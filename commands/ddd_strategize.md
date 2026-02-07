---
description: "DDD Step 4: Strategize — classify sub-domains and make investment decisions"
model: opus
---

# DDD Step 4: Strategize

Classify each sub-domain on the Core Domain Chart and make strategic investment decisions. Determine which contexts deserve deep modeling (CQRS/ES) versus simple implementations (CRUD).

## Prerequisites

- `research/ddd/03-sub-domains.md` must exist (run `/ddd_decompose` first)
- `research/ddd/01-alignment.md` for business context and value propositions

## Process Steps

### Step 1: Read Prerequisites

1. Read `research/ddd/03-sub-domains.md` completely
2. Read `research/ddd/01-alignment.md` for value propositions and constraints
3. Understand all bounded contexts and their preliminary classifications

### Step 2: Present Classification Framework

Explain the two axes to the user:

```
## Core Domain Chart

We'll classify each sub-domain on two axes:

**Business Differentiation** (x-axis): How much competitive advantage does this context provide?
- Low: Commodity functionality (authentication, payments)
- High: Unique to your business, hard for competitors to replicate

**Model Complexity** (y-axis): How complex is the domain logic?
- Low: Simple CRUD, few business rules
- High: Complex state machines, many invariants, nuanced rules

The quadrants suggest investment strategy:
- **High differentiation + High complexity** → Core Domain (invest heavily, deep DDD modeling)
- **High differentiation + Low complexity** → Core Domain, simpler (invest but keep lean)
- **Low differentiation + High complexity** → Supporting (necessary complexity, consider buying)
- **Low differentiation + Low complexity** → Generic (buy off the shelf or keep minimal)
```

### Step 3: Classify Each Sub-domain Interactively

For each bounded context identified in step 3:

```
### [Context Name]
**Current classification**: [from decomposition step]
**Building blocks**: [list]

**Business Differentiation**: How unique is this to your business?
1. Low — standard/commodity functionality
2. Medium — some customization needed
3. High — core competitive advantage

**Model Complexity**: How complex are the business rules?
1. Low — basic CRUD, few rules
2. Medium — moderate state management
3. High — complex invariants, state machines, nuanced rules

What would you rate this context?
```

Wait for the user's input on each context before proceeding.

### Step 4: Determine Architecture Strategy

Based on classifications, propose architecture approach per context:

| Classification | Architecture | Rationale |
|---------------|-------------|-----------|
| Core (high diff + high complexity) | CQRS/ES with full DDD tactical patterns | Worth the investment — aggregates, domain events, value objects |
| Core (high diff + low complexity) | Rich domain model, standard persistence | Differentiating but simple enough for CRUD with domain layer |
| Supporting (low diff + high complexity) | Consider buying/adapting existing solution | Complex but not differentiating — minimize custom code |
| Generic (low diff + low complexity) | CRUD or third-party service | Commodity — spend minimum effort |

### Step 5: Build Core Domain Chart

Create a Mermaid quadrant chart:

```mermaid
quadrantChart
    title Core Domain Chart
    x-axis Low Differentiation --> High Differentiation
    y-axis Low Complexity --> High Complexity
    quadrant-1 Core Domain
    quadrant-2 Supporting (Complex)
    quadrant-3 Generic
    quadrant-4 Core (Simple)
    [Context Name]: [0.8, 0.7]
    [Context Name]: [0.2, 0.3]
```

### Step 6: Present Strategy Summary

```
## Strategic Summary

| Context | Classification | Architecture | Investment Level |
|---------|---------------|-------------|-----------------|
| [Name] | Core | CQRS/ES | High — deep modeling |
| [Name] | Supporting | Adapted solution | Medium — functional |
| [Name] | Generic | Third-party/CRUD | Low — minimal |

**Implementation order** (core first):
1. [Core context] — highest business value
2. [Supporting context] — enables core
3. [Generic context] — last, simplest

Does this strategic assessment align with your priorities?
```

### Step 7: Write Strategy Artifact

Create `research/ddd/04-strategy.md`:

```markdown
---
ddd_step: 4
ddd_step_name: Strategize
domain: "[Domain Name]"
date: YYYY-MM-DD
status: complete
source: "research/ddd/03-sub-domains.md"
---

# DDD Strategy: [Domain Name]

## Core Domain Chart

` ``mermaid
quadrantChart
    title Core Domain Chart
    x-axis Low Differentiation --> High Differentiation
    y-axis Low Complexity --> High Complexity
    quadrant-1 Core Domain
    quadrant-2 Supporting (Complex)
    quadrant-3 Generic
    quadrant-4 Core (Simple)
    [Context plots]
` ``

## Sub-domain Classifications

### [Context Name]
- **Classification**: Core / Supporting / Generic
- **Business Differentiation**: High/Medium/Low — [rationale]
- **Model Complexity**: High/Medium/Low — [rationale]
- **Architecture Strategy**: CQRS/ES / Rich Domain Model / CRUD / Third-party
- **Investment Level**: High / Medium / Low
- **Rationale**: [Why this classification and strategy]

### [Context Name]
...

## Architecture Decisions

| Context | Pattern | Persistence | Rationale |
|---------|---------|------------|-----------|
| [Name] | CQRS/ES | Event Store | Complex invariants, audit trail needed |
| [Name] | CRUD | PostgreSQL | Simple domain, standard operations |
| [Name] | Third-party | N/A | Use [service] — commodity functionality |

## Implementation Priority
1. **[Context]** — [rationale for ordering]
2. **[Context]** — [rationale]
3. **[Context]** — [rationale]

## Open Questions
- [Strategic questions remaining]
```

### Step 8: Prompt Next Step

```
Strategy artifact written to `research/ddd/04-strategy.md`.

Summary:
- [N] core domains, [N] supporting, [N] generic
- Architecture: [summary of patterns chosen]
- Implementation order: [ordered list]

Next step: Run `/ddd_connect` to map relationships between bounded contexts and define integration patterns.
```

## Important Guidelines

1. **User decides classification**: Present the framework, but let the user rate differentiation and complexity
2. **Core domains are rare**: Most systems have 1-2 core domains. If everything is "core", push back
3. **Architecture follows strategy**: CQRS/ES is only for contexts that justify the complexity
4. **Don't over-invest in generic**: Authentication, payments, email — use existing solutions
5. **Implementation order matters**: Core first, then supporting contexts that enable core, then generic
6. **Preserve building block IDs**: Continue referencing E1, C1, etc. from the event catalog
