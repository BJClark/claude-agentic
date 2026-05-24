# Slicing Strategy Reference

## Definitions

**Vertical slice**: A phase that delivers a thin end-to-end capability — one workflow, one user story, one scenario — touching every layer it needs (DB, service, API, UI/consumer). The output is something a user or downstream system can *do* after the phase ships.

**Horizontal phase**: A phase scoped to one layer across many features (all schema changes, all services, all endpoints). Nothing works end-to-end until a later phase lands. Integration risk is maximized.

**Walking skeleton**: The first vertical slice — the thinnest possible end-to-end path that exercises the full stack for one capability. It proves the architecture holds before any investment in breadth.

**Bottom-up phasing**: A form of horizontal phasing that starts at the data layer and works up. Common default in LLM-generated plans. Produces the same deferred-integration problem.

---

## Why Default to Vertical

| | Vertical | Horizontal |
|---|---|---|
| Integration risk | Surfaces in Phase 1 | Surfaces in the last phase |
| Demo-ability | Every phase shows user-visible progress | "We built the foundation" |
| Descoping | Drop later phases; keep N working features | Drop later phases; keep 0 working features |
| Fast feedback | Designs validated by Phase 1 | Designs validated by final phase |
| Spec-first / BDD | Natural — one scenario per phase | Awkward — no scenario maps to a layer |
| Continuous delivery | Each phase is independently deployable | Only the final phase is deployable |

---

## The Shippable-Phase Smoke Test

For every candidate phase, ask:

> *"If we shipped only this phase and stopped, what new thing could a user / caller / downstream system do that they couldn't do before?"*

- **Good answer**: "Users can submit a draft order and see it in their list" → vertical
- **Bad answer**: "The order table exists and the repository is wired up" → horizontal

If the answer is "nothing yet," either:
1. **Merge** this phase into the next phase that consumes its output, or
2. **Justify it** explicitly as a named horizontal phase (see exceptions below)

---

## Acceptable Horizontal Phases

Horizontal phasing is rarely wrong — but it must be explicit, not the default.

Mark any horizontal phase in the plan with a `// horizontal — [justification]` annotation.

Accepted justifications:

- **Pure data migration**: The change has no user-visible behavior at all (rename a column, backfill nulls). Even here, prefer expand-contract over big-bang.
- **Library / tooling upgrade**: Changing a transitive dependency or build tool with no behavior change.
- **Cross-cutting refactor**: Rename a concept everywhere, move to a new module system, add a logging framework. Slicing by behavior isn't natural.
- **Genuine technical precondition**: The work cannot be tested or reviewed until some infrastructure exists first, AND there is no way to write a thin vertical slice that exercises the infrastructure. Document why.

When in doubt, try to slice vertically first. A horizontal phase that "felt necessary" often dissolves once you identify the smallest vertical slice that exercises the same infrastructure.

---

## Patterns

### New Feature — Walking Skeleton

```
Phase 1: [one happy-path user story, all layers]
  - migration + repo + service + endpoint + UI for the simplest case
  - User-visible: "User can create a draft X"

Phase 2: [next story or edge case]
  - User-visible: "User can publish X and see it in listings"

Phase 3: [error handling, validation, edge cases]
  - User-visible: "Invalid input rejected with clear error"
```

### Schema Migration — Expand-Contract

```
Phase 1: EXPAND (horizontal — pure schema change)
  - Add new column/table; dual-write to old + new path; old path authoritative
  - Justification: cannot validate new schema without data; no behavior changes yet

Phase 2: BACKFILL + VERIFY
  - Migrate historical data; verify read consistency under prod traffic
  - Justification: data correctness precondition for flip

Phase 3: FLIP (vertical — behavior change)
  - Read from new path; keep old as fallback; feature-flagged
  - User-visible: same behavior, now served from new schema

Phase 4: CONTRACT (horizontal — cleanup)
  - Remove old path, drop old column
  - Justification: pure removal, no behavior change
```

### Refactoring — Strangler Fig

```
Phase 1: INTRODUCE ABSTRACTION + ROUTE ONE FLOW
  - Add the new abstraction (e.g. new service / module)
  - Route exactly one complete user-facing flow through it end-to-end
  - Old flows untouched; both paths coexist
  - User-visible: "Checkout via new OrderService path works"

Phase 2–N: MIGRATE REMAINING FLOWS
  - One flow per phase, or group low-risk flows together
  - Delete old code path when the last flow is migrated

Phase FINAL: REMOVE OLD CODE
  - Horizontal cleanup phase; justified as pure removal
```

### Performance Work

```
Phase 1: P50 hot path optimized
  - Metric: median response time drops from Xms → Yms

Phase 2: P90 / bursty traffic
  - Metric: 90th percentile drops from Xms → Yms

Phase 3: P99 / tail latency
  - Metric: 99th percentile drops from Xms → Yms
```

---

## Anti-Patterns

**"Phase 1: data model"** → horizontal. The data model only has value when it backs behavior. Merge it into the first phase that makes the data visible or actionable.

**"Phase 1: infrastructure wiring"** → check if a vertical slice that exercises the infrastructure is possible. Often is.

**"Phase N: integration testing"** → testing is per-phase success criteria, not a phase. Each vertical phase's criteria includes the end-to-end test that goes green.

**Five phases, all named by component** (`Phase 1: Models`, `Phase 2: Services`, `Phase 3: API`, `Phase 4: UI`, `Phase 5: Tests`) → pure horizontal. Restructure so Phase 1 is the walking skeleton and each subsequent phase extends user-visible capability.

---

## Worked Example

### Bad (horizontal, bottom-up)

```
Phase 1: Order schema + migrations
Phase 2: OrderRepository + unit tests
Phase 3: OrderService + business logic
Phase 4: POST /orders API endpoint
Phase 5: UI order form + submission
```

Risk: nothing works end-to-end until Phase 5. A schema mistake in Phase 1 isn't caught until Phase 5.

### Good (vertical)

```
Phase 1: User can create a draft order [walking skeleton]
  - migration: orders table (minimal columns)
  - repository: create() + findById()
  - service: createDraftOrder()
  - endpoint: POST /orders (happy path)
  - UI: order form → success redirect
  Demoable, deployable (behind flag).

Phase 2: User can view their order list
  - repository: findByUser()
  - endpoint: GET /orders
  - UI: orders list page

Phase 3: Validation and error states
  - Service-layer validation
  - API error responses
  - UI inline field errors

Phase 4: Order submission (transitions draft → submitted)
  - State machine in service
  - Endpoint: PATCH /orders/:id/submit
  - UI: submit button + confirmation
```

Each phase is independently demoable. Scope can be cut after any phase and you have working software.
