---
name: ddd-discover
description: "DDD Step 2: EventStorming — discover domain events, commands, actors, and policies"
model: opus
context: fork
allowed-tools: Read, Grep, Glob, Write, Edit, AskUserQuestion, Task
argument-hint: [prd-file-path]
---

# DDD Step 2: Discover (EventStorming)

Ultrathink about domain events and their causal relationships before starting. Consider temporal ordering, failure modes, and implicit business rules.

Perform structured EventStorming to extract domain building blocks from your requirements.

**Input**: $ARGUMENTS

## Current Context

- **Branch**: !`git branch --show-current`
- **Last Commit**: !`git log -1 --oneline`

## Prerequisites

- `research/ddd/01-alignment.md` must exist (run `/ddd-align` first)

## Process Steps

### Step 1: Read Prerequisites

1. Read `research/ddd/01-alignment.md` completely
2. Read the original PRD (from the `source` field in alignment frontmatter)

### Step 2: Spawn Event Discovery Agent

Spawn a `ddd-event-discoverer` agent:
- Provide alignment doc path and original PRD path
- Instruct to extract all building blocks with IDs
- Wait for results

### Step 3: Interactive Event Timeline Review

Present discovered building blocks chronologically:

```
## EventStorming Results

### Event Timeline
1. **E1: [Event Name]** — [description]
   - Triggered by: C1 ([Command]) from A1 ([Actor])
2. **E2: [Event Name]** — [description]
   - Triggered by: P1 ([Policy]) reacting to E1

### Gaps Found
- [List gaps]

---

Let's walk through this timeline together.
```

Get user validation using AskUserQuestion:
- **Timeline review**: Does the event timeline accurately represent the domain process?
- Options should cover: timeline accurate, events missing, order wrong, needs discussion

Tailor options based on the specific events and flows discovered.

For each flow, present the trigger->command->event chain and get validation using AskUserQuestion:
- **Flow review**: Are triggers, failure paths, and alternatives correct for this flow?
- Options should cover: flow correct, missing failure paths, wrong triggers

Tailor options to the specific flow being reviewed.

### Step 4: Fill Gaps Interactively

For each gap found, present it clearly and ask:

For each gap, present it clearly and get a decision using AskUserQuestion:
- **Gap resolution**: How should we handle [this specific gap]?
- Options should include: user will fill it in, out of scope, needs more research

Tailor options based on the nature of each gap.

Add error/failure events for any gaps resolved.

### Step 5: Build Mermaid Diagrams

Create timeline and event flow diagrams showing actor->command->aggregate->event->policy chains.

### Step 6: Write Event Catalog Artifact

Create `research/ddd/02-event-catalog.md` with tables for Events, Commands, Actors, Policies, Read Models, and preliminary Aggregates.

### Step 7: Prompt Next Step

```
Event catalog written to `research/ddd/02-event-catalog.md`.

Summary:
- [N] events, [N] commands, [N] actors, [N] policies, [N] read models
- [N] gaps resolved, [N] open questions remaining

Next step: Run `/ddd-decompose` to identify bounded context boundaries.
```

## Guidelines

1. **Walk through events chronologically**: Don't dump the whole catalog at once
2. **Always ask about failure paths**: Every command can fail
3. **Maintain ID continuity**: IDs (E1, C1) carry through ALL subsequent artifacts
4. **Past tense for events, imperative for commands**: Enforce grammar consistency
5. **Preliminary aggregates only**: Don't commit — decomposition comes next
6. **Mermaid diagrams must be valid**: Test syntax before writing
