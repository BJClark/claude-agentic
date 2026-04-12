---
date: 2026-02-07T16:00:00-08:00
researcher: Claude
git_commit: 1d2546c426663dbb8a6cac39f2392cae8e1e1783
branch: main
repository: claude-agentic
topic: "How are the DDD commands structured and how do they chain together?"
tags: [research, codebase, ddd, commands, agents, workflow]
status: complete
last_updated: 2026-02-07
last_updated_by: Claude
---

# Research: How are the DDD commands structured and how do they chain together?

**Date**: 2026-02-07
**Git Commit**: 1d2546c
**Branch**: main
**Repository**: claude-agentic

## Research Question

How are the DDD commands structured and how do they chain together?

## Summary

The DDD system consists of 8 slash commands and 3 specialist agents that together implement a complete Domain-Driven Design discovery-to-implementation workflow. The commands are structured as a linear artifact chain where each command reads the previous command's output file, performs interactive work with the user, writes a numbered artifact to `research/ddd/`, and then prompts the user to run the next command. An orchestrator command (`/ddd_full`) chains all 7 discovery steps together with confirmation gates between each step.

The commands follow a consistent internal structure: YAML frontmatter with description and model, a prerequisites section naming required input artifacts, numbered process steps (read prerequisites, spawn agent or perform analysis, interactive review with user, write artifact, prompt next step), and guidelines. Three DDD-specific agents (`ddd-event-discoverer`, `ddd-context-analyzer`, `ddd-canvas-builder`) are spawned as sub-agents by steps 2, 3, and 7 respectively to perform the heavy analytical work before the main command presents results interactively.

Key discoveries:
- The artifact chain flows linearly: `01-alignment.md` -> `02-event-catalog.md` -> `03-sub-domains.md` -> `04-strategy.md` -> `05-context-map.md` -> `06-canvases.md` -> `plans/YYYY-MM-DD-ddd-*.md`
- Building block IDs (E1, C1, A1, P1, R1) are assigned in step 2 and explicitly carried through every subsequent artifact
- The final command (`/ddd_plan`) bridges DDD discovery into the existing `/implement_plan` command by producing plans in the exact `/create_plan` template format

## Detailed Findings

### File Organization

**Location**: Three directories linked via symlinks from `.claude/`

The DDD system spans three directories at the repository root, each symlinked into `.claude/` for Claude Code discovery:

| Directory | Symlink | DDD Files |
|-----------|---------|-----------|
| `commands/` | `.claude/commands -> ../commands` | 8 command files (`ddd_align.md` through `ddd_full.md`) |
| `agents/` | `.claude/agents -> ../agents` | 3 agent files (`ddd-event-discoverer.md`, `ddd-context-analyzer.md`, `ddd-canvas-builder.md`) |
| `research/` | (not symlinked) | `ddd-process-research.md` (reference material) |

All DDD command files live in `/Users/willclark/Developer/scidept/claude-agentic/commands/` and all DDD agent files live in `/Users/willclark/Developer/scidept/claude-agentic/agents/`.

### Command Frontmatter Structure

Every DDD command file uses YAML frontmatter with two fields:

```yaml
---
description: "DDD Step N: [Step Name] -- [brief description]"
model: opus
---
```

All 8 DDD commands specify `model: opus`. The 3 agent files use a different frontmatter schema:

```yaml
---
name: ddd-[role-name]
description: [brief description]
tools: Read, Grep, Glob, LS
model: sonnet
---
```

All 3 agents specify `model: sonnet` and are restricted to read-only tools (`Read, Grep, Glob, LS`).

### The 8 DDD Commands

#### Command 1: `/ddd_align` (Step 1: Align & Understand)

**File**: `commands/ddd_align.md:1-158`

**Input**: A PRD file path or conversational description from the user.

**Prerequisites**: None -- this is the entry point.

**Process**: Reads source material, extracts business context (purpose, actors, value propositions, workflows, constraints, revenue model), presents a structured summary for user validation, iterates based on feedback, then writes the artifact.

**Output**: `research/ddd/01-alignment.md` with YAML frontmatter (`ddd_step: 1`, `ddd_step_name: Align & Understand`, `source` field pointing to PRD).

**Next step prompt**: "Run `/ddd_discover` to perform EventStorming"

**Agents used**: None.

#### Command 2: `/ddd_discover` (Step 2: EventStorming)

**File**: `commands/ddd_discover.md:1-193`

**Input**: Reads `research/ddd/01-alignment.md` and the original PRD (from the `source` field in alignment frontmatter).

**Prerequisites**: `research/ddd/01-alignment.md` must exist.

**Process**: Spawns the `ddd-event-discoverer` agent to extract building blocks. Presents results as a chronological event timeline. Walks through each flow interactively asking about triggers, failure paths, and alternative paths. Fills gaps. Builds two Mermaid diagrams (timeline and event flow). Writes the catalog.

**Output**: `research/ddd/02-event-catalog.md` with YAML frontmatter (`ddd_step: 2`, `source: "research/ddd/01-alignment.md"`). Contains tables for Events (E1, E2...), Commands (C1, C2...), Actors (A1, A2...), Policies (P1, P2...), Read Models (R1, R2...), preliminary Aggregates, resolved gaps, and open questions.

**Next step prompt**: "Run `/ddd_decompose` to identify bounded context boundaries"

**Agents used**: `ddd-event-discoverer` (model: sonnet).

#### Command 3: `/ddd_decompose` (Step 3: Decompose)

**File**: `commands/ddd_decompose.md:1-185`

**Input**: Reads `research/ddd/02-event-catalog.md` and `research/ddd/01-alignment.md`.

**Prerequisites**: `research/ddd/02-event-catalog.md` must exist.

**Process**: Spawns the `ddd-context-analyzer` agent. Presents proposed boundaries with building block assignments and vocabulary clusters. Validates pivotal events as boundary markers. Resolves ambiguous groupings interactively. Builds a sub-domain map Mermaid diagram.

**Output**: `research/ddd/03-sub-domains.md` with YAML frontmatter (`ddd_step: 3`, `source: "research/ddd/02-event-catalog.md"`). Contains bounded context definitions (classification, building blocks, vocabulary, boundary signals), pivotal events table, language shifts table, and boundary decisions.

**Next step prompt**: "Run `/ddd_strategize` to classify sub-domains"

**Agents used**: `ddd-context-analyzer` (model: sonnet).

#### Command 4: `/ddd_strategize` (Step 4: Strategize)

**File**: `commands/ddd_strategize.md:1-199`

**Input**: Reads `research/ddd/03-sub-domains.md` and `research/ddd/01-alignment.md`.

**Prerequisites**: `research/ddd/03-sub-domains.md` must exist.

**Process**: Explains the Core Domain Chart framework (business differentiation vs. model complexity). Classifies each sub-domain interactively by asking the user to rate differentiation and complexity. Determines architecture strategy per classification (CQRS/ES for core+complex, rich domain model for core+simple, CRUD or third-party for generic). Builds a Mermaid quadrant chart. Establishes implementation priority order.

**Output**: `research/ddd/04-strategy.md` with YAML frontmatter (`ddd_step: 4`, `source: "research/ddd/03-sub-domains.md"`). Contains the Core Domain Chart, per-context classifications with architecture strategy and investment level, architecture decisions table, and implementation priority.

**Next step prompt**: "Run `/ddd_connect` to map relationships between bounded contexts"

**Agents used**: None.

#### Command 5: `/ddd_connect` (Step 5: Context Mapping)

**File**: `commands/ddd_connect.md:1-199`

**Input**: Reads `research/ddd/04-strategy.md`, `research/ddd/03-sub-domains.md`, and `research/ddd/02-event-catalog.md`.

**Prerequisites**: `research/ddd/04-strategy.md` must exist.

**Process**: Presents context mapping patterns (Partnership, Customer-Supplier, Conformist, ACL, OHS, Published Language, Shared Kernel, Separate Ways). Identifies all context pairs from shared events. Defines each relationship interactively. Documents data flow (events, format, translation). Builds a context map Mermaid diagram.

**Output**: `research/ddd/05-context-map.md` with YAML frontmatter (`ddd_step: 5`, `source: "research/ddd/04-strategy.md"`). Contains the context map diagram, relationship details, integration summary table, and ACL specifications.

**Next step prompt**: "Run `/ddd_define` to build Bounded Context Canvases and Aggregate Design Canvases"

**Agents used**: None.

#### Command 6: `/ddd_define` (Step 7: Define Canvases)

**File**: `commands/ddd_define.md:1-216`

**Input**: Reads ALL five prior artifacts (`01-alignment.md` through `05-context-map.md`).

**Prerequisites**: All five prior artifacts must exist.

**Process**: Determines canvas scope based on strategic classification (core gets full canvases, supporting gets BC canvas + abbreviated aggregate canvas, generic gets abbreviated BC canvas only). Spawns the `ddd-canvas-builder` agent. Presents each Bounded Context Canvas and Aggregate Design Canvas one at a time for interactive review. Generates Mermaid `stateDiagram-v2` for aggregate lifecycles.

**Output**: `research/ddd/06-canvases.md` with YAML frontmatter (`ddd_step: 7`, `source: "research/ddd/05-context-map.md"`). Contains Bounded Context Canvases (ubiquitous language, business rules, inbound/outbound communication) and Aggregate Design Canvases (invariants, commands, events, state lifecycle diagrams, correctness criteria). Gaps are marked as `[INSUFFICIENT DATA]`.

**Next step prompt**: "Run `/ddd_plan` to convert all DDD artifacts into implementation plans"

**Agents used**: `ddd-canvas-builder` (model: sonnet).

**Note on numbering**: The command description says "DDD Step 7" and the frontmatter says `ddd_step: 7`, but it is the 6th command in the chain. The output file is numbered `06-canvases.md`. The DDD Starter Modelling Process has an "Organize" step 6 that is skipped in this implementation (relevant only to team topology, not solo/small-team use).

#### Command 7: `/ddd_plan` (Step 8: Plan)

**File**: `commands/ddd_plan.md:1-307`

**Input**: Reads ALL six DDD artifacts (`01-alignment.md` through `06-canvases.md`).

**Prerequisites**: All six DDD artifacts must exist.

**Process**: Determines implementation sequence from `04-strategy.md` (core first, then supporting, then generic). Maps each DDD artifact to specific plan sections. Presents phased plan strategy per context for confirmation. Writes one implementation plan per bounded context.

**Output**: `plans/YYYY-MM-DD-ddd-[context-name].md` files -- one per bounded context. Plans use the exact `/create_plan` template format with YAML frontmatter including `bounded_context`, `classification`, `architecture`, and `ddd_artifacts` fields. Each plan has 4 phases: Domain Model, Application Layer, Infrastructure, and Integration, plus a Testing Strategy section.

**Next step prompt**: "Start implementation with `/implement_plan plans/YYYY-MM-DD-ddd-[first-context].md`"

**Agents used**: None.

#### Command 8: `/ddd_full` (Orchestrator)

**File**: `commands/ddd_full.md:1-118`

**Input**: Any parameters passed to it are forwarded to `/ddd_align`.

**Prerequisites**: None -- orchestrates from the beginning.

**Process**: Calls each of the 7 individual DDD commands in sequence using `SlashCommand()`. After each step writes its artifact, presents a confirmation gate:

```
Step N complete: [Artifact] written to [path]
Ready to proceed to Step N+1 ([Step Name])?
```

Waits for user confirmation before continuing to the next step. The user can stop at any step and resume later.

**Output**: All artifacts from steps 1-7, plus a final summary table showing all artifacts and their statuses.

**Agents used**: None directly (delegates to individual commands which spawn agents).

### The 3 DDD Agents

#### Agent: `ddd-event-discoverer`

**File**: `agents/ddd-event-discoverer.md:1-84`
**Used by**: `/ddd_discover` (Step 2)
**Model**: sonnet
**Tools**: Read, Grep, Glob, LS (read-only)

**Purpose**: Extracts domain building blocks from requirements text. Performs five sequential passes: events (past tense), commands (imperative), actors, policies (when/then), and read models. Assigns sequential IDs (E1, C1, A1, P1, R1). Performs gap analysis flagging commands without events, events without triggers, and actors without commands.

**Self-description**: "You are a domain archaeologist, not a domain designer."

#### Agent: `ddd-context-analyzer`

**File**: `agents/ddd-context-analyzer.md:1-91`
**Used by**: `/ddd_decompose` (Step 3)
**Model**: sonnet
**Tools**: Read, Grep, Glob, LS (read-only)

**Purpose**: Identifies bounded context boundaries from language patterns. Builds a vocabulary index, identifies semantic clusters, finds boundary signals (pivotal events, language shifts, actor changes), names clusters in domain language, classifies as core/supporting/generic, and maps shared events as integration points.

**Self-description**: "You are a linguistic cartographer, not an architect."

#### Agent: `ddd-canvas-builder`

**File**: `agents/ddd-canvas-builder.md:1-135`
**Used by**: `/ddd_define` (Step 7/Command 6)
**Model**: sonnet
**Tools**: Read, Grep, Glob, LS (read-only)

**Purpose**: Synthesizes all five prior DDD artifacts into formal Bounded Context Canvases (v5 format) and Aggregate Design Canvases. Generates Mermaid `stateDiagram-v2` diagrams for aggregate lifecycles. Marks `[INSUFFICIENT DATA]` for any field that cannot be filled from existing artifacts.

**Self-description**: "You are a canvas assembler, not a domain modeler."

### Artifact Chain and Data Flow

The commands produce a linear chain of numbered markdown files in `research/ddd/`:

```
PRD / conversation (user input)
  |
  v
/ddd_align
  |  writes: research/ddd/01-alignment.md
  |  (business context, actors, value propositions, workflows, constraints)
  v
/ddd_discover  [spawns: ddd-event-discoverer agent]
  |  reads:  01-alignment.md + original PRD
  |  writes: research/ddd/02-event-catalog.md
  |  (events E1..En, commands C1..Cn, actors A1..An, policies P1..Pn, read models R1..Rn)
  v
/ddd_decompose  [spawns: ddd-context-analyzer agent]
  |  reads:  02-event-catalog.md + 01-alignment.md
  |  writes: research/ddd/03-sub-domains.md
  |  (bounded contexts, building block assignments, pivotal events, language shifts)
  v
/ddd_strategize
  |  reads:  03-sub-domains.md + 01-alignment.md
  |  writes: research/ddd/04-strategy.md
  |  (core domain chart, classification, architecture strategy, implementation priority)
  v
/ddd_connect
  |  reads:  04-strategy.md + 03-sub-domains.md + 02-event-catalog.md
  |  writes: research/ddd/05-context-map.md
  |  (relationship patterns, data flow, ACL specifications)
  v
/ddd_define  [spawns: ddd-canvas-builder agent]
  |  reads:  01 through 05 (all five prior artifacts)
  |  writes: research/ddd/06-canvases.md
  |  (bounded context canvases, aggregate design canvases, state diagrams)
  v
/ddd_plan
  |  reads:  01 through 06 (all six DDD artifacts)
  |  writes: plans/YYYY-MM-DD-ddd-[context-name].md (one per bounded context)
  |  (implementation plans compatible with /implement_plan)
  v
/implement_plan  (separate command, not part of DDD system)
```

### How Commands Read Prior Artifacts

Each command explicitly states its prerequisites and reads them in its "Step 1: Read Prerequisites" section. The `source` field in each artifact's YAML frontmatter points back to the input artifact, creating a traceable provenance chain:

| Artifact | `source` frontmatter field |
|----------|---------------------------|
| `01-alignment.md` | Path to PRD or `"conversational"` |
| `02-event-catalog.md` | `"research/ddd/01-alignment.md"` |
| `03-sub-domains.md` | `"research/ddd/02-event-catalog.md"` |
| `04-strategy.md` | `"research/ddd/03-sub-domains.md"` |
| `05-context-map.md` | `"research/ddd/04-strategy.md"` |
| `06-canvases.md` | `"research/ddd/05-context-map.md"` |

Later commands read more artifacts than just their immediate predecessor. `/ddd_connect` (step 5) reads three artifacts (02, 03, 04). `/ddd_define` (step 7) reads all five prior artifacts. `/ddd_plan` (step 8) reads all six.

### Building Block ID Continuity

The ID scheme (`E1`, `C1`, `A1`, `P1`, `R1`) is established in step 2 by the `ddd-event-discoverer` agent and carried through every subsequent artifact. Five of the eight commands explicitly state in their guidelines: "Preserve building block IDs." The IDs appear in:

- Event catalog tables (step 2)
- Bounded context building block assignments (step 3)
- Strategy classification references (step 4)
- Context map shared event references (step 5)
- Canvas inbound/outbound communication and aggregate command/event tables (step 7)
- Implementation plan phase content mapping commands to events (step 8)

### Interactivity Pattern

Every DDD command follows the same interactivity pattern:

1. Read prerequisites silently
2. Perform analysis (optionally via agent)
3. Present results to user in structured format
4. Ask specific validation questions
5. Iterate based on user feedback
6. Write artifact only after user confirmation
7. Prompt next step

Commands 2, 3, 4, and 5 are the most interactive, walking through individual elements one at a time and asking targeted questions. Commands 1 and 6 present broader summaries for validation. Command 7 presents the overall plan strategy per context.

### The `ddd_full` Orchestration Model

The `/ddd_full` command acts as a state machine that:
1. Calls each individual command via `SlashCommand()`
2. Each command runs its full interactive process
3. After each command writes its artifact, `/ddd_full` presents a confirmation gate
4. The user must confirm to proceed to the next step
5. The user can stop at any step; individual commands can be re-run independently

This means `/ddd_full` does not bypass the interactivity of individual commands. The full workflow is intended to be a multi-session process.

### Bridge to Implementation

The `/ddd_plan` command (step 8) bridges the DDD discovery workflow into the existing plan/implementation system. It:

1. Reads all six DDD artifacts
2. Uses a mapping table that connects each DDD artifact type to specific plan sections (e.g., alignment -> Overview; event catalog -> Domain model phase; context map -> Integration phases)
3. Produces plans in the exact format expected by `/implement_plan` (defined in `commands/implement_plan.md`)
4. The plans include YAML frontmatter with DDD-specific fields (`bounded_context`, `classification`, `architecture`, `ddd_artifacts`)
5. One plan is produced per bounded context, ordered by strategic priority (core first)

### Reference Material

**File**: `research/ddd-process-research.md:1-124`

This file provides background research on the DDD Starter Modelling Process, EventStorming methodology, CQRS/ES design principles, and common anti-patterns. It is not referenced by any command or agent directly but provides the theoretical foundation the command system was built upon. Key concepts from this document that appear in the commands include: the 8-step DDD Starter Modelling Process, Alberto Brandolini's EventStorming color code, Vaughn Vernon's four rules for aggregate design, the Core Domain Chart classification framework, and context mapping patterns.

## Code References

Quick reference index of key files:

- `commands/ddd_align.md` - Step 1: Entry point, business alignment from PRD
- `commands/ddd_discover.md` - Step 2: EventStorming, spawns ddd-event-discoverer
- `commands/ddd_decompose.md` - Step 3: Bounded context boundaries, spawns ddd-context-analyzer
- `commands/ddd_strategize.md` - Step 4: Core Domain Chart classification
- `commands/ddd_connect.md` - Step 5: Context mapping patterns
- `commands/ddd_define.md` - Step 7: Canvases, spawns ddd-canvas-builder
- `commands/ddd_plan.md` - Step 8: Implementation plans for /implement_plan
- `commands/ddd_full.md` - Orchestrator, chains all 7 steps
- `agents/ddd-event-discoverer.md` - Extracts events, commands, actors, policies, read models
- `agents/ddd-context-analyzer.md` - Identifies language clusters and context boundaries
- `agents/ddd-canvas-builder.md` - Synthesizes canvases from prior artifacts
- `commands/implement_plan.md` - Downstream consumer of /ddd_plan output
- `research/ddd-process-research.md` - Background research document

## Architecture Documentation

### Patterns Used

- **Linear Artifact Chain**: Each command produces a numbered artifact that becomes the input for the next command. The `source` field in YAML frontmatter creates explicit provenance.
- **Agent Delegation**: Three commands (steps 2, 3, 7) delegate heavy analysis to specialized agents running on a smaller model (sonnet) with read-only tools, then take over for interactive review on the main model (opus).
- **Confirmation Gates**: The `/ddd_full` orchestrator pauses between each step for user confirmation, allowing the user to stop, adjust, or re-run individual steps.
- **ID Continuity**: A global ID scheme (E1, C1, A1, P1, R1) assigned once in step 2 is carried through all subsequent artifacts unchanged.
- **Progressive Widening Reads**: Earlier commands read 1-2 prerequisites. Later commands read progressively more artifacts (step 5 reads 3, step 7 reads 5, step 8 reads 6).
- **Bridge Pattern**: The final DDD command produces output in the exact format of a different command system (`/create_plan` format), enabling the DDD workflow to feed into the existing `/implement_plan` command.

### Data Flow

```
User Input (PRD)
  -> /ddd_align -> 01-alignment.md
    -> /ddd_discover [agent: ddd-event-discoverer] -> 02-event-catalog.md
      -> /ddd_decompose [agent: ddd-context-analyzer] -> 03-sub-domains.md
        -> /ddd_strategize -> 04-strategy.md
          -> /ddd_connect -> 05-context-map.md
            -> /ddd_define [agent: ddd-canvas-builder] -> 06-canvases.md
              -> /ddd_plan -> plans/YYYY-MM-DD-ddd-*.md
                -> /implement_plan (external)
```

## Open Questions

1. The step numbering skips step 6 (Organize from the DDD Starter Modelling Process). The `ddd_define` command is labeled as "Step 7" in its frontmatter but produces artifact file `06-canvases.md`. The rationale for this skip is not documented in the commands themselves but the research document mentions team topology concerns are not relevant for solo/small teams.
2. The `/ddd_full` command references `SlashCommand()` as the mechanism for calling sub-commands, but no implementation of this function is visible in the repository. This is presumably a Claude Code built-in capability.
3. No existing `research/ddd/` directory with sample artifacts was found, indicating the DDD workflow has not yet been run to completion in this repository.
