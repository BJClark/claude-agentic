---
name: ddd-plan
description: "DDD Step 8: Convert DDD artifacts into implementation plans for /implement-plan"
model: opus
context: fork
allowed-tools: Read, Grep, Glob, Write, Edit, AskUserQuestion
argument-hint: [domain-name]
---

# DDD Step 8: Plan (DDD to Implementation)

Ultrathink about the translation from domain model to implementation. Consider how aggregates map to code structures, how events flow through infrastructure, and how to phase work for incremental delivery.

Convert all DDD artifacts into concrete implementation plans compatible with `/implement-plan`.

**Input**: $ARGUMENTS

## Current Context

- **Branch**: !`git branch --show-current`
- **Last Commit**: !`git log -1 --oneline`

## Prerequisites

ALL DDD artifacts must exist:
- `research/ddd/01-alignment.md`
- `research/ddd/02-event-catalog.md`
- `research/ddd/03-sub-domains.md`
- `research/ddd/04-strategy.md`
- `research/ddd/05-context-map.md`
- `research/ddd/06-canvases.md`

## Process Steps

### Step 1: Read All Artifacts

Read ALL six DDD artifacts completely.

### Step 2: Determine Implementation Sequence

From `04-strategy.md`:
1. Core contexts first — highest business value
2. Supporting contexts that enable core
3. Generic contexts last

Present the implementation sequence table, then get confirmation using AskUserQuestion:
- **Sequence check**: Does this implementation sequence make sense?
- Options should cover: sequence correct, reorder contexts, skip some contexts

Tailor options based on the specific contexts and their strategic priority.

### Step 3: Map DDD Artifacts to Plan Sections

| DDD Artifact | Plan Section |
|-------------|-------------|
| Alignment | Overview, Desired End State, NOT Doing |
| Event Catalog | Domain model phase content |
| Sub-domains | Implementation scope per plan |
| Strategy | Architecture decisions |
| Context Map | Integration phases, ACL implementation |
| BC Canvas | Domain model details, validation |
| Aggregate Canvas | Aggregate implementation, state machines, tests |

### Step 4: Present Plan Strategy Per Context

For each context, present proposed phases, then get validation using AskUserQuestion:
- **Phase review**: Does this phase strategy for [Context Name] look right?
- Options should cover: phases look good, adjust phases, simplify

Tailor options based on the specific context's architecture classification.

### Step 5: Write Implementation Plans

One plan per bounded context at `plans/YYYY-MM-DD-ddd-[context-name].md` using the standard plan template with phases, success criteria (automated + manual), and DDD artifact references.

After writing all plans, get final confirmation using AskUserQuestion:
- **Final review**: Implementation plans written for all contexts. Ready to finalize?
- Options should cover: plans look good, revise specific plan, review all plans first

Tailor options based on what was actually written.

### Step 6: Present Summary

```
## Implementation Plans Created

| Plan | Context | Architecture | Phases |
|------|---------|-------------|--------|

Implementation order:
1. [First] -> `/implement-plan plans/YYYY-MM-DD-ddd-[name].md`
2. [Second] -> after first is complete

Each plan is compatible with `/implement-plan`.
```

## Guidelines

1. **One plan per bounded context**: Don't combine contexts
2. **Standard plan template format**: Compatible with `/implement-plan`
3. **Architecture matches strategy**: CQRS/ES only where classified
4. **Phases are incremental and testable**: Each has automated + manual verification
5. **Trace to DDD artifacts**: Every item references its source (E1, C1, canvas)
6. **Core contexts get detailed plans**: Supporting/generic more abbreviated
7. **Create `plans/` directory** if it doesn't exist
