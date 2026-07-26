# Explicit Architecture in Hanami

A design guide for building a Hanami 2.x/3.x app that deliberately implements Herberto Graça's **Explicit Architecture** (DDD + Ports & Adapters + Onion + Clean + CQRS).

> Source material:
> - [Herberto Graça — *DDD, Hexagonal, Onion, Clean, CQRS… How I put it all together*](https://herbertograca.com/2017/11/16/explicit-architecture-01-ddd-hexagonal-onion-clean-cqrs-how-i-put-it-all-together/)
> - [Hanami](https://hanakai.org/hanami) and the [Hanami guides](https://hanakai.org/learn/hanami)
> - [Igor Šarčević — *The Power of Interfaces in Ruby*](https://morningcoffee.io/interfaces-in-ruby)
> - Alvaro Duran — *Ledgers of Catan* and *Ledger Transactions Don't Have to Be Atomic*, The Payments Engineer Playbook
> - Ismael Celis — *Event Sourcing with Ruby examples*: [the ground up](https://ismaelcelis.com/posts/event-sourcing-ruby-examples/), [the Event Store interface](https://ismaelcelis.com/posts/event-sourcing-ruby-event-store/), [the Command layer](https://ismaelcelis.com/posts/event-sourcing-ruby-command-layer/)

---

## 1. The two axes

Graça's infographic (diagrams `000` → `100`) is really two orthogonal models stacked on one picture:

**Axis A — concentric layers (fine-grained).** Domain Model at the centre, then Domain Services, then the Application Layer, then adapters at the rim, split into *primary/driving* (the UI half of the ring) and *secondary/driven* (the infrastructure half). Every dependency arrow points inward. Ports (interfaces) live **inside** the core; adapters live **outside**.

**Axis B — components (coarse-grained).** Vertical slices per subdomain — Billing, Ordering, Catalog — cutting through all the layers. "Package by component," not package by layer. Components never reference each other's internals; they talk through events, a Shared Kernel, or explicit published contracts.

Most frameworks give you neither axis. **Hanami ships primitives for both**, which is what makes this pairing unusually clean:

- **Slices** are Axis B, first-class.
- **Container + `Deps` + providers** are the dependency-inversion machinery Axis A needs.
- **Operations** are the application layer, already named and already carrying explicit success/failure paths.

What Hanami does *not* do is enforce the layering inside a slice. That part is your design work, and it's where the rules below earn their keep.

---

## 2. Mapping table

| Explicit Architecture | Hanami | Notes |
|---|---|---|
| Component / bounded context | **Slice** (`slices/ordering`) | Own container, own providers, own settings, own boot |
| Application Layer (use cases) | **Operation** (`slices/ordering/orders/place.rb`) | `step`-based flow, `Success`/`Failure` |
| Application Services | Operations, or plain POROs in the slice container | Extract only when logic is reused |
| Domain Model (entities, VOs) | **Plain Ruby objects** in `slices/<x>/domain/` | Zero framework, zero `Deps` |
| Domain Services | POROs in `domain/services/` | Take entities in, return entities/values out |
| Port (behaviour) | **A container key** + a shared example group | Tests as interfaces (Šarčević) — see §4 |
| Port (data / DTO) | **`Dry::Validation::Contract`**, injectable via `Deps` | The machine-checked half — see §5 |
| Input validation | `params` / `contract` in actions; contracts in operations | Three tiers — see §5 |
| Secondary/driven adapter | Class in `adapters/`, registered by a **provider** | Stripe, S3, SMTP, HTTP clients |
| Primary/driving adapter | **Action**, CLI command, worker, mailer trigger | Translates a delivery mechanism into a core call |
| User Interface | **Views + templates + parts + assets** | Views are real objects; testable in isolation |
| ORM / persistence adapter | **Relations** (`Hanami::DB::Relation`) | The only place SQL lives |
| Repository | **Repo** (`ArticleRepo`) | Where the port meets the ORM |
| DTO / read model | **Struct** (`MyApp::DB::Struct`) | Query-side return type |
| Query object (CQRS read) | Repo read methods, or dedicated `queries/` | Bypasses the domain on purpose |
| Application events | `"notifications"` component / dry-events / job queue | Cross-slice fan-out |
| Domain events | Past-tense value objects in `domain/events/` | Optionally the source of truth — see §10 |
| Event store | A **two-method port**: `append_to_stream` / `read_from_stream` | The cleanest port in this doc — see §10 |
| Projector | Pure `(state, event) -> state` function in `domain/` | Never validates; always deterministic |
| Read model | Relation + repo, rebuilt by a subscriber | Derived and disposable under ES |
| Ledger entry | Immutable signed row, one per account per commodity | Conserved quantities — see §11 |
| Balance | A **projection**, never a column you mutate | `SUM(amount)`, or a materialised view |
| Balancing invariant | Pure function in `domain/` | Not a DB constraint — see §11 |
| Clearing account | A real, named account in the chart | Where an unmatched entry parks — see §12 |
| Compensation | Appended opposite entries, never a rollback | Saga semantics — see §12 |
| Shared Kernel | A `shared` slice, or `lib/`, or a real gem | Keep it *tiny* |
| Component decoupling | `import from:` / `export [...]` in `config/slices/*.rb` | The published contract, in one file |

---

## 3. Layout

Domain components are slices. Delivery mechanisms stay thin and separate — this matters, because a common Hanami mistake is making `Admin` and `API` slices and calling that your architecture. Those are UIs, not subdomains. Graça is explicit that a component is *always* domain-related.

```
config/
  app.rb
  routes.rb
  providers/                  # app-wide adapters (db, redis, notifications)
  slices/
    ordering.rb               # ← the published contract for Ordering
    billing.rb
    catalog.rb

app/                          # default web delivery: the outermost ring
  action.rb
  actions/orders/create.rb    # driving adapter → calls into a slice
  views/orders/show.rb        # UI
  templates/orders/show.html.erb

slices/
  api/                        # a second delivery mechanism, still just a UI
    action.rb
    actions/orders/create.rb

  ordering/                   # ── COMPONENT ─────────────────────────────
    domain/                   #    innermost ring: pure Ruby
      order.rb                #      entity
      money.rb                #      value object
      order_status.rb
      services/pricing.rb     #      domain service
    orders/                   #    application layer: use cases
      place.rb
      cancel.rb
    repos/order_repo.rb       #    port ↔ persistence boundary
    relations/orders.rb       #    ORM detail
    structs/order.rb          #    read-side DTO
    adapters/                 #    driven adapters (outer ring)
      stripe_payment_gateway.rb
      null_payment_gateway.rb
    config/
      providers/
        payment_gateway.rb    #    wires adapter → port key
      settings.rb
      routes.rb

  billing/
  catalog/
  shared/                     # Shared Kernel — event names, common VOs
```

The single most useful property of this layout: `slices/ordering/domain/` should be runnable with `ruby -Islices/ordering`. If it needs Hanami booted, it isn't a domain layer.

---

## 4. Ports without interfaces

This is the crux of porting Explicit Architecture to Ruby. Graça's ports are PHP interfaces — a compiler-checked artifact. Ruby has no method-set equivalent; dry-validation contracts cover the *data* half of a port and are treated separately in §5. The **behavioural** half becomes a **three-part convention**:

1. **A container key** owned by the slice that needs it (`"payment_gateway"`, not `"stripe"`).
2. **A documented contract** — the method signature and return shape the core expects.
3. **A contract test** that every implementation must pass.

The rule that makes it real: **the application core never names the vendor.** If `grep -r "Stripe" slices/ordering/orders/` returns anything, the port has leaked.

### The port, expressed as a fake

The most practical way to write a Ruby port down is as the null/test implementation. It *is* the specification, and it's executable.

```ruby
# slices/ordering/adapters/null_payment_gateway.rb
module Ordering
  module Adapters
    # PORT: payment_gateway
    #   #charge(amount:, token:, idempotency_key:)
    #     → Success(Ordering::Domain::Charge)
    #     → Failure[:declined, reason]
    #     → Failure[:gateway_unavailable, reason]
    class NullPaymentGateway
      include Dry::Monads[:result]

      def charge(amount:, token:, idempotency_key:)
        Success(Domain::Charge.new(id: "null-#{idempotency_key}", amount:))
      end
    end
  end
end
```

Note the port is shaped around **what the use case needs**, not around Stripe's API. Graça repeats this twice in the article, and it's the failure mode most teams hit: a `payment_gateway` port with `create_payment_intent` and `confirm_payment_intent` on it isn't a port, it's Stripe with extra steps.

### The adapter

```ruby
# slices/ordering/adapters/stripe_payment_gateway.rb
module Ordering
  module Adapters
    class StripePaymentGateway
      include Dry::Monads[:result]

      def initialize(client:)
        @client = client
      end

      def charge(amount:, token:, idempotency_key:)
        intent = @client.create(
          amount: amount.cents,
          currency: amount.currency,
          source: token,
          idempotency_key: idempotency_key
        )
        Success(Domain::Charge.new(id: intent.id, amount: amount))
      rescue Stripe::CardError => e
        Failure[:declined, e.message]
      rescue Stripe::StripeError => e
        Failure[:gateway_unavailable, e.message]
      end
    end
  end
end
```

The adapter absorbs the vendor's exceptions and translates them into the port's vocabulary. Vendor exception classes are as much of a leak as vendor method names.

### The provider — where inversion of control actually happens

```ruby
# slices/ordering/config/providers/payment_gateway.rb
Ordering::Slice.register_provider(:payment_gateway) do
  prepare do
    require "stripe"
  end

  start do
    adapter =
      if target["settings"].payments_enabled
        Ordering::Adapters::StripePaymentGateway.new(
          client: Stripe::PaymentIntent
        )
      else
        Ordering::Adapters::NullPaymentGateway.new
      end

    register "payment_gateway", adapter
  end

  stop do
    # close pooled connections, flush buffers
  end
end
```

Swapping vendors is now one file. Nothing in the core changes — which is the entire promise of Ports & Adapters, delivered by a framework feature rather than by discipline alone.

### The contract test — where the port actually lives

Igor Šarčević's [*The Power of Interfaces in Ruby*](https://morningcoffee.io/interfaces-in-ruby) makes the case this design depends on, so it's worth stating his argument rather than assuming it.

His first move is to reject the obvious approach. The usual Ruby "interface" — a module whose methods `raise "Not implemented"` — looks like Java but fails at the one job an interface has: you don't find out about the missing method until the code runs and blows up. It's a to-do list wearing a type system's clothes. His conclusion is that you may as well delete it and let Ruby's own `NoMethodError` do the same work.

His second move is the interesting one. Stop chasing the syntax and go after the semantics: what you actually want is *a set of constraints on an object's behaviour, checked before the app runs* — and that is a description of a test suite. So the port becomes a shared example group, and `it_behaves_like` becomes `implements`.

The payoff is that this is strictly **more** expressive than the PHP interface Graça is writing against. An interface can say `charge(Money, string, string): Charge`. It cannot say any of the things that actually matter at this boundary:

```ruby
# spec/support/ports/payment_gateway.rb
RSpec.shared_examples "a payment gateway" do
  # ── the part an interface could express ──
  it { is_expected.to respond_to(:charge).with_keywords(:amount, :token, :idempotency_key) }

  # ── the part it could not ──
  it "returns Success(Charge) for a valid charge" do
    result = subject.charge(amount: Money.new(1000, "USD"), token: "tok_ok", idempotency_key: "k1")

    expect(result).to be_success
    expect(result.value!).to respond_to(:id, :amount)
  end

  it "translates a declined card into the port's vocabulary" do
    result = subject.charge(amount: Money.new(1000, "USD"), token: "tok_declined", idempotency_key: "k2")

    expect(result).to be_failure
    expect(result.failure.first).to eq(:declined)
  end

  it "never leaks vendor exceptions" do
    expect {
      subject.charge(amount: Money.new(1000, "USD"), token: "tok_explode", idempotency_key: "k3")
    }.not_to raise_error
  end

  it "is idempotent for a repeated idempotency_key" do
    args = {amount: Money.new(1000, "USD"), token: "tok_ok", idempotency_key: "k4"}

    first  = subject.charge(**args)
    second = subject.charge(**args)

    expect(second.value!.id).to eq(first.value!.id)
  end
end
```

```ruby
RSpec.describe Ordering::Adapters::StripePaymentGateway do
  it_behaves_like "a payment gateway"
end

RSpec.describe Ordering::Adapters::NullPaymentGateway do
  it_behaves_like "a payment gateway"
end
```

Idempotency, exception containment, and the failure vocabulary are the properties that make an adapter safe to swap — and none of them fit in a type signature. Run the group against the Stripe adapter (recorded or sandboxed) *and* the null adapter: if the fake and the real thing both pass, substitutability is proven rather than assumed, and your unit tests stop lying to you.

### A null object is not a `NotImplementedError` module

Worth separating, because §4's `NullPaymentGateway` can look like the anti-pattern Šarčević is warning about. It isn't, and the difference is the whole point:

| | Abstract module raising `NotImplementedError` | Null adapter |
|---|---|---|
| Is it a working implementation? | No | Yes — it runs in dev and in tests |
| When does it fail? | At runtime, on the missing method | It doesn't |
| Does it pass the port's shared examples? | Impossible | Yes, that's the requirement |
| What does it document? | A to-do list | Executable expected behaviour |

The null adapter earns its place by being a real, passing implementation of the port. An abstract base class raising `NotImplementedError` earns nothing that `NoMethodError` wouldn't have given you for free — skip it.

### The gap this leaves

Be clear-eyed about what's lost relative to a compiled interface. It isn't expressiveness — the shared examples say more, not less. It's **coverage**: a PHP interface is checked on every implementer whether anyone remembered or not, whereas a shared example group only fires where someone wrote `it_behaves_like`. Add an adapter, forget the one line, and the port silently stops being enforced for it.

That's a mechanical problem, so it gets a mechanical answer — see the port-coverage fitness function in §13.

---

## 5. Contracts: the data half of a port

Ruby has no method-set interfaces, but it does have **dry-validation contracts**, and they cover the half of Graça's port definition that §4's shared examples don't. He describes a port as potentially "composed of several Interfaces and DTOs" — contracts are the DTO half, and unlike duck typing they are declarative, reusable, injectable, and fail loudly with a structured error object.

What they can't do: assert that `StripePaymentGateway` responds to `#charge` and returns `Failure[:declined, _]`. Behaviour still needs contract tests. **Use both — a schema for the data crossing the seam, shared examples for the behaviour at the seam.**

### Three tiers of validation, three layers

| Tier | Lives in | Validates | Mechanism | On failure |
|---|---|---|---|---|
| **Structural** | Driving adapter (action) | shape, types, allowlisting, coercion | `params do` / `contract` | `422` |
| **Contextual** | Application layer (operation) | uniqueness, existence, cross-field, current state | injected `Dry::Validation::Contract` | `Failure[:invalid, errors]` |
| **Invariant** | Domain | things that must never be false | constructor guards | `raise` |

Hanami's own docs draw the first line for you: parameter validation in actions is for structure, types and coercion, while checks like "does a user with this email already exist" belong deeper — in something like a create-user operation that can reach a data store.

The second line is the one teams miss. If a rule can only be false because of what's in the database *right now*, it's contextual and belongs to the use case. If a rule must never be false for the object to exist at all, it's an invariant: it belongs in the constructor and should **raise**, not return a `Failure`, because reaching it means a bug upstream rather than bad user input.

### Contracts as injectable components

A contract is just a class, so it can live in the container and take dependencies — which makes it swappable and independently testable like any other component:

```ruby
# slices/ordering/contracts/place_order.rb
module Ordering
  module Contracts
    class PlaceOrder < Dry::Validation::Contract
      include Deps["repos.customer_repo", "repos.catalog_repo"]

      params do
        required(:customer_id).filled(:integer)
        required(:payment_token).filled(:string)
        required(:items).array(:hash) do
          required(:sku).filled(:string)
          required(:quantity).filled(:integer, gteq?: 1)
        end
      end

      rule(:customer_id) do
        key.failure("is not an active customer") unless customer_repo.active?(value)
      end

      rule(:items) do
        skus    = value.map { _1[:sku] }
        unknown = skus - catalog_repo.existing_skus(skus)
        key.failure("unknown skus: #{unknown.join(", ")}") if unknown.any?
      end
    end
  end
end
```

Wired into the operation from §6:

```ruby
include Deps["contracts.place_order", "repos.order_repo", "payment_gateway"]

private

def validate(attrs)
  result = place_order.call(attrs)
  result.success? ? Success(result.to_h) : Failure[:invalid, result.errors.to_h]
end
```

The action pattern-matches `Failure[:invalid, errors]` and renders them. Note the contract reaches the database — fine, because a contract is an **application-layer** component. It must never be injected into `domain/`.

Actions can also be handed a contract directly (`contract MyContract`, or `include Deps[contract: "..."]`), which lets one class serve both an HTTP endpoint and a non-HTTP caller like a CLI importer.

### Where contracts pay off most: inbound adapter boundaries

The overlooked use: **responses from third parties are untrusted input too.** A driven adapter parsing a webhook or an API response should validate before anything reaches the core.

```ruby
module Ordering
  module Adapters
    class StripeWebhook
      include Deps["contracts.stripe_charge_payload"]

      def parse(payload)
        result = stripe_charge_payload.call(payload)
        return Failure[:malformed_payload, result.errors.to_h] if result.failure?

        Success(Domain::Charge.new(**result.to_h))
      end
    end
  end
end
```

That is an anti-corruption layer with teeth. When the vendor silently changes a field's type, you get a clean `Failure` at the boundary instead of a `NoMethodError` three layers in — and the failure names the vendor's contract, not yours.

### And for the Shared Kernel

The same trick across components. Give each event payload a schema in `slices/shared/`, validate on publish *and* on receive, and the published language between components stops being a comment and starts being a build failure:

```ruby
# slices/shared/events/order_placed.rb
module Shared
  module Events
    ORDER_PLACED = "orders.placed"

    OrderPlacedPayload = Dry::Schema.Params do
      required(:order_id).filled(:integer)
      required(:customer_id).filled(:integer)
      required(:total_cents).filled(:integer)
      required(:currency).filled(:string, included_in?: %w[USD EUR GBP])
    end
  end
end
```

This is also the closest Ruby gets to Graça's point that a Shared Kernel in a polyglot system should be language-agnostic — describing events as data (he suggests JSON) so every component can interpret them. A dry-schema is one JSON Schema export away from exactly that.

### The trap

Don't let contracts become the domain model. A contract encoding *discount eligibility* is domain logic that has escaped into a schema DSL: it can't be reused outside validation, it can't be unit-tested without the container, and it will drift from the entity that supposedly owns the rule.

> Contracts answer **"is this input well-formed and admissible?"**
> Entities answer **"what does the business do with it?"**

---

## 6. Application layer = Operations

Hanami operations map onto Graça's Application Services almost exactly. Graça's canonical shape is: *fetch entities → tell them to do domain work → persist*. Written as an operation:

```ruby
# slices/ordering/orders/place.rb
module Ordering
  module Orders
    class Place < Ordering::Operation
      include Deps[
        "repos.order_repo",
        "repos.customer_repo",
        "payment_gateway",              # ← the PORT key
        "notifications"                 # ← application events
      ]

      def call(customer_id:, items:, payment_token:)
        transaction do
          customer = step fetch_customer(customer_id)
          order    = step build_order(customer, items)   # domain does the work
          charge   = step charge_for(order, payment_token)

          order.confirm(charge)
          persisted = order_repo.save(order)

          notifications.instrument(Shared::Events::ORDER_PLACED, order_id: persisted.id)
          persisted
        end
      end

      private

      def fetch_customer(id)
        customer = customer_repo.find(id)
        customer ? Success(customer) : Failure[:customer_not_found, id]
      end

      def build_order(customer, items)
        Domain::Services::Pricing.new.build_order(customer:, items:)
      end

      def charge_for(order, token)
        payment_gateway.charge(
          amount: order.total,
          token: token,
          idempotency_key: order.idempotency_key
        )
      end
    end
  end
end
```

What's worth noticing:

- **Orchestration only.** No pricing rules, no tax logic. Those are in `Domain::Services::Pricing`, so a second use case (a CLI backfill, an admin re-quote) can reuse them. Graça's warning applies directly: domain logic that lands in the application layer stops being reusable.
- **`transaction` wraps the flow**, and a step failure rolls it back — Hanami hands you this for free.
- **The application event fires at the end**, carrying the outcome. Side effects (receipt email, warehouse notification, analytics) hang off the event, not off this method.
- **`Deps` gives keyword-arg constructor injection**, so the test is `Place.new(payment_gateway: fake, order_repo: fake)` — no global stubbing, no `allow_any_instance_of`.

---

## 7. Domain layer

The centre of the onion. Rules, in order of how often they get broken:

1. **No `include Deps`.** A domain object that can reach the container is not a domain object.
2. **No repos, no relations, no DB.** Domain objects are handed everything they need.
3. **No Hanami constants at all.** Pure Ruby, plus maybe dry-types/dry-monads.
4. **Business invariants live here** — enforced in constructors and mutators, not in validation schemas.

```ruby
# slices/ordering/domain/order.rb
module Ordering
  module Domain
    class Order
      attr_reader :id, :customer_id, :lines, :status, :charge

      def initialize(id:, customer_id:, lines:, status: Status::DRAFT, charge: nil)
        raise ArgumentError, "order requires at least one line" if lines.empty?
        @id, @customer_id, @lines, @status, @charge = id, customer_id, lines, status, charge
      end

      def total
        lines.map(&:subtotal).reduce(Money.zero) { |a, b| a + b }
      end

      def confirm(charge)
        raise InvalidTransition, "cannot confirm #{status}" unless status == Status::DRAFT
        @status = Status::CONFIRMED
        @charge = charge
      end

      def cancellable? = status == Status::CONFIRMED && charge.refundable?
    end
  end
end
```

### Structs are not entities

Hanami's `DB::Struct` objects come off the relations — they're read models, and they're excellent at that. Do not let them become your domain model: they mirror table shape, not domain shape, and behaviour attached to them ends up coupled to your schema.

The repo is where the two representations meet:

```ruby
# slices/ordering/repos/order_repo.rb
module Ordering
  module Repos
    class OrderRepo < Bookshelf::DB::Repo   # base class name follows `hanami generate`
      # ── write side: hydrate/persist domain entities ──
      def find(id)
        record = orders.combine(:lines).by_pk(id).one
        record && Mappers::Order.to_domain(record)
      end

      def save(order)
        transaction do
          attrs = Mappers::Order.to_attributes(order)
          orders.by_pk(order.id).changeset(:update, attrs).commit
        end
      end

      # ── read side: structs straight out, no domain involved ──
      def recent_for_customer(customer_id, limit: 20)
        orders.where(customer_id:).order { created_at.desc }.limit(limit).to_a
      end
    end
  end
end
```

That mapper is a real cost — the honest one in this whole design (§15). It buys you a domain model that changes when the business changes rather than when the schema does.

---

## 8. Two paths through the app

Graça's flow-of-control diagrams show a command path and a query path that deliberately differ. Hanami's actions/views/operations split lands on this naturally.

```
WRITE  ─ Action (driving adapter)
         │  translates HTTP → a call
         ▼
         Operation (application layer)
         │  fetch → domain → persist → emit event
         ▼
         Domain entities / domain services
         │
         ▼
         Repo → Relation → DB          (driven adapter)

READ   ─ Action → View (UI)
                  │  expose
                  ▼
                  Repo query → Struct → template
                  (domain layer bypassed on purpose)
```

Actions stay thin — HTTP in, HTTP out:

```ruby
# app/actions/orders/create.rb
module Bookshelf
  module Actions
    module Orders
      class Create < Bookshelf::Action
        include Deps[place_order: "ordering.orders.place"]

        params do
          required(:items).array(:hash)
          required(:payment_token).filled(:string)
        end

        def handle(request, response)
          return response.render(view, validation: request.params) unless request.params.valid?

          result = place_order.call(
            customer_id: request.session[:customer_id],
            items: request.params[:items],
            payment_token: request.params[:payment_token]
          )

          case result
          in Success(order)
            response.redirect_to routes.path(:order, order.id)
          in Failure[:declined, reason]
            response.render view, error: reason
          in Failure[:customer_not_found, _]
            halt 404
          end
        end
      end
    end
  end
end
```

Every branch of the operation's failure vocabulary gets an HTTP meaning **here**, in the adapter — the core never knows what a 404 is.

Views handle the read path as ordinary objects:

```ruby
# app/views/orders/show.rb
module Bookshelf
  module Views
    module Orders
      class Show < Bookshelf::View
        include Deps["ordering.repos.order_repo"]

        expose :order do |id:|
          order_repo.recent_for_customer(id)   # struct, not entity
        end
      end
    end
  end
end
```

---

## 9. Decoupling components

Graça's point about components is stronger than most people implement: a component holds **no reference to any code unit of another component — not even an interface.** Hanami gives you three tools, in ascending order of coupling.

### Loosest: application events

```ruby
# config/providers/events.rb  — an app-wide dispatcher
Hanami.app.register_provider(:events) do
  start do
    register "events", Bookshelf::Events::Bus.new(logger: target["logger"])
  end
end
```

Ordering emits `ORDER_PLACED`; Billing and Catalog subscribe. Neither knows the other exists. The event name constant lives in the **Shared Kernel**, so the emitter doesn't own the vocabulary:

```ruby
# slices/shared/events.rb
module Shared
  module Events
    ORDER_PLACED    = "orders.placed"
    ORDER_CANCELLED = "orders.cancelled"
  end
end
```

Keep the Shared Kernel minimal — event names, a few universal value objects, nothing else. Every change to it is a change to every component.

### Middle: explicit imports and exports

When a synchronous call is genuinely required, make the contract a file you can review:

```ruby
# config/slices/ordering.rb
module Ordering
  class Slice < Hanami::Slice
    import keys: ["invoices.issue"], from: :billing   # exactly what we consume
    export ["orders.place", "orders.cancel"]          # exactly what we publish
  end
end
```

This pair of lines is the component's published language. A PR that widens `export` is a PR that widens your architecture, and it's visible as such.

### Tightest: `shared_app_component_keys`

Hanami's own docs caution against this, and the caution is right — it couples every slice to the app. Reserve it for genuinely universal infrastructure (logger, settings).

### The rule of thumb

Graça notes that a component may **query** data it doesn't own, but never **change** it. In practice: a read-only repo reaching another component's tables is a defensible shortcut; a write is never one. If Ordering needs Billing's data mutated, that's an event or an imported operation.

---

## 10. Event sourcing, where it earns its place

Graça leaves a door open here and doesn't walk through it. In his Domain Model ring, Domain Events fire when an entity changes, carry the changed values with them, and are — his words — perfect for event sourcing. Ismael Celis's Ruby series walks through it, and the two fit together better than either article suggests.

### The shape

Celis reduces event sourcing to a single function:

```
#call(state, event) -> state
```

State is a plain entity — a Struct or a Hash. Events are past-tense value objects. A **projector** folds events onto state, so current state is `events.reduce(blank, &projector)`. Three properties fall out, and every one of them is load-bearing for Explicit Architecture:

- **Projectors are pure.** Same state, same events, same result. No side effects.
- **Events are assumed valid.** Validation happens *before* an event exists, in the command layer. A projector never validates — which lines up exactly with the three-tier split in §5.
- **There is no persistence anywhere in the domain flow.** Domain code deals only with in-memory objects.

That third property is Graça's inward-pointing dependency rule, reached from a completely different direction.

### The Event Store is a textbook port

Celis's entire persistence interface is two methods:

```
#append_to_stream(stream_id String, events List<Event>) boolean
#read_from_stream(stream_id String) List<Event>
```

That drops straight into §4's machinery — container key, adapters, provider, shared examples:

```ruby
# slices/ordering/config/providers/event_store.rb
Ordering::Slice.register_provider(:event_store) do
  start do
    target.start(:db)
    register "event_store", Ordering::Adapters::PostgresEventStore.new(db: target["db.gateway"])
  end
end
```

And the port's shared examples state guarantees no interface could carry — ordering, optimistic locking, replay determinism:

```ruby
RSpec.shared_examples "an event store" do
  it { is_expected.to respond_to(:append_to_stream).with(2).arguments }
  it { is_expected.to respond_to(:read_from_stream).with(1).argument }

  it "preserves event order within a stream" do
    subject.append_to_stream("order-1", [event_a, event_b])
    expect(subject.read_from_stream("order-1")).to eq([event_a, event_b])
  end

  it "isolates streams from each other" do
    subject.append_to_stream("order-1", [event_a])
    subject.append_to_stream("order-2", [event_b])
    expect(subject.read_from_stream("order-2")).to eq([event_b])
  end

  it "rejects a concurrent write to the same stream" do
    subject.append_to_stream("order-1", [event_a], last_sequence: 0)

    expect {
      subject.append_to_stream("order-1", [event_b], last_sequence: 0)
    }.to raise_error(Ordering::ConcurrencyError)
  end
end
```

Verify it against the Postgres adapter *and* an in-memory one. The in-memory store isn't a mock — it's §4's null object doing real work, and it lets every domain test run without a database.

### The command layer *is* the application layer

Celis's five-step command flow and Graça's Application Service are the same shape over a different persistence port:

| | Graça's Application Service | Celis's command |
|---|---|---|
| 1 | repository finds entities | event store reads the stream |
| 2 | — | projector reconstitutes state |
| 3 | tell entities to do domain work | decide which events to issue |
| 4 | — | apply new events to state |
| 5 | repository persists entities | event store appends new events |

In Hanami, that's one operation:

```ruby
module Ordering
  module Orders
    class Cancel < Ordering::Operation
      include Deps["event_store", "clock"]

      def call(order_id:, reason:)
        stream = "order-#{order_id}"
        events = event_store.read_from_stream(stream)
        return Failure[:not_found, order_id] if events.empty?

        state      = events.reduce(Domain::Order.blank, &Domain::OrderProjector)
        new_events = step Domain::Decisions::CancelOrder.call(state, reason:, now: clock.now)

        event_store.append_to_stream(stream, new_events, last_sequence: events.last.sequence)

        Success(new_events.reduce(state, &Domain::OrderProjector))
      end
    end
  end
end
```

Everything framework-shaped sits in the operation. The decision is a pure function in `domain/`:

```ruby
# slices/ordering/domain/decisions/cancel_order.rb
module Ordering
  module Domain
    module Decisions
      CancelOrder = lambda do |order, reason:, now:|
        return Failure[:already_cancelled, order.id] if order.cancelled?
        return Failure[:too_late_to_cancel, order.id] if order.shipped?

        Success([Events::OrderCancelled.new(order_id: order.id, reason:, at: now)])
      end
    end
  end
end
```

Note `clock` is injected. Once decisions are pure functions, `Time.now` is I/O like any other, and it becomes a port.

### The payoff: domain purity stops being a discipline

§7 asks you to keep `domain/` free of `Deps`, Hanami and I/O; §13 polices it with a grep. Under event sourcing the shape of the code enforces it instead. The domain becomes a pure function from `(state, input)` to events, and the test needs nothing at all:

```ruby
RSpec.describe Ordering::Domain::Decisions::CancelOrder do
  it "emits OrderCancelled for a confirmed order" do
    order  = Domain::Order.new(id: 1, status: :confirmed)
    result = described_class.call(order, reason: "changed mind", now: Time.at(0))

    expect(result.value!).to eq([
      Domain::Events::OrderCancelled.new(order_id: 1, reason: "changed mind", at: Time.at(0))
    ])
  end
end
```

No container, no database, no clock, no mocks. Celis's description of what you end up with is worth keeping: the system's whole behaviour flattens into a specification at one level of abstraction — **a list of commands and the events they produce.** That's a more useful artefact than any architecture diagram.

### CQRS stops being a shortcut

§8's read path — repo → struct → view, domain bypassed — is a pragmatic choice in a CRUD design. Under event sourcing it's structural:

```
WRITE   Action → Operation → decision fn → events → Event Store    (source of truth)
                                                        │
                                                        ▼
                                                    subscriber
                                                        │
READ    Action → View → Repo → relation ◄── projection ─┘          (derived, disposable)
```

Hanami's relations and repos become **projection stores**, not the system of record. Two consequences to accept before committing: read models are eventually consistent with the write side, and any read model can be dropped and rebuilt by replaying the log. The second is a genuine superpower — read-side schema changes stop being frightening, because the data can always be regenerated.

### Do it per slice, never per app

This is the strongest practical argument for the slices-as-components design in §3. **Event sourcing is a per-component decision.** Ordering can be event-sourced while Catalog stays plain CRUD, because a slice owns its persistence, its providers, and its exported contract. Nothing outside Ordering knows its state is derived from a log — the exported operation keys look identical either way.

Pick the slice where history *is* the product: money movement, ledgers, subscription state, anything with compliance or dispute-resolution value, anything whose current state is honestly a fold over past decisions. Don't event-source a product catalogue.

### Costs

- **Versioning is forever.** Events are permanent, so a shape change means an upcaster you maintain indefinitely. The §5 schemas help — validate on append, and treat the schema as part of the event's public contract.
- **Eventual consistency.** "Save, then immediately read your own write" needs deliberate handling in the UI.
- **No ad-hoc queries on the write side.** Every question needs a projection built in advance.
- **Replay cost** grows with stream length. Snapshots are the standard answer and they're more machinery.
- **Conceptual load.** This is a bigger step for a team than everything else in this document combined.

### One detail worth stealing regardless

Celis suggests committing *commands* to the store alongside events, with each event annotated by the ID of the command that produced it. Projectors ignore the commands, but you get an audit trail of intent *and* outcome:

```
2022-06-01T10:11:00 [product-123] user xyz attempted to change currency to GBP
--  currency changed from USD to GBP at 0.82
--  price updated to GBP 820.00
```

"The user tried X, and here's what actually happened" answers a class of support question that ordinary logging never quite does — and it's worth doing even in a slice that isn't event-sourced.

### Where this disagrees with §7

Flagging rather than smoothing over: Celis argues entities should be dumb in-memory state with decisions living outside them, and rejects entity/command mashups (`product.update_price(1000)` producing events internally) on the grounds that they bloat entities with policy, validations and side effects. §7's `Order#confirm` is exactly the classical style he's arguing against.

Both are defensible, and it's a real fork:

- **Behaviour-rich entities** (Graça, classical DDD) — invariants live with the data, one place to look, natural in a CRUD design.
- **State plus separate decision functions** (Celis) — required by projector purity, and it makes policy variation cheap: an admin cancellation and a customer cancellation become two decision functions over the same entity.

Decide per slice. If a slice is event-sourced, take the second; purity will push you there regardless.

---

## 11. Ledgers, not balances

A claim worth making first class: **most apps write transactions where they should be writing ledgers.** The two are not alternatives — you still need the transaction — but the transaction is a *mechanism* and the ledger is a *representation*, and teams routinely reach for the first when the problem calls for the second.

### The complaint, precisely

```sql
BEGIN;
  UPDATE wallets SET credits = credits - 100 WHERE id = 42;
  UPDATE wallets SET credits = credits + 100 WHERE id = 99;
COMMIT;
```

This is correct at the instant it runs and unanswerable forever afterwards.

| | Mutable balance in a transaction | Ledger of entries |
|---|---|---|
| "Why is this number 4,317?" | No answer exists | Sum the entries |
| Protects against concurrent writers | Yes | Yes (still needs the transaction) |
| Protects against *your code being wrong last Tuesday* | No | Yes — the invariant is checkable at any time |
| Fixing a mistake | Mutate again; evidence destroyed | Append a compensating entry; both are history |
| "Where did 40,000 credits go this month?" | Instrument it in advance and hope | One query, retroactively |
| Verifiable | Nothing to verify | Everything must sum to zero |

The transaction gives you consistency **at write time**. The ledger gives you consistency **you can prove at any time**, which is the property that actually matters when someone disputes a number eight months later.

The transaction doesn't go away. It gets *smaller and more uniform*: its only job becomes appending N balanced entries atomically. One shape, everywhere in the app. Business logic stops living inside `BEGIN`/`COMMIT` and moves to a pure function that decides which entries to write.

That last claim is itself an assumption, and a load-bearing one. §12 takes it apart — at scale, and across component boundaries, requiring both sides of a movement to land together does real damage to the domain model.

### Accounts contain things, not money

The generalising move comes from Alvaro Duran's *Ledgers of Catan*, which builds a full double-entry ledger for a board game that **has no money in it at all** — five commodities, barter only, no common unit of value. He quotes the Beancount definition: an account is "something that can contain things," and notes that accounting is for tracking things generally; money is merely the thing people most wanted to track.

That reframing is what makes this architectural rather than a fintech special case. Ledger-shaped domains are everywhere and usually go unrecognised:

- API credits, tokens, compute minutes
- Plan seats assigned and released
- Inventory units across warehouses
- Loyalty points, referral rewards
- Storage quota consumed and freed
- Rate-limit budgets

If a quantity is **conserved** — it doesn't appear or vanish, it only *moves* — it wants a ledger. Duran's rules for that, from his Catan checkpoint: every unit is preserved, every transaction balances *by resource type*, and no mixing or "fair value" conversion between types.

His deeper argument is that collapsing everything to one unit of reference is a medieval assumption that has broken down: fair value can be gamed, since you pick the reference marketplace, and a shock in it produces phantom gains and losses on commodities you never traded. In a software ledger the same trap appears as storing everything in USD cents, or normalising all quantities to one unit. Don't. Keep the commodity on the entry.

### The invariant that replaces the transaction

Duran's Multi-Currency Balancing Rule — transactions balance when debits and credits, **partitioned by commodity**, add up to the same number — is a domain invariant, not a database constraint. Which means, per §7, it belongs in `domain/` as a pure function:

```ruby
# slices/ledger/domain/transfer.rb
module Ledger
  module Domain
    # amount is a signed integer in the commodity's minor unit. Never a float,
    # never a normalised "common" unit — scale belongs to the commodity.
    Entry = Data.define(:account, :commodity, :amount)

    Transfer = Data.define(:id, :entries, :occurred_at, :metadata) do
      def balanced?
        by_commodity.all? { |_commodity, entries| entries.sum(&:amount).zero? }
      end

      def unbalanced_commodities
        by_commodity.reject { |_, entries| entries.sum(&:amount).zero? }.keys
      end

      def by_commodity = entries.group_by(&:commodity)
    end
  end
end
```

Signed integers rather than debit/credit columns make the invariant literally `sum == 0`. Accountants will want the debit/credit vocabulary in the UI; that's a presentation concern, and the arithmetic is the same either way.

The decision function then follows §10's shape exactly — pure, no I/O, testable with nothing:

```ruby
# slices/ledger/domain/decisions/post_transfer.rb
PostTransfer = lambda do |accounts, transfer|
  unless transfer.balanced?
    return Failure[:unbalanced, transfer.unbalanced_commodities]
  end

  overdrawn = transfer.entries.select { |entry|
    account = accounts.fetch(entry.account)
    !account.allows_negative? && (account.balance_of(entry.commodity) + entry.amount).negative?
  }

  return Failure[:insufficient_balance, overdrawn.map(&:account)] if overdrawn.any?

  Success([Events::TransferPosted.new(transfer:)])
end
```

Note `allows_negative?` is a property of the **account**, not the transfer. Duran's Earth account goes arbitrarily negative because it's an infinite source; player accounts cannot. Same in an app: `source:purchase` may run negative forever, a customer wallet may not.

### Source and sink accounts

The trick that makes everything balance: when value enters or leaves the system, it still needs a counterparty. Duran names his Earth, plus dedicated sinks for dice production, build costs and discards.

Name yours explicitly and never let them be implicit:

```
source:purchase      credits bought with money
source:promotion     credits granted free
source:migration     opening balances at import
sink:consumption     credits spent on the product
sink:expiry          credits that lapsed
sink:refund          credits returned for money
```

The payoff is analytics you never had to instrument. Because every unit that ever existed passed through a named source and a named sink, "how many credits expired unused last quarter, by plan tier" is a query you can run *retroactively*, against data you already have, for a question nobody thought to ask at the time. Duran makes the same point about Catan: the ledger tells you who got the most resources, who spent the most, who got robbed most, and which hexes over- or under-produced against their dice probability — none of which anyone set out to record.

### Contra accounts: making the *nature* of an event queryable

Duran models a theft not as a plain transfer but as a routed pair through a `Robber` account, so that the involuntary nature of the movement is recorded rather than inferred. Two extra entries that track **risk rather than balance**.

The app analogues are worth taking seriously: chargeback versus refund, write-off versus consumption, promotional credit versus purchased credit, fraud clawback versus correction. All of them move the same quantity and mean entirely different things.

The distinction from a metadata column is sharp:

- A `reason` field answers *"why did this one entry happen?"*
- A contra account answers *"how much has ever moved through this phenomenon, and does it reconcile against everything else?"*

Reach for the contra account when you need the category to be a **balance over time** rather than a label on a row.

### What does *not* belong in the ledger

The most valuable warning in Duran's piece is about what he leaves out. A Catan port grants the right, not the obligation, to trade at a favourable rate. It costs nothing, is not a resource, and **changes no balance until exercised** — so he treats it as off-balance-sheet, a note rather than an entry.

The software equivalents get mismodelled constantly: plan entitlements, quotas, rate limits, "up to 10 seats," promised capacity, promotional eligibility. These are **policy**, not balance. Putting them in the ledger means fabricating entries for things that have not happened, and then fighting your own conservation invariant forever.

> If it isn't a conserved quantity that has actually moved, it isn't a ledger entry.

Entitlements live in the domain as policy objects. The ledger records what was drawn against them.

Duran also declines to track built settlements and cities as assets — they grant production rights but can't be traded away and have no salvage value, so they aren't on the balance sheet. Same rule, same reasoning.

### In Hanami

A `ledger` slice, with a deliberately narrow exported surface:

```ruby
# config/slices/ledger.rb
module Ledger
  class Slice < Hanami::Slice
    export ["transfers.post", "queries.balance", "queries.history"]
  end
end
```

Every other slice posts transfers and reads balances. None of them touch entries directly — that's the §9 rule, and here it's load-bearing, because a slice that can write raw entries can break conservation for everyone.

The store is the same port shape as §10's event store, which is not a coincidence:

```ruby
# PORT: ledger_store
#   #append(transfer)                 → Success(sequence) | Failure[:conflict, _]
#   #entries_for(account, commodity:) → Enumerable<Entry>
```

The operation is the only place a database transaction appears, and it's uniform:

```ruby
module Ledger
  module Transfers
    class Post < Ledger::Operation
      include Deps["ledger_store", "repos.account_repo", "notifications"]

      def call(transfer)
        accounts = account_repo.lock_and_load(transfer.entries.map(&:account))

        events = step Domain::Decisions::PostTransfer.call(accounts, transfer)

        transaction do
          ledger_store.append(transfer)
          events.each { notifications.instrument(Shared::Events::TRANSFER_POSTED, _1.to_h) }
        end

        Success(transfer)
      end
    end
  end
end
```

Business logic is in the pure decision function. The transaction does one boring thing. That's the whole reframing in one method.

Balances are a **projection** — a materialised view or a `balances` table maintained by a subscriber — which slots straight into §10's CQRS diagram. Reads go through the repo to the projection; writes go through entries. The balance is never a column anyone updates.

### Two fitness functions you couldn't otherwise write

Add these to §13; they're the concrete payoff for the whole representation.

```ruby
# 6. Conservation. The invariant the mutable-balance design cannot even express.
RSpec.describe "ledger conservation" do
  it "sums to zero across every commodity" do
    Ledger::Slice["queries.global_totals"].call.each do |commodity, total|
      expect(total).to eq(0), "#{commodity} is out by #{total}"
    end
  end
end

# 7. Projection reconciliation. Catches a broken subscriber before a customer does.
RSpec.describe "balance projection" do
  it "matches the entries it was derived from" do
    Ledger::Slice["queries.all_accounts"].call.each do |account|
      derived = Ledger::Slice["queries.recompute_balance"].call(account.id)
      expect(account.balances).to eq(derived), "projection drift on #{account.id}"
    end
  end
end
```

Run the first as a periodic production job, not just in CI. A ledger that has stopped summing to zero is a system that is actively lying, and you want to know within minutes rather than at audit.

### Where the ACID transaction genuinely still matters

Don't oversell the pattern — and see §12 for the case that it matters less than it appears. Ledgers relocate concurrency control; they don't dissolve it. Two concurrent transfers from the same account can each be individually valid and jointly overdraw it, and appending entries doesn't fix that on its own. The options are the familiar ones:

- **Optimistic locking on the account's last sequence** — the same mechanism §10's event store already needs, so if you have both you've built it once.
- **Serialise per account**, which is what most high-throughput ledgers do.
- **Allow the overdraft and reconcile**, valid only for accounts where negative is meaningful — Duran's Earth, your `source:` accounts.

The gain isn't the elimination of locking. It's that locking now has exactly **one** shape in your codebase, at one boundary, instead of being reinvented in every service that touches a balance.

### Relationship to §10

Related, independent, frequently confused:

| | Event sourcing | Ledger |
|---|---|---|
| State is | a fold over heterogeneous events | a sum over homogeneous entries |
| Built-in invariant | none | entries sum to zero, per commodity |
| Gives you | replay, time travel, full audit | conservation you can **verify**, plus audit |
| Requires the other? | no | no |

A ledger is close to a specialisation of event sourcing where the events are uniform and the fold is addition — but you can build one on plain Postgres tables with no event store anywhere, and that is often the right call. Conversely, event sourcing gives you no conservation guarantee, because arbitrary events have nothing to conserve.

If you're choosing one: **the ledger is the cheaper and higher-yield pattern.** It applies to a narrower slice of the domain, needs far less machinery, and delivers the audit trail people actually ask for.

---

## 12. Atomicity is a choice, not a given

§11 asserted that the database transaction survives in a smaller form — "append N balanced entries atomically." Duran's follow-up, *Ledger Transactions Don't Have to Be Atomic*, argues that even this deserves interrogation, and the argument is strong enough that the earlier claim needs qualifying rather than defending.

### Financial transactions are not database transactions

They *inspired* database transactions — Jim Gray defined transaction processing benchmarks in terms of debits and credits — and both match a layman's intuition: money leaves one account and immediately arrives at another.

It doesn't. Funds take seconds, a business day, sometimes a month. That interval is real and economically meaningful: whoever holds funds in transit can earn on them, use them for cash flow, treat them as short-term collateral. Duran calls this **up-in-the-airness**, and insists it's a sticky property of money rather than an implementation detail you can normalise away.

A database transaction has no such interval, by construction. Model one on the other and you model out the thing that makes money movement interesting.

The instinct is an engineering habit, not a domain truth. To an engineer "transaction" means ACID; in the world, a transaction is just an exchange, and exchanges routinely fail in transit. People refund. Cards get charged back. Notes turn out to be fake and goods get recalled. None of that is exceptional — it's Tuesday.

### The real cost: accounts that don't exist

Here is the part that should trouble anyone who took §7 seriously.

For a ledger transaction to be atomic, **the accounts involved must be able to represent an intermediary state of affairs.** You can't remove up-in-the-airness, so all-or-nothing requires checkpoints along the way — and you often can't know in advance where they need to be.

Duran's example: an ACH transfer. The funds leave the source account immediately, so the ledger writes a pending debit "freezing" money that is in fact already gone, plus a pending credit for the incoming side. Double-entry safe. A business day later the clearing house returns R12 — the account was sold to another institution. Under atomicity the only move is to roll everything back and start over, which is *not what happened*. The alternative is an intermediary in-transit account which, in his words, doesn't really exist, which accountants don't care about, and whose only purpose is to prop up an already failed design.

Name that in this document's vocabulary: **a domain entity that exists solely to satisfy an infrastructure constraint.** §7 spends its whole length arguing that persistence concerns must not shape domain objects. An in-transit account no one in the business would recognise is that failure in its purest form — and it hides well, because it looks like an account.

### Stripe's model: validate after, not before

Stripe's Ledger never assumed atomicity. Each entry is its own event, with its own timestamp, source system and arrival moment; the only thing entries share is an identifier. Money movement records a **creation** event (funds become pending, owned by Stripe) and later a **release** event (funds allocated to their destination). The two are completely independent — different services, out of order, no shared commit.

The single most transferable idea in the whole piece:

> The atomic model checks double-entry safety **before** creating the entries.
> Stripe moves the check to the end — **after** the entries exist.

When an entry lands without its counterpart, the imbalance doesn't disappear into a rollback. It surfaces as a non-zero balance on a **clearing account**, immediately visible, with three monitors watching:

| Monitor | Question it answers | Red flag |
|---|---|---|
| **Clearing** | does every clearing account sit at zero in steady state? | any non-zero balance |
| **Timeliness** | did both sides arrive inside the threshold? | a pending entry exceeding its SLA |
| **Completeness** | does every upstream record have a matching ledger event? | a record with no event |

A single missing entry lights up a dashboard.

Note what this does *not* break: conservation (§11's fitness function 6) still holds. The ledger never stops balancing — the residue of an unmatched movement is parked in a named account rather than smeared across the system. The invariant that matters becomes *every imbalance is attributable to a clearing account, and clearing accounts return to zero.*

### The reframe worth stealing

Duran's conclusion is the sentence to take away: the intermediary account required by the atomic model is transformed into an engineering dashboard, decoupling the accounting system from the engineering of it. **Accountants deal with accounts; engineers deal with dashboards.**

That is a separation-of-concerns argument, and it's the same one Explicit Architecture makes everywhere else. The in-transit account was an engineering concern wearing a domain costume. Non-atomicity evicts it to infrastructure and observability, leaving the domain model holding only accounts a person in the business would recognise.

It also matters downstream. Reconciliation is already miserable — Patrick McKenzie's description of it as a game designed to frustrate the player, arising from unstructured data in the pipelines between businesses, with the people doing the work unable to see the relationships that produced the invoices. Adding fictional accounts to that is gratuitous cruelty.

### The Saga rules

Duran frames non-atomic ledgers through the Sagas paper: break a long-lived transaction into smaller ones that can interleave. Four rules follow, and they're the operational spec:

1. **Entries only change status.** `pending → posted | archived`. Amount, account and direction never change. Immutability survives in spirit as long as old and new are distinguishable — a `discarded_at` timestamp is enough.
2. **Transaction status stops existing** while work is in flight. Once entries advance individually there is no shared state to report; only when the group completes is there a finalisation status. Expect this to hurt: `transaction.status` is usually scattered across the UI.
3. **Rollback is replaced by compensation.** When some entries are posted and the money is gone, "roll back" is meaningless. You append compensating entries — same amount, opposite direction. The atomic model *cannot* do this faithfully: its only recourse is to post the whole transaction and then reverse it, which misrepresents what happened.
4. **Double-entry safety is the ultimate validation.** Every change to the group must keep credits equal to debits. That is the only rule — which is precisely what makes it flexible.

Rule 4 is why non-atomicity buys **expressiveness**, not merely fault tolerance. Compensation doesn't have to return funds to origin. It can route them to an account accruing failures of a specific kind, or to a different provider on retry. Redirect, reroute, retry, accrue — all legal, all faithful, as long as it balances. "Payment failed, try a second processor" becomes a first-class ledger operation instead of a reversal followed by a fresh transaction that pretends the first never happened.

### Why this bites harder in *this* architecture

An observation Duran doesn't make, because he isn't writing about components: **the atomic ledger transaction quietly assumes a single database.**

§9 puts each component in charge of its own persistence. §10 makes some slices event-sourced. The moment Billing and Ordering own separate stores — or one publishes while the other subscribes — a transaction spanning both is off the table regardless of anyone's opinion about atomicity. Duran's own phrasing: the debit and the credit don't need to come from the same service.

So in a componentised app the question isn't "atomic or not" in the abstract. It's:

- **Does the ledger live entirely inside one slice?** Atomic is available, and probably right.
- **Does a movement cross slices?** Non-atomic is the only honest option. Anything else is a distributed transaction smuggled in under another name.

That's a sharper decision rule than "do it at scale," and it's forced by the component boundaries this document has been advocating since §3.

### In Hanami

The entry carries status and group identity; the transfer is the entity that changes state.

```ruby
# slices/ledger/domain/entry.rb
Entry = Data.define(
  :id, :transfer_id, :account, :commodity, :amount,
  :status,        # :pending | :posted | :archived
  :occurred_at, :discarded_at
) do
  def posted? = status == :posted
  def live?   = discarded_at.nil?
end
```

Each side posts independently — no operation spans both:

```ruby
module Ledger
  module Entries
    class Post < Ledger::Operation
      include Deps["ledger_store", "notifications"]

      def call(entry)
        advanced = step Domain::Decisions::AdvanceEntry.call(entry, to: :posted)

        ledger_store.append(advanced)
        notifications.instrument(Shared::Events::ENTRY_POSTED, advanced.to_h)

        Success(advanced)
      end
    end
  end
end
```

Clearing accounts are ordinary named accounts in the chart, not a special case in code:

```
clearing:ach_in_transit
clearing:card_capture
clearing:slice_handoff       # counterpart lives in another slice
clearing:provider_retry      # rerouted after a failure
```

And the three monitors become **production** fitness functions, extending §13:

```ruby
# 8. Clearing — non-zero at steady state means an entry is missing its counterpart.
RSpec.describe "clearing accounts" do
  it "returns to zero outside of in-flight windows" do
    Ledger::Slice["queries.clearing_balances"].call.each do |account, balances|
      balances.each do |commodity, amount|
        expect(amount).to eq(0), "#{account} holds #{amount} #{commodity}"
      end
    end
  end
end

# 9. Timeliness — no pending entry older than its account's SLA.
RSpec.describe "entry timeliness" do
  it "has no pending entry past its threshold" do
    stale = Ledger::Slice["queries.stale_pending"].call(now: Time.now)
    expect(stale).to be_empty, "stale: #{stale.map(&:id).join(", ")}"
  end
end

# 10. Completeness — every upstream record has a matching ledger entry.
```

Monitor 9 is the one that pays for itself. In the atomic model a stuck transfer is invisible until someone complains; here it's a row with a timestamp, and the alert fires before the support ticket.

### Pick your battle

| | Atomic | Non-atomic |
|---|---|---|
| Failure modes | two: succeeded or didn't | many, each visible and named |
| Partial failure | impossible by construction | recorded, measurable, correctable |
| Models reality | poorly — no in-transit state | faithfully |
| Domain model cost | fictional intermediary accounts | none; clearing accounts are real infrastructure |
| Reroute / retry / accrue | a reversal plus a new transaction | a first-class operation |
| Operational requirement | none beyond the database | clearing, timeliness and completeness monitors |
| Failure when you get it wrong | loud and immediate | silent, until reconciliation |

Duran's own position: with the engineering bandwidth and the monitoring infrastructure, non-atomic is better — non-atomicity gives you control and responsibility, and if you can shoulder the latter you may as well take the former. He notes that ledger vendors default to atomic largely because systems that are simple to understand and hard to implement are easier to sell, even at the cost of maintenance. He is also candid that he has worked somewhere naive about this, and that letting entries arrive out of sync without being strict about it is a time bomb.

That last admission is the operative one, and it makes the prerequisite explicit: **the monitors are not an enhancement, they're the price of entry.** Non-atomicity without clearing, timeliness and completeness dashboards isn't a more faithful model, it's an unreconciled mess with better vocabulary.

Practical default for an app built on this document:

1. **Start atomic, inside one slice.** Simple, well understood, and the §11 conservation test covers you.
2. **Go non-atomic when a movement crosses a slice boundary** — at that point you have no choice, so build the monitors as part of the same piece of work.
3. **Never adopt non-atomicity as an aesthetic preference.** The question to answer honestly is whether the dashboards will exist *before* you need them.

---

## 13. Fitness functions

Architecture that isn't tested decays. Four cheap, high-value tests:

**1. Slice isolation via boot.** Hanami's `HANAMI_SLICES` makes this trivially provable:

```bash
HANAMI_SLICES=ordering bundle exec rspec spec/slices/ordering
```

If Ordering can't boot without Billing, they're coupled. CI runs one job per slice.

**2. Container surface approval.** Snapshot each slice's public keys; unreviewed cross-slice imports fail the build:

```ruby
RSpec.describe "Ordering container surface" do
  it "exposes only the approved keys" do
    imported = Ordering::Slice.boot.keys.grep(/\A(billing|catalog)\./)
    expect(imported).to contain_exactly("billing.invoices.issue")
  end
end
```

**3. Domain purity.** Crude, effective:

```ruby
RSpec.describe "domain purity" do
  Dir["slices/*/domain/**/*.rb"].each do |file|
    it "#{file} has no framework dependencies" do
      source = File.read(file)
      expect(source).not_to match(/include Deps/)
      expect(source).not_to match(/Hanami::/)
      expect(source).not_to match(/_repo\b|relations\./)
    end
  end
end
```

**4. Port leakage.** For each declared port, assert the vendor name appears only in `adapters/` and `config/providers/`.

**5. Port coverage.** This is the one that closes the gap in §4 — the reason a shared example group is weaker than a compiled interface isn't expressiveness, it's that nobody is forced to invoke it. So force it. Declare the ports, then assert every implementation of each one is actually running its shared examples:

```ruby
# spec/architecture/port_coverage_spec.rb
PORTS = {
  "a payment gateway" => %w[
    Ordering::Adapters::StripePaymentGateway
    Ordering::Adapters::NullPaymentGateway
  ],
  "a receipt deliverer" => %w[
    Billing::Adapters::SmtpReceiptDeliverer
    Billing::Adapters::NullReceiptDeliverer
  ]
}.freeze

RSpec.describe "port coverage" do
  PORTS.each do |port, implementations|
    implementations.each do |klass|
      it "#{klass} is verified against '#{port}'" do
        example_groups = RSpec.world.example_groups.select { _1.described_class&.name == klass }
        metadata = example_groups.flat_map { _1.descendants.map(&:description) }

        expect(metadata).to include(a_string_including(port)),
          "#{klass} implements '#{port}' but never calls it_behaves_like"
      end
    end
  end
end
```

A cruder variant that needs no RSpec internals: grep each `adapters/*.rb` for the port it's registered under, then grep the matching spec file for `it_behaves_like`. Either way, adding an adapter without verifying it against its port now fails CI — which is the property the compiler was giving you for free.

---

## 14. Testing

The layers give you a pyramid that falls out of the design rather than being imposed on it:

| Layer | Test style | Speed |
|---|---|---|
| Domain (entities, VOs, domain services) | Plain unit tests, no Hanami, no DB | microseconds |
| Operations | Constructor-inject fakes via `Deps` | milliseconds |
| Repos | Integration, real DB | slow — few of them |
| Adapters | Contract tests (§4) + recorded HTTP | slow — few of them |
| Actions | Request specs with the operation stubbed | fast |
| Views | Direct object calls, no HTTP | fast |

The property worth protecting: **the majority of your tests should never touch a database or boot the framework.** If they do, the domain layer has leaked outward, and no amount of directory structure will save you.

---

## 15. Where this strains

Be honest about the costs before committing:

- **The mapper tax.** Struct ↔ entity mapping is real, repetitive work. For CRUD-heavy components it buys nothing. Mitigation: don't apply the domain layer uniformly — a Catalog slice can be repo + operation with no entities at all, while Ordering gets the full treatment. Graça himself notes in the comments that he rarely uses aggregates; the pattern set is a menu, not a checklist.
- **Ports are conventions, not contracts.** Ruby will happily let you `include Deps["stripe_client"]` in an operation. Note precisely where the weakness is: the shared examples in §4 *describe* more than a compiled interface could, so the loss is coverage, not expressiveness — nothing forces an adapter to be verified. The fitness functions in §13 are not optional extras here; they're the type system you don't have.
- **Slices are not a hard boundary.** Nothing stops `Ordering::Orders::Place` from referencing `Billing::Invoice` directly — the constant resolves. Test for it.
- **No built-in event bus.** You'll assemble one from `notifications`/dry-events plus a job queue for async delivery. Fine, but it's your code to own.
- **Non-atomic ledgers trade a loud failure for a silent one.** Atomicity fails immediately and obviously; unmatched entries fail quietly until reconciliation. That trade is only worth making with the monitors already running (§12).
- **Ledgers cost storage and write amplification.** Entries accumulate forever, balances need a projection to stay fast, and "just read the column" becomes "read the projection and trust the subscriber." Worth it for anything disputable; overkill for a counter nobody will audit.
- **Event sourcing multiplies all of the above.** If you take §10, you add event versioning, eventual consistency and replay cost on top of everything here. It's the right call for a ledger and the wrong one for a catalogue.
- **Cognitive load on the team.** Five directories per component, a mapping layer, and a container-key indirection are a real onboarding cost. Worth it for a long-lived app with contested subdomains; actively harmful for a six-week internal tool.

---

## 16. Adoption sequence

Don't build the full structure up front. Graça's closing point is that the map is not the territory — the architecture should be pulled into existence by pressure from the domain.

1. **Start in `app/`.** Actions, operations, repos. No slices, no domain layer. Ship.
2. **Add ports where volatility is.** The first external service you might swap or need to fake in tests gets a container key and a provider. Usually payments or email.
3. **Extract the first slice** when a subdomain has its own vocabulary and its own reasons to change — not when the directory gets large.
4. **Introduce the domain layer inside one slice** — whichever has invariants that keep getting duplicated across operations.
5. **Add events** the first time an operation grows a second unrelated side effect.
6. **Add fitness functions** as soon as slice #2 exists. Before that they test nothing; after that, they're the only thing keeping the boundary real.
7. **Model your conserved quantities as ledgers** (§11) the moment one exists — credits, seats, inventory, points. This is cheaper than §10 and pays off sooner; do it first if you're choosing between them.
8. **Keep ledger transactions atomic** until a movement crosses a slice boundary (§12). When it does, build the clearing/timeliness/completeness monitors in the same piece of work — never after.
9. **Consider event sourcing for exactly one slice** — the one where the audit trail is itself the product (§10). Never as a default, never app-wide, and not before the slice boundary has stopped moving.

---

## 17. Rules cheat sheet

```
Actions      → call operations. Never repos, relations, or adapters (writes).
Views        → call repos for reads. Never operations, never entities.
Operations   → orchestrate. Fetch, delegate to domain, persist, emit.
                Never SQL. Never vendor names. Never HTTP concepts.
Contracts    → structure at the edge, context in the operation, invariants in the domain.
                Validate inbound third-party payloads too. Never inject into domain/.
Domain       → pure Ruby. No Deps, no Hanami, no DB, no I/O.
Repos        → the only place relations are touched.
                Return entities to the write side, structs to the read side.
Relations    → the only place SQL lives.
Adapters     → the only place vendor SDKs and vendor exceptions appear.
Providers    → the only place adapters are named.
Ports        → a container key + a shared example group. Every adapter runs it.
                Verify the null object against the same group as the real one.
Events       → past tense, immutable, assumed valid. Validate before emitting, never in
                a projector. Projectors are pure: (state, event) -> state, no I/O.
Event store  → two methods: append_to_stream, read_from_stream. Treat as a port.
                Event-source per slice, never per app.
Ledgers      → conserved quantities get entries, not a mutable balance column.
                Balance is a projection. The invariant (sum to zero, per commodity)
                is a pure domain function, not a DB constraint.
                Name every source and sink. Entitlements are policy, not entries.
Transactions → append N balanced entries. No business logic between BEGIN and COMMIT.
                Atomic within a slice; non-atomic the moment a movement crosses one.
Non-atomic   → entries change status only; compensate, never roll back; double-entry
                is the sole validation. Unmatched entries park in a named clearing
                account. Clearing + timeliness + completeness monitors are the price
                of entry, not an upgrade.
Slices       → talk via events, or via explicitly exported keys. Never constants.
Shared kernel → event names and universal VOs. Nothing else. Keep it tiny.
```
