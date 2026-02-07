---
name: ddd-define
description: "DDD Step 7: Define bounded context canvases and aggregate design canvases"
model: opus
context: fork
allowed-tools: Read, Grep, Glob, Write, Edit, AskUserQuestion, Task
argument-hint: [domain-name]
---

# DDD Step 7: Define (Canvases)

Ultrathink about aggregate design, invariant enforcement, and state lifecycle transitions. Consider consistency boundaries, concurrency implications, and the correctness criteria that matter most.

Build formal Bounded Context Canvases and Aggregate Design Canvases for each context.

**Input**: $ARGUMENTS

## Current Context

- **Branch**: !`git branch --show-current`
- **Last Commit**: !`git log -1 --oneline`

## Prerequisites

ALL prior artifacts must exist:
- `research/ddd/01-alignment.md`
- `research/ddd/02-event-catalog.md`
- `research/ddd/03-sub-domains.md`
- `research/ddd/04-strategy.md`
- `research/ddd/05-context-map.md`

## Process Steps

### Step 1: Read All Prerequisites

Read ALL five prior artifacts completely. Every canvas field draws from prior discovery.

### Step 2: Determine Canvas Scope

Based on strategic classification:
- **Core contexts**: Full BC Canvas + Aggregate Design Canvas per aggregate
- **Supporting contexts**: Full BC Canvas + abbreviated Aggregate Canvas
- **Generic contexts**: Abbreviated BC Canvas only

Present the plan and ask if ready to begin.

### Step 3: Build Canvases Per Context

For each context (core first):

**A. Spawn `ddd-canvas-builder` agent** with all artifact paths.

**B. Present Bounded Context Canvas** with: Name, Purpose, Classification, Architecture, Ubiquitous Language, Business Rules, Inbound/Outbound Communication. Ask for review.

**C. For core/supporting, present Aggregate Design Canvas** with: Enforced Invariants, Handled Commands, Created Events, State Lifecycle (Mermaid stateDiagram-v2), Correctness Criteria. Ask for review.

Wait for confirmation on each canvas before proceeding.

### Step 4: Write Canvases Artifact

Create `research/ddd/06-canvases.md` with all canvases, data gaps summary, and decisions made.

### Step 5: Prompt Next Step

```
Canvases written to `research/ddd/06-canvases.md`.

Summary:
- [N] Bounded Context Canvases
- [N] Aggregate Design Canvases
- [N] state lifecycle diagrams
- [N] data gaps flagged

Next step: Run `/ddd_plan` to convert DDD artifacts into implementation plans.
```

## Guidelines

1. **One canvas at a time**: Present and validate individually
2. **Core contexts first**: Most attention and detail
3. **`[INSUFFICIENT DATA]` over guessing**: Never invent invariants
4. **Valid Mermaid state diagrams**: Use `stateDiagram-v2` with `[*]`
5. **Cross-reference context map**: Inbound/outbound must align with relationships
6. **Preserve building block IDs**: E1, C1, A1, P1, R1 from catalog
7. **Correctness criteria are testable**: Concrete assertions, not vague
