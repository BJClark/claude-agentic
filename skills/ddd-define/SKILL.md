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

- **Branch**: !`git branch --show-current 2>/dev/null || echo "N/A"`
- **Last Commit**: !`git log -1 --oneline 2>/dev/null || echo "N/A"`

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

Present the canvas scope plan, then get confirmation using AskUserQuestion:
- **Scope check**: Is the canvas plan based on strategic classification correct?
- Options should cover: ready to begin, adjust scope, focus on specific context

Tailor options based on what contexts exist and their classifications.

### Step 3: Build Canvases Per Context

For each context (core first):

**A. Spawn `ddd-canvas-builder` agent** with all artifact paths.

**B. Present Bounded Context Canvas** with: Name, Purpose, Classification, Architecture, Ubiquitous Language, Business Rules, Inbound/Outbound Communication.

After presenting the Bounded Context Canvas, get validation using AskUserQuestion:
- **BC Canvas review**: Does this Bounded Context Canvas for [Context Name] look correct?
- Options should cover: canvas correct, needs corrections, missing information

Tailor options based on the specific canvas fields presented.

**C. For core/supporting, present Aggregate Design Canvas** with: Enforced Invariants, Handled Commands, Created Events, State Lifecycle (Mermaid stateDiagram-v2), Correctness Criteria.

After presenting the Aggregate Design Canvas, get validation using AskUserQuestion:
- **Aggregate review**: Does this Aggregate Design Canvas for [Aggregate Name] look correct?
- Options should cover: canvas correct, wrong invariants, state lifecycle issues, missing information

Tailor options based on the specific aggregate being reviewed. Wait for confirmation on each canvas before proceeding to the next context.

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
