# From PRD to production: a modern DDD workflow

**The fastest path from a Product Requirements Document to a CQRS/Event Sourced architecture runs through a structured discovery process — not code.** Modern DDD practitioners follow an 8-step iterative workflow (the DDD Starter Modelling Process) that moves from business understanding through collaborative domain discovery, strategic decomposition, and tactical design before writing a single line of implementation code. This process, refined by the DDD Crew community and practitioners like Alberto Brandolini, Nick Tune, and Adam Dymitruk, has been stripped of enterprise ceremony and adapted for solo developers and small teams using free digital tools like Miro, Excalidraw, and Context Mapper.

The critical insight driving modern DDD practice is that **discovery cannot be skipped**. Teams who jump straight to coding consistently misidentify domain boundaries, build oversized aggregates, and create distributed monoliths. Even a solo developer investing 4–6 hours in structured EventStorming and bounded context identification will produce dramatically better architecture than weeks of ad-hoc refactoring.

---

## The 8-step journey from requirements to running code

The DDD Starter Modelling Process (5,400+ GitHub stars) organizes the entire workflow into four phases with eight iterative steps. This is not waterfall — teams jump between steps constantly — but the linear ordering provides useful scaffolding.

**Phase 1 — Align and understand.** Start by orienting around the business model using a Business Model Canvas or Product Vision Board. The goal is answering: what does this system need to do, for whom, and why does it matter? For a solo developer working from a PRD, this means reading the PRD critically and identifying the core value proposition, the users involved, and the business outcomes expected.

**Phase 2 — Strategic architecture.** This is where the real work begins. Three steps happen here: **Discover** the domain visually using EventStorming or Domain Storytelling. **Decompose** the domain into sub-domains by identifying natural clusters. **Strategize** by classifying each sub-domain as core (competitive advantage, deserves the best engineering), supporting (necessary but not differentiating), or generic (buy off the shelf). Eric Evans' ratio holds: the core domain should be roughly 5% of code but take 80% of effort and deliver 20% of total value.

**Phase 3 — Strategy and organization design.** **Connect** bounded contexts by defining their relationships using context mapping patterns (Partnership, Customer-Supplier, Anti-Corruption Layer, Open Host Service, Conformist, Shared Kernel, Separate Ways). **Organize** teams around bounded contexts following Team Topologies principles. For small teams, this step is lightweight — it's really about deciding which contexts share code and which communicate through events or APIs.

**Phase 4 — Tactical architecture.** **Define** each bounded context's internals using the Bounded Context Canvas and Aggregate Design Canvas. **Code** the domain model using tactical DDD patterns (Entities, Value Objects, Aggregates, Domain Events, Repositories). Steps 7 and 8 happen simultaneously in practice — insights from coding continuously reshape the design.

---

## EventStorming: the discovery engine that drives everything

EventStorming operates at three progressively detailed levels. Each level produces distinct artifacts and answers different questions.

**Big Picture EventStorming** explores the entire domain in a half-day session. Everyone writes Domain Events on orange sticky notes in past tense ("Order Placed," "Payment Received") and places them on a wide timeline. The process moves through chaotic exploration (30 minutes of parallel brainstorming), timeline enforcement (sorting events left-to-right), identification of pivotal events that signal phase boundaries, and an explicit walkthrough where participants narrate the timeline and challenge gaps. The artifacts produced are a complete event timeline, hotspots (red stickies marking problems), opportunities (green stickies), and identified actors and external systems. **Pivotal events — the orange stickies where the business fundamentally shifts phase — are the strongest signal for bounded context boundaries.**

**Process Modeling EventStorming** zooms into a specific business process with 3–8 people. This level adds commands (blue stickies, imperative voice: "Place Order"), policies (lilac stickies: "When order placed, then send confirmation"), and read models (green stickies: information users need to make decisions). The flow pattern becomes: Actor → View → Command → Aggregate → Domain Event → Policy → next flow. Brandolini's recent evolution frames this as a "collaborative game" with formal rules: every path must complete, and grammar must be respected.

**Software Design EventStorming** designs the actual software within a bounded context. This level introduces aggregates (large yellow stickies). Brandolini's technique for identifying aggregates is elegant: have participants write business rules on blank stickies, then group rules that naturally belong together — the groups become aggregates. Bounded context boundaries are drawn as solid lines around related aggregate clusters, with the key heuristic being **where language changes between events, you've crossed a context boundary**.

### The color code reference

| Color | Element | Grammar | Example |
|-------|---------|---------|---------|
| Orange | Domain Event | Past tense | "Order Placed" |
| Blue | Command | Imperative | "Place Order" |
| Yellow (large) | Aggregate | Noun | "Order" |
| Yellow (small) | Actor/Role | Stick figure | "Customer" |
| Lilac | Policy | When...then | "Billing Policy" |
| Green | Read Model/View | Screen name | "Order Summary" |
| Pink | External System | System name | "Stripe" |
| Red/Magenta | Hotspot | Question/concern | "What if payment fails?" |

---

## Event Modeling: the blueprint that bridges discovery and implementation

Event Modeling, created by Adam Dymitruk in 2019, extends EventStorming into a complete system specification. Where EventStorming produces shared understanding and bounded contexts, Event Modeling produces an implementable blueprint showing information flow over time. It follows seven steps: brainstorm events, establish chronological order, create a storyboard with UI wireframes, identify inputs (commands), identify outputs (views/read models), organize into swim lanes, and elaborate into implementable features.

Event Modeling uses four building block patterns. The **Command pattern** shows a user viewing information, submitting a command, and an event being stored. The **Read Model pattern** shows events projected into views. The **Automation pattern** handles system-triggered behavior without human intervention. The **Translation pattern** manages external system integration. The practical advantage for small teams is that Event Modeling produces independent "slices" of work — each slice contains its commands, events, and projections and can be implemented autonomously.

**Domain Storytelling** offers a complementary approach particularly suited to solo developers. Using a pictographic language of actors, activities, and work objects connected by numbered arrows, it captures one scenario at a time in a structured narrative. The tool Egon.io (free, web-based) supports this method. The recommended combination: use Domain Storytelling first to stabilize the narrative of what actually happens, then use EventStorming to discover events, commands, and aggregates for CQRS/ES implementation.

---

## Designing aggregates, commands, and projections for CQRS/ES

The transition from EventStorming artifacts to CQRS/Event Sourcing architecture follows a direct mapping. Commands (blue stickies) become the write side. Domain Events (orange stickies) become the event store entries. Read Models (green stickies) become projections. Aggregates (yellow stickies) become consistency boundaries that accept commands and emit events.

**Vaughn Vernon's four rules for aggregate design** remain the foundation, with modern refinements. First, **model true invariants in consistency boundaries** — an aggregate is a transactional boundary where business rules requiring immediate consistency live. The key question: "Would the business accept a brief delay in enforcing this rule?" If yes, use eventual consistency across separate aggregates. Second, **design small aggregates** — roughly 70% of aggregates should be just a root entity with value-typed properties. Third, **reference other aggregates by identity only**, never by object reference. Fourth, **use eventual consistency outside the boundary** via domain events.

Commands must express business intent, not database operations. "CancelOrder" captures meaning; "DeleteOrder" does not. Each command targets exactly one aggregate and produces one or more events. The implementation pattern separates command handling (validation and event emission) from state mutation (which happens only in event handlers during replay). This separation is what makes event sourcing work — replay produces identical state because state changes are derived exclusively from events.

**Projection design follows five rules.** Denormalize aggressively — each projection should answer its specific query with a single record fetch, using whatever storage technology suits it best (Elasticsearch for search, Neo4j for graphs, PostgreSQL for relational queries). Projection handling must be idempotent. Read models are disposable and rebuildable from events. Build projection rebuild capability from day one. Design the UI for eventual consistency using optimistic updates or redirect patterns.

### The critical design questions checklist

When designing **aggregates**, ask: What are the true invariants requiring transactional consistency? What is the minimum data set that must be consistent in a single transaction? Could this be a Value Object instead of an Entity? How many events will this aggregate accumulate over time? What happens when two users modify it simultaneously?

When designing **events**, ask: Does this represent a business fact, not a technical operation? Does it contain enough context to be meaningful independently? What is its serialized form — you're committing to this long-term? How will you handle event versioning as the schema evolves?

When designing **projections**, ask: What specific query does this serve? Can it be rebuilt from events at any time? What technology best matches this query pattern? How will you handle the gap between event storage and read model updates in the UI?

---

## Diverge and converge: making architecture decisions without analysis paralysis

The Design Council's Double Diamond maps directly onto DDD work. **Diamond 1 (Problem Space):** diverge to discover the domain broadly through EventStorming, then converge to define bounded contexts and sub-domains. **Diamond 2 (Solution Space):** diverge to explore multiple architectural options for each context, then converge to commit to specific aggregate designs and technology choices.

João Rosa (Xebia) describes a practical technique for the convergence phase of context mapping. After Big Picture EventStorming, split into small groups of 3–4 people. Each group independently creates their own Context Map from the EventStorm output. During show-and-tell, one volunteer identifies bounded contexts that are the same across groups — typically 50–80% of the map. The remaining discussion focuses entirely on genuine boundary tensions where groups disagree, avoiding fatigue from rehashing agreements.

For solo developers, the diverge/converge cycle becomes internal. During diverge phases, generate multiple possible boundary configurations without judging them. Write each option on a separate area of your Miro board. During converge phases, evaluate options against concrete criteria: Does each context have coherent language? Can each be independently deployable? Would changing one context force changes in another? **The "Groan Zone" — the painful transition between divergent and convergent thinking — is normal.** Timeboxing and dot-voting (even solo, ranking options 1-5) push past it.

---

## The lightweight solo/small-team toolkit

A practical discovery session for a solo developer or pair takes 4–6 hours across two sessions, using free tools.

**Session 1 (2–3 hours): Discovery and decomposition.** Open Miro (free tier gives 3 boards) or Excalidraw. Write domain events from your PRD on orange stickies in past tense — start with the end state ("Invoice Paid") and work backward asking "what happened before this?" Arrange on a timeline. Add commands (blue), actors (yellow), and policies (lilac). Identify clusters where language is consistent. Name the clusters — these are candidate bounded contexts. Mark pivotal events at boundaries.

**Session 2 (2–3 hours): Strategy and definition.** Classify each context as core, supporting, or generic using a Core Domain Chart (plot on axes of business differentiation vs. model complexity). For your core domain, fill in the Bounded Context Canvas (available as a free Miro template, currently v5): name, description, strategic classification, inbound/outbound communication, ubiquitous language, business rules, assumptions, and open questions. For key aggregates in the core domain, complete the Aggregate Design Canvas: enforced invariants, handled commands, created events, state transitions, and throughput estimates.

The essential toolchain for modern DDD discovery:

- **Visual collaboration:** Miro (free, has official Brandolini-endorsed EventStorming templates) or Excalidraw (free, open-source)
- **Domain Storytelling:** Egon.io (free, web-based)
- **Formal modeling:** Context Mapper VS Code extension (generates context map diagrams, PlantUML, and provides automated architectural refactorings like Split Bounded Context by Features)
- **Decision documentation:** Architecture Decision Records as markdown files in `docs/decisions/` using the Michael Nygard template (Status, Context, Decision, Consequences)
- **Canvases:** Bounded Context Canvas and Aggregate Design Canvas from the DDD Crew GitHub repositories

---

## Common traps that derail CQRS/ES projects

**The biggest anti-pattern is CRUD events.** Modeling events as "CustomerCreated/CustomerUpdated/CustomerDeleted" destroys the value of event sourcing. "CustomerAddressChanged" loses whether this was a correction or an actual move. Events must capture business meaning: "CustomerRelocated" vs "CustomerAddressCorrected" are different facts with different downstream implications.

**Applying CQRS system-wide is the second most common mistake.** Martin Fowler warns explicitly: "CQRS should only be used on specific portions of a system (a Bounded Context), not the system as a whole." Most bounded contexts are simple enough for standard CRUD. Reserve CQRS/ES for contexts where read and write models diverge significantly, audit trails matter, or business logic is genuinely complex.

**Oversized aggregates** cause concurrency conflicts and performance problems. **Undersized aggregates** create excessive saga coordination. The sweet spot comes from honestly asking domain experts whether brief delays between related operations are acceptable — the answer is usually yes, which means separate aggregates with eventual consistency.

**Starting with a framework before understanding the patterns** adds accidental complexity. Nick Chamberlain's advice: implement CQRS/ES with plain code first. Bring in frameworks like Marten (.NET), EventSauce (PHP), or @node-ts/ddd (TypeScript) only after you've discovered what complexity your specific domain actually requires.

Finally, **starting with microservices instead of a modular monolith** is the architectural equivalent of premature optimization. Modern consensus is overwhelming: begin with a modular monolith where each bounded context is a separate module with its own domain, application, and infrastructure layers. Enforce boundaries with architecture tests. Extract to microservices only after boundaries have proven stable and the operational overhead is justified by specific scaling, security, or team autonomy needs.

---

## Conclusion

The modern DDD workflow for small teams is not a heavyweight enterprise process — it's a focused **4–6 hour discovery investment** that produces a small set of high-value artifacts: an EventStorm timeline, a context map, Bounded Context Canvases for core domains, and Aggregate Design Canvases for key aggregates. The process follows a natural rhythm of diverging to explore possibilities (brainstorming events, generating multiple boundary options) and converging to make decisions (classifying domains, committing to aggregate designs, writing ADRs).

The direct path from PRD to CQRS/ES architecture is: understand the business context → discover domain events through EventStorming → decompose into bounded contexts at linguistic boundaries → classify core vs. supporting vs. generic → design aggregates around true invariants → map commands to aggregates and events to projections → code the core domain with full DDD patterns while keeping supporting contexts simple. The model will be wrong initially. That is expected, correct, and the entire reason the architecture should favor a modular monolith with clear boundaries that can evolve as understanding deepens.