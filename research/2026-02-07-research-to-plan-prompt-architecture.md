---
date: 2026-02-07T13:00:00-08:00
researcher: Claude
git_commit: e29a2b3dc7f9cfbfa6eda0eba078c7efbd9b4512
branch: main
repository: claude-agentic
topic: "Prompt Architecture for Research-to-Plan Workflows with Focus on Zero-to-One"
tags: [research, prompts, planning, architecture, zero-to-one]
status: complete
last_updated: 2026-02-07
last_updated_by: Claude
---

# Research: Prompt Architecture for Research-to-Plan Workflows

**Date**: 2026-02-07
**Git Commit**: e29a2b3
**Branch**: main
**Repository**: claude-agentic

## Research Question

How are the prompts around research and planning structured? What are the "requirements" for a prompt to research a codebase through a specific "lens" and then turn that research into an implementation plan? Focus on "zero to one" workflows for starting new projects and features.

## Summary

The codebase implements a layered prompt architecture with three distinct tiers: **agents** (specialized read-only workers), **commands** (orchestrating workflows), and **composite commands** (chaining workflows together). Research and planning are treated as separate, sequential phases connected by persistent artifacts (markdown documents with YAML frontmatter). The system is designed around a "document first, then act" philosophy where each phase produces a self-contained artifact that serves as the input for the next phase.

## Detailed Findings

### 1. The Three-Tier Prompt Architecture

The system is organized into three tiers that compose together:

#### Tier 1: Agents (Specialized Workers)
Located in `agents/`. These are single-purpose, read-only sub-agents with constrained toolsets. Each agent has a specific "lens" through which it views the codebase:

| Agent | Lens | Tools | Purpose |
|-------|------|-------|---------|
| `codebase-locator` | WHERE | Grep, Glob, LS | Find file locations without reading contents |
| `codebase-analyzer` | HOW | Read, Grep, Glob, LS | Understand implementation details with file:line references |
| `codebase-pattern-finder` | WHAT EXISTS | Grep, Glob, Read, LS | Find similar implementations as templates |
| `thoughts-locator` | WHERE (docs) | Grep, Glob, LS | Find relevant documents in thoughts/ directory |
| `thoughts-analyzer` | INSIGHTS | Read, Grep, Glob, LS | Extract high-value, actionable insights from documents |
| `web-search-researcher` | EXTERNAL | WebSearch, WebFetch, TodoWrite, Read, Grep, Glob, LS | Research external information |

**Critical constraint shared by all agents**: Every agent prompt includes a "CRITICAL: Document What Exists" section that explicitly forbids suggesting improvements, performing root cause analysis, proposing enhancements, or critiquing implementation. They are "documentarians, not critics or consultants."

#### Tier 2: Commands (Orchestrating Workflows)
Located in `commands/`. These are multi-step interactive workflows that spawn and coordinate Tier 1 agents. The key commands in the research-to-plan pipeline are:

- `research_codebase.md` - Orchestrates research through parallel agents
- `create_plan.md` - Orchestrates plan creation through interactive research and iteration
- `iterate_plan.md` - Updates existing plans based on feedback
- `implement_plan.md` - Executes plans phase-by-phase
- `validate_plan.md` - Verifies implementation against plan

#### Tier 3: Composite Commands (Chaining Workflows)
These chain Tier 2 commands together into end-to-end workflows:

- `oneshot.md` - Chains: ralph_research -> launch new session with oneshot_plan
- `oneshot_plan.md` - Chains: ralph_plan -> ralph_impl
- `ralph_research.md` - Research with Linear ticket integration
- `ralph_plan.md` - Planning with Linear ticket integration
- `ralph_impl.md` - Implementation with worktree setup
- `founder_mode.md` - Post-implementation ticketing and PR creation

### 2. Requirements for a Research Prompt (Viewing Through a Lens)

Based on analyzing all six agent prompts, every research prompt that views the codebase through a specific "lens" shares these structural requirements:

#### A. Frontmatter Metadata
```yaml
---
name: agent-name                    # kebab-case identifier
description: One-line description   # used by the orchestrator to decide when to spawn
tools: Tool1, Tool2                 # constrained toolset (never more than needed)
model: sonnet                       # cost/capability tradeoff (sonnet for agents, opus for orchestrators)
---
```

#### B. Identity Statement
A single opening sentence that declares the agent's specialization and its specific lens:
- "Specialist at finding WHERE code lives" (codebase-locator)
- "Specialist at understanding HOW code works" (codebase-analyzer)
- "Specialist at finding code patterns and examples" (codebase-pattern-finder)
- "Specialist at finding documents in thoughts/" (thoughts-locator)
- "Specialist at extracting HIGH-VALUE insights" (thoughts-analyzer)
- "Expert web research specialist" (web-search-researcher)

#### C. Behavioral Constraints (The "DO NOT" Block)
Every agent has an explicit constraint block that prevents scope creep:
```
## CRITICAL: Document What Exists
- DO NOT suggest improvements or changes unless explicitly asked
- DO NOT perform root cause analysis unless explicitly asked
- DO NOT propose enhancements, critique implementation, or identify problems
- ONLY describe what exists, where it exists, and how components interact
```

This is the single most important architectural pattern: **agents are observers, never advisors**.

#### D. Core Responsibilities (Numbered List)
3-4 specific responsibilities that define the agent's scope. Each responsibility maps to a verb:
- **Find** (locator agents)
- **Analyze/Trace** (analyzer agents)
- **Extract/Filter** (insight agents)
- **Search/Synthesize** (web agents)

#### E. Strategy Section
A prescribed approach for how to accomplish the task, broken into numbered steps:
1. What to do first (entry point strategy)
2. How to search/analyze (technique)
3. How to go deeper (follow-up strategy)

#### F. Output Format (Structured Template)
Every agent specifies an exact output format with markdown structure. This is critical because the orchestrator (command) needs to parse and synthesize these outputs. The format always includes:
- Section headers matching the agent's responsibilities
- File paths with line numbers (`file.ext:line`)
- Categorized/grouped results
- Summary counts or assessments

#### G. Guidelines (Closing Rules)
A bulleted list of do/don't rules that reinforces the lens:
- codebase-locator: "Don't read file contents" (stay in its lane)
- codebase-analyzer: "Always include file:line references" (precision)
- codebase-pattern-finder: "Show working code, not just snippets" (completeness)
- thoughts-analyzer: "Be skeptical - not everything written is valuable" (quality filter)

#### H. Identity Reinforcement (Closing Statement)
A final sentence that reinforces the agent's role metaphor:
- "You are a documentarian, not a critic or consultant"
- "You are a pattern librarian"
- "You are a curator of insights, not a document summarizer"

### 3. Requirements for Turning Research into an Implementation Plan

The `create_plan.md` command defines a 5-step interactive process for converting research into a plan:

#### Step 1: Context Gathering & Initial Analysis
- Read all mentioned files FULLY (no limit/offset)
- Spawn parallel research agents (locator, analyzer, pattern-finder, thoughts-locator)
- Read all identified files into main context
- Cross-reference requirements with actual code
- Present "informed understanding" with questions research couldn't answer

#### Step 2: Research & Discovery (Interactive)
- Handle user corrections by spawning new research tasks
- Present design options with pros/cons
- Surface open questions that need human judgment
- Ask: "Which approach aligns best with your vision?"

#### Step 3: Plan Structure Development
- Propose phase outline before writing details
- Get feedback on structure before filling in

#### Step 4: Detailed Plan Writing
Uses a specific template with these required sections:

```
# [Feature/Task Name] Implementation Plan
## Overview
## Current State Analysis
## Desired End State
## What We're NOT Doing
## Implementation Approach
## Phase N: [Descriptive Name]
  ### Overview
  ### Changes Required (with file paths and code)
  ### Success Criteria
    #### Automated Verification (runnable commands)
    #### Manual Verification (human-checked items)
## Testing Strategy
## Performance Considerations
## Migration Notes
## References
```

#### Step 5: Review & Iteration
- Present draft location
- Iterate until user is satisfied
- "No Open Questions in Final Plan" - must be fully actionable

### 4. The Zero-to-One Workflow

The codebase defines several paths for zero-to-one work. Here's how they compose:

#### Path A: Ad-Hoc Research-to-Plan (No Ticket System)
```
/research_codebase → research/YYYY-MM-DD-description.md
                            ↓
/create_plan       → plans/YYYY-MM-DD-description.md
                            ↓
/implement_plan    → code changes (phase-by-phase)
                            ↓
/validate_plan     → validation report
                            ↓
/commit → /describe_pr → PR
```

#### Path B: Ticket-Driven (Linear Integration)
```
/ralph_research    → thoughts/shared/research/YYYY-MM-DD-ENG-XXXX-desc.md
  (ticket: "research needed" → "research in progress" → "research in review")
                            ↓
/ralph_plan        → thoughts/shared/plans/YYYY-MM-DD-ENG-XXXX-desc.md
  (ticket: "ready for spec" → "plan in progress" → "plan in review")
                            ↓
/ralph_impl        → launches new session with worktree
  (ticket: "ready for dev" → "in dev")
  (executes /implement_plan → /commit → /describe_pr in worktree)
```

#### Path C: Automated End-to-End (Oneshot)
```
/oneshot ENG-XXXX  → /ralph_research → launches /oneshot_plan in new session
                                         ↓
/oneshot_plan      → /ralph_plan → /ralph_impl (all in sequence)
```

#### Path D: Experimental/Founder Mode (Post-Hoc)
```
(Write code first, commit)
                            ↓
/founder_mode      → Create Linear ticket retroactively
                   → Create branch, cherry-pick, push
                   → gh pr create
                   → /describe_pr
```

### 5. Common Patterns for New Features

The `create_plan.md` documents three common patterns for zero-to-one work:

1. **Database Changes**: Schema/migration → Store methods → Business logic → API → Clients
2. **New Features**: Research existing patterns → Data model → Backend logic → API endpoints → UI
3. **Refactoring**: Document current behavior → Plan incremental changes → Maintain backwards compatibility → Migration strategy

### 6. The Artifact Chain

Every workflow produces persistent markdown artifacts that form a chain:

```
Ticket (input)
  → Research Document (research/YYYY-MM-DD-description.md)
    → Implementation Plan (plans/YYYY-MM-DD-description.md)
      → Handoff Document (handoffs/ENG-XXXX/YYYY-MM-DD_HH-MM-SS.md)
        → PR Description (prs/{number}_description.md)
```

Each artifact has YAML frontmatter with:
- `date`, `git_commit`, `branch`, `repository` (temporal anchoring)
- `status`, `last_updated`, `last_updated_by` (lifecycle tracking)
- `tags` (discoverability)

### 7. Key Design Principles

#### Separation of Observation and Advice
Research agents document what exists. Planning commands synthesize and propose. This separation prevents agents from biasing research with premature solution thinking.

#### Interactive Over Autonomous
`create_plan.md` explicitly requires check-ins at each step: "Don't write full plan in one shot, get buy-in at each step, allow course corrections." The user approves phase structure before details are written.

#### Skepticism as a Feature
"Be Skeptical: Question vague requirements, identify issues early, ask 'why' and 'what about', verify with code." The planning command is designed to push back on assumptions.

#### Phased Implementation with Gates
Plans are broken into phases, each with automated and manual success criteria. `implement_plan.md` requires pausing between phases for human verification unless explicitly told to continue.

#### Resumability
The handoff system (`create_handoff.md`, `resume_handoff.md`) ensures work can be transferred between sessions. Handoffs capture tasks, learnings, artifacts, and next steps as structured documents.

### 8. Sub-Agent Spawning Best Practices (from create_plan.md)

The `create_plan.md` codifies these rules for orchestrating agents:

1. Spawn multiple tasks in parallel for efficiency
2. Each task focused on specific area
3. Provide detailed instructions: what to search, which directories, what to extract, expected format
4. Be specific about directories with full path context
5. Specify read-only tools to use
6. Request file:line references in responses
7. Wait for all tasks before synthesizing
8. Verify sub-task results: spawn follow-ups if unexpected, cross-check findings

## Architecture Documentation

### Model Selection Pattern
- Agents (Tier 1): `model: sonnet` - cost-efficient for scoped work
- Orchestrators (Tier 2): `model: opus` - higher capability for synthesis and interaction
- Simple chains (Tier 3): no model specified (inherits default)

### Tool Constraint Pattern
Each agent receives only the tools it needs:
- Location agents: Grep, Glob, LS (no Read - they shouldn't read contents)
- Analysis agents: Read, Grep, Glob, LS (Read added for deep analysis)
- Web agents: WebSearch, WebFetch added
- Orchestrators: Full toolset including TodoWrite for tracking

### File Organization Pattern
```
agents/           → Tier 1 (sub-agents with constrained tools)
commands/         → Tier 2 (orchestrating workflows) + Tier 3 (composite commands)
research/         → Output: research artifacts
plans/            → Output: implementation plans (or thoughts/shared/plans/)
thoughts/shared/  → Output: all artifacts when thoughts system is present
```

## Open Questions

1. **How should a "lens" prompt be structured for a completely new/greenfield project with no existing codebase?** The current agents all assume an existing codebase to analyze. The `codebase-pattern-finder` explicitly looks for "similar implementations" - what happens when there are none?

2. **What's the minimum viable research document for a zero-to-one feature?** The research template is designed for documenting existing systems. For truly new features, the "Current State Analysis" and "Historical Context" sections may be empty or minimal.

3. **How do the "jeff-*" commands (jeff-bdd, jeff-map, jeff-hypothesis, jeff-research, jeff-opportunity, jeff-issues) relate to this workflow?** These commands appear in the system's skill list but have no corresponding files in this repository. They seem to be a parallel product-discovery workflow (user story mapping, BDD, hypothesis-driven development) that could feed into the research-to-plan pipeline.

4. **What role does `founder_mode` play in zero-to-one?** It's the only workflow that goes implementation-first, creating tickets and PRs retroactively. This suggests a recognized need for "hack first, document later" in experimental/exploratory work.
