---
description: "DDD Step 7: Define bounded context canvases and aggregate design canvases"
model: opus
---

# DDD Step 7: Define (Canvases)

Build formal Bounded Context Canvases and Aggregate Design Canvases for each context. Synthesize all prior artifacts into structured canvases with Mermaid state diagrams for aggregate lifecycles.

## Prerequisites

- ALL prior artifacts must exist:
  - `research/ddd/01-alignment.md`
  - `research/ddd/02-event-catalog.md`
  - `research/ddd/03-sub-domains.md`
  - `research/ddd/04-strategy.md`
  - `research/ddd/05-context-map.md`

## Process Steps

### Step 1: Read All Prerequisites

Read ALL five prior artifacts completely. Every field in the canvases draws from information already discovered. Do not proceed without full context.

### Step 2: Determine Canvas Scope

Based on strategic classification from `04-strategy.md`:
- **Core contexts**: Full Bounded Context Canvas + Aggregate Design Canvas for each aggregate
- **Supporting contexts**: Full Bounded Context Canvas + abbreviated Aggregate Design Canvas
- **Generic contexts**: Abbreviated Bounded Context Canvas only (minimal investment)

Present the plan:

```
## Canvas Plan

Based on strategic classification:

**Full canvases** (Bounded Context + Aggregate Design):
- [Core Context 1] — [N] aggregates
- [Core Context 2] — [N] aggregates

**Bounded Context Canvas only**:
- [Supporting Context 1]
- [Supporting Context 2]

**Abbreviated canvas**:
- [Generic Context 1]

We'll work through each context one at a time, starting with core domains.

Ready to begin with [Core Context]?
```

### Step 3: Build Canvases Per Context

For each context (core first, then supporting, then generic):

**A. Spawn `ddd-canvas-builder` agent:**
- Provide paths to ALL five prior artifacts
- Specify which context to build canvases for
- Instruct to mark `[INSUFFICIENT DATA]` for gaps

**B. Present the Bounded Context Canvas for review:**

```
## Bounded Context Canvas: [Context Name]

| Field | Value |
|-------|-------|
| **Name** | [Context Name] |
| **Purpose** | [From alignment + sub-domains] |
| **Classification** | [From strategy] |
| **Architecture** | [From strategy — CQRS/ES, CRUD, etc.] |

### Ubiquitous Language
| Term | Definition |
|------|-----------|
| [Term] | [Definition from context vocabulary] |

### Business Rules
- [Rules from events, policies, and invariants]
- [INSUFFICIENT DATA] — [gap description]

### Inbound Communication
| Source | Message | Type | Pattern |
|--------|---------|------|---------|
| [Context] | [Data] | [Event/Query/Command] | [From context map] |

### Outbound Communication
| Target | Message | Type | Pattern |
|--------|---------|------|---------|
| [Context] | [Event] | Domain Event | [From context map] |

---

Does this canvas accurately represent the [Context Name] context?
- Any business rules missing?
- Is the ubiquitous language complete?
- Are the communication patterns correct?
```

**C. For core/supporting contexts, present each Aggregate Design Canvas:**

```
## Aggregate Design Canvas: [Aggregate Name]

### Enforced Invariants
- [Invariant from business rules and policies]

### Handled Commands
| Command | Pre-conditions | Post-conditions |
|---------|---------------|-----------------|
| C1 ([Name]) | [What must be true before] | E1 ([Event]) emitted |

### Created Events
| Event | Key Data |
|-------|----------|
| E1 ([Name]) | [Fields carried in the event] |

### State Lifecycle

` ``mermaid
stateDiagram-v2
    [*] --> [Initial State] : C1 ([Command])
    [State A] --> [State B] : E2 ([Event])
    [State B] --> [*]
` ``

### Correctness Criteria
- [Testable assertion about the aggregate]
- [INSUFFICIENT DATA] — [gap description]

---

Does this aggregate design look correct?
- Are the invariants complete?
- Is the state lifecycle accurate?
- Any commands or events missing?
```

Wait for user confirmation on each canvas before proceeding to the next.

### Step 4: Write Canvases Artifact

Create `research/ddd/06-canvases.md`:

```markdown
---
ddd_step: 7
ddd_step_name: Define (Canvases)
domain: "[Domain Name]"
date: YYYY-MM-DD
status: complete
source: "research/ddd/05-context-map.md"
---

# DDD Canvases: [Domain Name]

## Table of Contents
- [Bounded Context Canvas: Context 1](#bounded-context-canvas-context-1)
  - [Aggregate: Aggregate 1](#aggregate-design-canvas-aggregate-1)
  - [Aggregate: Aggregate 2](#aggregate-design-canvas-aggregate-2)
- [Bounded Context Canvas: Context 2](#bounded-context-canvas-context-2)

---

## Bounded Context Canvas: [Context Name]

[Full canvas as reviewed with user]

### Aggregate Design Canvas: [Aggregate Name]

[Full canvas with Mermaid stateDiagram-v2]

---

[Repeat for all contexts and aggregates]

---

## Data Gaps Summary
| Context | Field | Gap |
|---------|-------|-----|
| [Context] | [Field] | [INSUFFICIENT DATA] — [description] |

## Decisions Made During Review
| Decision | Context | Rationale |
|----------|---------|-----------|
| [Decision] | [Context] | [Why] |
```

### Step 5: Prompt Next Step

```
Canvases written to `research/ddd/06-canvases.md`.

Summary:
- [N] Bounded Context Canvases
- [N] Aggregate Design Canvases
- [N] state lifecycle diagrams
- [N] data gaps flagged as [INSUFFICIENT DATA]

Next step: Run `/ddd_plan` to convert all DDD artifacts into implementation plans compatible with `/implement_plan`.
```

## Important Guidelines

1. **One canvas at a time**: Present and validate each canvas individually — don't dump all at once
2. **Core contexts first**: They deserve the most attention and detailed canvases
3. **`[INSUFFICIENT DATA]` over guessing**: Never invent invariants or business rules
4. **Valid Mermaid state diagrams**: Use `stateDiagram-v2` with `[*]` for start/end states
5. **Cross-reference context map**: Inbound/outbound must align with relationships in `05-context-map.md`
6. **Preserve building block IDs**: E1, C1, A1, P1, R1 must carry through from event catalog
7. **Correctness criteria are testable**: "Order total must equal sum of line items" not "Order works correctly"
