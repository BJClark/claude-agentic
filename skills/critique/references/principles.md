# Principles (v1)

Twenty-five principles drawn from Rails convention, 37signals OSS (Campfire, Writebook, Fizzy), Domain-Driven Design (Evans), and Rails performance (Berkopec).

Each principle has a stable id (`P01`…`P25`), a one-line rule, a `stack:` tag, a review prompt, and — where the Rails framing doesn't translate cleanly — a note for other stacks.

`stack:` values:
- `general` — applies to any codebase.
- `web` — applies to any HTTP/MVC-shaped system.
- `rails` — framework-specific; generalizes with translation.
- `rails-runtime` — only meaningful when Puma/Sidekiq/Ruby runtime is in play.

---

## Core Rails

### P01 — Prefer framework methods over bespoke implementation
**Rule**: If the helper you're writing sounds like it should exist, it probably does — `pluck`, `find_each`, `in_groups_of`, `to_sentence`, `presence`.
**Stack**: general
**Review prompt**: Does any handwritten helper duplicate a stdlib/framework method? Flag the bespoke one.
**Translation outside Rails**: Replace "Rails" with the stdlib + primary framework for the stack (e.g. `itertools`, `lodash`, `collect`).

### P02 — Prefer domain language over short technical names
**Rule**: `Subscription#cancel!` beats `Subscription#update_status(2)`. Code should read like the business.
**Stack**: general
**Review prompt**: Do public method names describe *what happens in the domain* or *how the DB changes*? Flag the latter.

### P03 — Fat models, skinny controllers, dumb views
**Rule**: Controllers route; views render; models know what's true. Branching business rules in a controller is a bug waiting to move.
**Stack**: web
**Review prompt**: Does a controller/handler branch on business state, compute derived values, or persist domain decisions? If yes → flag.
**Translation outside Rails**: Read "controller" as "HTTP handler / route / action"; read "model" as the domain layer (entity, aggregate, domain service).

### P04 — Honor convention ruthlessly
**Rule**: `orders` table, `Order` model, `order_id` FK, `OrdersController`. Every deviation costs you and every tool in the ecosystem.
**Stack**: general
**Review prompt**: Is a name, path, or file layout deviating from the project's established convention without a stated reason? Flag.

### P05 — Express queries as named scopes
**Rule**: `Order.recent.unpaid.for_customer(x)` is a sentence. Ad-hoc `where` chains scattered across callers aren't.
**Stack**: rails
**Review prompt**: Are identical-looking `where` clauses appearing in ≥2 call sites? Suggest consolidating to a scope.
**Translation outside Rails**: Repository methods / query objects that name the filter, instead of re-building predicates inline.

### P06 — Trust the database
**Rule**: Validations are UX; constraints are integrity. Add `NOT NULL`, FKs, unique indexes — don't rely on application code to guard what SQL enforces for free.
**Stack**: general
**Review prompt**: Does the code assume a column is non-null, unique, or references a real row without a schema-level guarantee? Flag.

### P07 — Preload by intent, not defensively
**Rule**: `includes`/`preload` at the query site where you know the access pattern. Fix N+1s where they're born, not by sprinkling everywhere.
**Stack**: general
**Review prompt**: Is there an N+1 at a call site? Is there a preload in a place where the caller doesn't actually access the association? Flag either.

### P08 — POROs before concerns, concerns before service objects
**Rule**: Plain objects answer most "where does this go" questions. A `services/` directory tends to become the graveyard where undesigned code hides under a noun.
**Stack**: rails
**Review prompt**: Is a new `FooService`/`FooManager`/`FooHandler` being introduced where a PORO or concern would have worked? Flag.
**Translation outside Rails**: "Manager", "Helper", and "Util" classes carry the same smell in any language.

### P09 — Keep callbacks local and boring
**Rule**: `before_validation :normalize_email` is fine. `after_commit :send_welcome_email, :enqueue_billing, :sync_to_crm` is how side effects fuse into something untestable.
**Stack**: rails
**Review prompt**: Does a single model have ≥2 `after_*` callbacks that trigger cross-aggregate side effects? Flag.
**Translation outside Rails**: Any framework's lifecycle hooks (ORM events, middleware, signals) — chained side effects are the smell.

### P10 — Test behavior through framework seams
**Rule**: Request specs and system specs are cheap insurance. Over-mocked unit tests calcify structure and lie about correctness — mock at boundaries (HTTP, mail, jobs), not between your own objects.
**Stack**: general
**Review prompt**: Do new tests mock collaborators owned by the same team/module? Flag. Are HTTP/mail/job boundaries *not* mocked? Flag.

---

## Lessons from 37signals OSS

### P11 — Everything is CRUD — even verbs
**Rule**: `StarsController#create` and `#destroy` instead of `PATCH /messages/:id/star`. Actions that feel like verbs become nested resources.
**Stack**: web
**Review prompt**: Is a new non-CRUD action (e.g. `PATCH /things/:id/verb`) being added? Flag and suggest a nested resource.

### P12 — Model state as records, not booleans
**Rule**: A `Message` `has_many :boosts` rather than `boosted: true`. Records carry timestamps, authorship, history, and undo for free.
**Stack**: general
**Review prompt**: Does a new boolean column represent an *action* (liked, starred, published, cancelled)? Suggest modeling as a record.

### P13 — Prefer concerns over service objects
**Rule**: Slice fat models along real seams — `Room::Accesses`, `Room::MessageCreation` — so the file reads like a table of contents.
**Stack**: rails
**Review prompt**: Is the urge to extract a service actually the urge to navigate a large file? Flag service-object extractions that could be concerns/mixins.
**Translation outside Rails**: The general principle: slice large modules along domain seams, not along "verbs".

### P14 — Build the thin thing yourself before pulling a gem
**Rule**: Campfire has no Devise, no Pundit, no Sidekiq, no Redis. An 80-line version that fits your app beats a gem whose assumptions won't still fit in three years.
**Stack**: general
**Review prompt**: Is a new dependency being added where <150 lines of in-repo code would cover the actual usage? Flag.

### P15 — Let the platform do it before JavaScript does
**Rule**: `:has()`, `<dialog>`, view transitions, and `@starting-style` replace code that used to need a controller.
**Stack**: web
**Review prompt**: Is new JS (Stimulus controller, React component, handler) doing something modern CSS/HTML can do declaratively? Flag.

---

## In the Spirit of Eric Evans

### P16 — Make the ubiquitous language actually ubiquitous
**Rule**: URL, mailer subject, job name, column — all the same vocabulary the domain experts use. Two dialects means every conversation pays a translation tax.
**Stack**: general
**Review prompt**: Do the user-facing term, the URL, the column, and the class name all use the same word? Flag any divergence.

### P17 — Wrap meaningful primitives in value objects
**Rule**: `EmailAddress`, `Money`, `DateRange` — immutable, compared by value, with their own behavior.
**Stack**: general
**Review prompt**: Is a primitive (string, int, pair of floats) being passed through ≥3 functions with implicit invariants (currency, timezone, format)? Suggest a value object.

### P18 — Aggregate roots are the only door in
**Rule**: Outside code never reaches through `order.line_items.find(x).update(...)` — it calls `order.adjust_line_item(x, …)` and lets the root enforce invariants.
**Stack**: general
**Review prompt**: Does external code mutate a child via traversal from a root? Flag the reach-through.

### P19 — When a word means two things, split the context
**Rule**: `Billing::Customer` is not `Publishing::Author`. Collapsing them into one 2,000-line `User` is the most common Rails mistake at scale.
**Stack**: general
**Review prompt**: Does a single entity accrete fields/behaviors that only some callers use, gated by `if type == …`? Flag — probably two contexts fused.

### P20 — Name what happened, don't just react
**Rule**: Publish a `UserSignedUp` event rather than chaining `after_commit` callbacks. Events describe the domain and are greppable; callbacks describe persistence and aren't.
**Stack**: general
**Review prompt**: Is new cross-aggregate behavior being wired through persistence hooks rather than a named domain event? Flag.

---

## In the Spirit of Nate Berkopec

### P21 — Measure before you touch anything
**Rule**: A production APM — Skylight, Scout, Datadog, pick one — is the floor. Without it you're optimizing on vibes.
**Stack**: general
**Review prompt**: Is a performance change being made without a referenced measurement? Flag the absence of evidence.

### P22 — Chase p95, not the mean
**Rule**: Average response time smears fast cache hits over slow requests that actually hurt users. The goal is the long tail.
**Stack**: general
**Review prompt**: Does a perf-motivated change cite "average" rather than a tail percentile? Flag.

### P23 — Most "slow" is N+1s and a missing index
**Rule**: `bullet`/`prosopite` in dev/test, `pg_stat_statements` in prod. A seq scan on a million-row table is a five-minute `add_index`.
**Stack**: general
**Review prompt**: Before accepting an architectural change for perf reasons, ask: has an N+1 audit run, and do the query predicates have matching indexes? Flag if not.

### P24 — Cache is debt, not a free win
**Rule**: Every cache `fetch` is a bet you'll invalidate correctly. Russian-doll fragment caching with `touch: true` works because the framework handles invalidation — ad-hoc `expires_in` caches are how you ship stale data.
**Stack**: general
**Review prompt**: Is a new cache entry being added with a TTL but no clear invalidation path? Flag.

### P25 — Tune Puma and Sidekiq to your actual workload
**Rule**: Defaults are a guess. I/O-bound → more threads; CPU-bound → more workers, fewer threads. Set `MALLOC_ARENA_MAX=2` or use jemalloc before concluding you have a memory leak.
**Stack**: rails-runtime
**Review prompt**: Is Puma/Sidekiq config being changed without workload evidence (thread wait ratio, CPU saturation, memory growth curve)? Flag.
