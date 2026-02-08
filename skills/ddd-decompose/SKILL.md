---
name: ddd-decompose
description: "DDD Step 3: Decompose the domain into sub-domains and bounded contexts"
model: opus
context: fork
allowed-tools: Read, Grep, Glob, Write, Edit, AskUserQuestion, Task
argument-hint: [domain-name]
---

# DDD Step 3: Decompose

Ultrathink about language boundaries and context separation. Consider where vocabulary shifts meaning, where pivotal events mark phase transitions, and where actor responsibilities diverge.

Identify bounded context boundaries by analyzing language patterns in the event catalog.

**Input**: $ARGUMENTS

## Current Context

- **Branch**: !`git branch --show-current`
- **Last Commit**: !`git log -1 --oneline`

## Prerequisites

- `research/ddd/02-event-catalog.md` must exist (run `/ddd_discover` first)
- `research/ddd/01-alignment.md` should be accessible

## Process Steps

### Step 1: Read Prerequisites

1. Read `research/ddd/02-event-catalog.md` completely
2. Read `research/ddd/01-alignment.md` for business context

### Step 2: Spawn Context Analyzer Agent

Spawn a `ddd-context-analyzer` agent:
- Provide paths to alignment doc and event catalog
- Instruct to identify language clusters, pivotal events, and sub-domain classifications

### Step 3: Present Proposed Boundaries

Present boundaries and validate each interactively:

```
## Proposed Sub-domain Boundaries

### 1. [Context Name]
**Building blocks**: E1, E3, C1, C4, A1, P1, R1
**Core vocabulary**: [key terms]
**Boundary signal**: [why separate — language shift, pivotal event, actor change]

```

After presenting each proposed boundary, ask:

<invoke name="AskUserQuestion">
  questions: [{
    "question": "Does the [Context Name] boundary grouping make sense?",
    "header": "Boundary",
    "multiSelect": false,
    "options": [
      {
        "label": "Grouping is correct",
        "description": "These building blocks belong together in this context"
      },
      {
        "label": "Blocks misplaced",
        "description": "Some building blocks should be in a different context"
      },
      {
        "label": "Should be split",
        "description": "This context is too large and should be divided"
      },
      {
        "label": "Should be merged",
        "description": "This context should be combined with another"
      }
    ]
  }]
</invoke>

### Step 4: Validate Pivotal Events

Present pivotal events as boundary markers with from/to context transitions.

After presenting pivotal events as boundary markers:

<invoke name="AskUserQuestion">
  questions: [{
    "question": "Do these pivotal events correctly mark the boundaries between contexts?",
    "header": "Pivotal Events",
    "multiSelect": false,
    "options": [
      {
        "label": "Events are correct",
        "description": "These events accurately mark phase transitions between contexts"
      },
      {
        "label": "Missing pivotal events",
        "description": "There are boundary-marking events not identified here"
      },
      {
        "label": "Wrong boundaries",
        "description": "Some of these events don't actually mark context transitions"
      }
    ]
  }]
</invoke>

### Step 5: Resolve Ambiguous Groupings

For each ambiguous building block, present trade-offs and ask:

<invoke name="AskUserQuestion">
  questions: [{
    "question": "[Block ID] could belong to [Context A] or [Context B]. Where should it go?",
    "header": "Placement",
    "multiSelect": false,
    "options": [
      {
        "label": "[Context A]",
        "description": "[Rationale for placing in Context A]"
      },
      {
        "label": "[Context B]",
        "description": "[Rationale for placing in Context B]"
      },
      {
        "label": "Duplicate in both",
        "description": "This concept exists in both contexts with different meanings"
      }
    ]
  }]
</invoke>

Document the user's rationale for each decision.

### Step 6: Build Sub-domain Map

Create Mermaid diagram showing Core/Supporting/Generic sub-domains and relationships.

### Step 7: Write Sub-domains Artifact

Create `research/ddd/03-sub-domains.md` with bounded contexts, pivotal events, language shifts, and boundary decisions.

### Step 8: Prompt Next Step

```
Sub-domain map written to `research/ddd/03-sub-domains.md`.

Summary:
- [N] bounded contexts: [N] core, [N] supporting, [N] generic
- [N] pivotal events marking boundaries

Next step: Run `/ddd_strategize` to classify sub-domains and make investment decisions.
```

## Guidelines

1. **Language is the primary signal**: Shared vocabulary = same context
2. **Validate each boundary individually**: Don't present all as done deal
3. **Pivotal events are strongest markers**: Phase transitions indicate boundaries
4. **Don't force symmetry**: Contexts can be vastly different sizes
5. **Preserve building block IDs**: E1, C1, A1, P1, R1 from event catalog
6. **Preliminary classifications only**: Full analysis in `/ddd_strategize`
