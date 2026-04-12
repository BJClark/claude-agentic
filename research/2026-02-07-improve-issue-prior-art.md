---
date: 2026-02-07T10:00:00-08:00
researcher: claude
git_commit: 0e364b6
branch: main
repository: claude-agentic
topic: "Prior art for an 'improve issue' skill that reads, researches, clarifies, and enriches tickets"
tags: [research, skills, linear, tickets, issue-improvement]
status: complete
last_updated: 2026-02-07
last_updated_by: claude
---

# Research: Prior Art for an "Improve Issue" Skill

**Date**: 2026-02-07
**Researcher**: claude
**Git Commit**: 0e364b6
**Branch**: main
**Repository**: claude-agentic

## Research Question

We need a new skill to "improve an issue" -- take an issue from Linear or GitHub, read it, identify what an engineer would need to know to implement that ticket, see if we can answer it with artifacts already here, and ask the user clarifying questions. Finally, improve the ticket with this new information. What "prior art" in our prompts exists for each of these capabilities?

## Summary

The codebase already contains substantial prior art for every component of the proposed "improve issue" skill, spread across multiple commands and skills. No single existing skill performs the full "improve issue" workflow, but the building blocks are well-established and battle-tested. The closest existing analog is `/ralph_research`, which reads a ticket, researches the codebase, and updates the ticket -- but it focuses on producing a standalone research document rather than enriching the ticket description itself.

Key discoveries:
- **Reading issues from Linear/GitHub**: Three commands (`ralph_research`, `ralph_plan`, `ralph_impl`) all fetch and read Linear tickets using MCP tools and the `linear` CLI, following the same pattern
- **Identifying implementation needs & researching the codebase**: `ralph_research` conducts codebase research and documents findings; `create-plan` performs thorough context gathering with parallel sub-agents; `ddd-align` extracts business context from documents
- **Asking clarifying questions**: `AskUserQuestion` is used extensively across DDD skills, `create-plan`, `implement-plan`, and `debug-issue` for interactive validation with structured options
- **Updating tickets with enriched information**: `linear.md` contains the full protocol for adding comments, updating descriptions, managing links, and following the team workflow

## Detailed Findings

### 1. Reading Issues from Linear/GitHub

#### `commands/ralph_research.md`

**Location**: `/Users/willclark/Developer/scidept/claude-agentic/commands/ralph_research.md`

**How it reads tickets**:
- Fetches tickets using `linear` CLI into `thoughts/shared/tickets/ENG-xxxx.md` (line 7)
- Reads the ticket and all comments to understand what research is needed (line 8)
- Can work with a mentioned ticket or fetch top 10 priority items in "research needed" status
- Falls back to selecting highest priority SMALL or XS issue

#### `commands/ralph_plan.md`

**Location**: `/Users/willclark/Developer/scidept/claude-agentic/commands/ralph_plan.md`

**How it reads tickets**:
- Same pattern as `ralph_research`: fetches with `linear` CLI to `thoughts/shared/tickets/ENG-xxxx.md` (line 7)
- Reads ticket and all comments to learn about past implementations and research (line 8)
- Checks the `links` section for linked documents

#### `commands/ralph_impl.md`

**Location**: `/Users/willclark/Developer/scidept/claude-agentic/commands/ralph_impl.md`

**How it reads tickets**:
- Same fetch pattern (line 8)
- Reads ticket and all comments to understand the implementation plan (line 9)
- Identifies linked implementation plan documents from the `links` section (line 24)

**Common ticket fetch pattern across all three**:
```
0c. use `linear` cli to fetch the selected item into thoughts with the ticket number - ./thoughts/shared/tickets/ENG-xxxx.md
0d. read the ticket and all comments to understand [context-specific goal]
```

#### `commands/linear.md`

**Location**: `/Users/willclark/Developer/scidept/claude-agentic/commands/linear.md`

**How it reads tickets**:
- Uses `mcp__linear__get_issue` to fetch ticket details (line 211)
- Uses `mcp__linear__list_issues` for searching (line 280-285)
- Documents all workflow state IDs for status management (lines 366-384)
- Documents team ID and label IDs for correct categorization

### 2. Identifying What an Engineer Would Need to Know

#### `skills/create-plan/SKILL.md`

**Location**: `/Users/willclark/Developer/scidept/claude-agentic/skills/create-plan/SKILL.md`

**Relevant patterns**:
- Step 1 "Context Gathering & Initial Analysis" (lines 42-55): Spawns four parallel research sub-agents:
  - `codebase-locator`: Find related files
  - `codebase-analyzer`: Understand current implementation
  - `codebase-pattern-finder`: Find similar features
  - `thoughts-locator`: Find existing documentation
- Reads ALL identified files fully
- Cross-references requirements with actual code
- Presents informed understanding with findings and **unanswered questions**

#### `commands/ralph_research.md`

**Location**: `/Users/willclark/Developer/scidept/claude-agentic/commands/ralph_research.md`

**Relevant patterns** (lines 28-49):
- Uses `/research-codebase` for codebase research guidance
- Searches for relevant implementations and patterns
- Examines existing similar features or related code
- Identifies technical constraints and opportunities
- Documents findings in a research document with date-based naming
- Synthesizes research into actionable insights: key findings, implementation approaches, risks

#### `skills/research-codebase/SKILL.md`

**Location**: `/Users/willclark/Developer/scidept/claude-agentic/skills/research-codebase/SKILL.md`

**Relevant patterns**:
- Decomposes query into research areas (line 37-39)
- Spawns parallel sub-agents: codebase-locator, codebase-analyzer, codebase-pattern-finder, thoughts-locator, thoughts-analyzer (lines 43-56)
- Synthesizes findings with specific file:line references (lines 60-65)
- Generates structured research document with YAML frontmatter

#### `skills/ddd-align/SKILL.md`

**Location**: `/Users/willclark/Developer/scidept/claude-agentic/skills/ddd-align/SKILL.md`

**Relevant patterns** for understanding what needs to be known:
- Extracts: business purpose, actors/roles, value propositions, core workflows, constraints, revenue model (lines 47-53)
- Presents a structured "Business Domain Summary" for validation
- Captures assumptions and open questions explicitly

### 3. Checking Existing Artifacts for Answers

#### `commands/ralph_research.md`

**Location**: `/Users/willclark/Developer/scidept/claude-agentic/commands/ralph_research.md`

**Relevant patterns**:
- Reads linked documents in the ticket's `links` section (line 23)
- Uses the ticket's comments to understand previous research attempts (line 8)

#### `skills/create-plan/SKILL.md`

**Location**: `/Users/willclark/Developer/scidept/claude-agentic/skills/create-plan/SKILL.md`

**Relevant patterns**:
- `thoughts-locator` agent finds existing documentation (line 49)
- Reads all identified files fully before proceeding (line 50)

#### `commands/resume_handoff.md`

**Location**: `/Users/willclark/Developer/scidept/claude-agentic/commands/resume_handoff.md`

**Relevant patterns**:
- Reads research or plan documents linked from handoff under `thoughts/shared/plans` or `thoughts/shared/research` (lines 16, 28)
- Checks for existing artifacts and validates their current relevance

#### Agent: `thoughts-locator`

**Location**: `/Users/willclark/Developer/scidept/claude-agentic/agents/thoughts-locator.md`

This agent specifically locates relevant documentation in the `thoughts/` directory hierarchy and is used by both `research-codebase` and `create-plan`.

#### Agent: `thoughts-analyzer`

**Location**: `/Users/willclark/Developer/scidept/claude-agentic/agents/thoughts-analyzer.md`

This agent extracts insights from documentation found by `thoughts-locator`.

### 4. Asking the User Clarifying Questions

#### `AskUserQuestion` Tool Usage Across Skills

The `AskUserQuestion` tool is the standard mechanism for interactive clarification. It supports structured multi-choice questions with headers and descriptions.

**`skills/ddd-align/SKILL.md`** (lines 90-110):
- Asks "Does this Business Domain Summary accurately capture your domain?"
- Options: "Looks accurate", "Needs corrections", "Major gaps"
- Iterates until user confirms accuracy

**`skills/ddd-discover/SKILL.md`** (lines 62-136):
- Asks about event timeline accuracy with 4 options
- Asks about flow correctness (triggers, failure paths, alternatives)
- Asks about gap resolution with 3 options ("I'll fill this in", "Out of scope", "Needs research")

**`skills/create-plan/SKILL.md`** (lines 61-66):
- Gets structured decisions on approach, priority, and scope
- Tailors options based on actual research discoveries

**`skills/implement-plan/SKILL.md`** (lines 86-106):
- Phase gate questions: "Proceed to Next Phase", "Fix Issues First", "Review Changes"

**`skills/debug-issue/SKILL.md`** (lines 131-147):
- Team mode selection: "Competing Hypotheses" vs "Single Investigation"

**`skills/ddd-full/SKILL.md`** (lines 103-119):
- Team mode selection for parallel exploration

#### Pattern: Asking for clarification when information is insufficient

**`commands/ralph_research.md`** (line 24):
```
1b. if insufficient information to conduct research, add a comment asking for clarification and move back to "research needed"
```

**`commands/linear.md`** (line 331):
```
- Ask for clarification rather than guessing project/status
```

**`commands/linear.md`** (line 325):
```
- All tickets should include a clear "problem to solve" - if the user asks for a ticket and only gives implementation details, you MUST ask "To write a good ticket, please explain the problem you're trying to solve from a user perspective"
```

### 5. Updating/Enriching the Ticket

#### `commands/linear.md`

**Location**: `/Users/willclark/Developer/scidept/claude-agentic/commands/linear.md`

This is the primary protocol for all ticket manipulation. Key sections:

**Creating ticket descriptions** (lines 84-178):
- Analyzes document content to identify core problem, extract implementation details, note code areas mentioned
- Drafts ticket with: title, description, key details, implementation notes, references
- Interactive refinement with user before creation
- Uses `links` parameter for external URLs

**Adding comments** (lines 205-253):
- Formats comments for clarity, ~10 lines
- Focus on key insights, decisions, blockers, state changes
- File references with backticks and GitHub links
- Uses `mcp__linear__create_comment` for comments
- Uses `mcp__linear__update_issue` for links

**Updating ticket status** (lines 268-319):
- Full workflow state progression documented
- Status IDs for all states (lines 366-384)
- Comments explaining status changes

**Comment quality guidelines** (lines 337-352):
- Key insights over summaries
- Decisions and tradeoffs
- Blockers resolved
- State changes
- Surprises or discoveries

**Ticket structure requirement** (line 325):
```
All tickets should include a clear "problem to solve"
```

**Ticket format** (lines 189-203):
```markdown
Title: Fix resumed sessions to inherit all configuration from parent

Description:

## Problem to solve
[description]

## Solution
[description]
```

#### `commands/ralph_research.md`

**Location**: `/Users/willclark/Developer/scidept/claude-agentic/commands/ralph_research.md`

**How it updates tickets** (lines 53-55):
- Attaches research document to ticket using MCP tools with proper link formatting
- Adds a comment summarizing research outcomes, noting milestone relevance
- Moves item to "research in review" status

#### `commands/ralph_plan.md`

**Location**: `/Users/willclark/Developer/scidept/claude-agentic/commands/ralph_plan.md`

**How it updates tickets** (lines 30-33):
- Runs `humanlayer thoughts sync` and attaches doc to ticket using MCP tools
- Creates terse comment with link to plan
- Notes milestone targeting in comment
- Moves item to "plan in review" status

### 6. Team Workflow State Machine

**Location**: `/Users/willclark/Developer/scidept/claude-agentic/commands/linear.md` (lines 39-53)

The team follows a specific workflow progression:

```
Triage -> Spec Needed -> Research Needed -> Research in Progress -> Research in Review
-> Ready for Plan -> Plan in Progress -> Plan in Review -> Ready for Dev -> In Dev
-> Code Review -> Done
```

The "improve issue" skill would likely interact with the early stages of this workflow: `Triage`, `Spec Needed`, and `Research Needed`. The `ralph_research` command already handles the `Research Needed -> Research in Progress -> Research in Review` transition.

### 7. Sub-Agent Architecture

The codebase uses three main sub-agent types for research:

**`agents/codebase-locator.md`**: Finds WHERE code lives. Returns structured file location maps grouped by purpose.

**`agents/codebase-analyzer.md`**: Understands HOW code works. Returns analysis with entry points, core implementation, data flow, key patterns, and configuration.

**`agents/codebase-pattern-finder.md`**: Finds similar implementations. Returns pattern examples with code snippets, file:line references, and usage context.

These agents are composed by `create-plan` and `research-codebase` to do parallel investigation.

### 8. Closest Existing Analog: `ralph_research`

The `ralph_research` command is the closest existing analog to the proposed "improve issue" skill. Its flow:

1. Read a Linear ticket and its comments
2. Read linked documents
3. If insufficient information, ask for clarification via a ticket comment
4. Conduct codebase research using `/research-codebase`
5. Conduct web research if needed
6. Document findings in a research document
7. Attach research to the ticket and add a summary comment
8. Move the ticket to "research in review"

The key differences from the proposed "improve issue" skill:
- **Output target**: `ralph_research` produces a standalone research document; "improve issue" enriches the ticket description itself
- **Interaction model**: `ralph_research` asks for clarification via ticket comments (async); "improve issue" uses `AskUserQuestion` (interactive/synchronous)
- **Scope of investigation**: `ralph_research` digs into the codebase; "improve issue" only checks existing project artifacts (docs, thoughts/, linked materials) -- no code research
- **Workflow stage**: `ralph_research` handles `Research Needed -> Research in Review`; "improve issue" handles earlier stages (`Triage -> Spec Needed` or `Spec Needed -> Research Needed`)
- **Platform**: `ralph_research` is Linear-only; "improve issue" supports both Linear and GitHub Issues

### 9. Ticket Quality Standards

**`commands/linear.md`** (line 325) establishes the core quality standard:
```
All tickets should include a clear "problem to solve" - if the user asks for a ticket and only gives
implementation details, you MUST ask "To write a good ticket, please explain the problem you're trying
to solve from a user perspective"
```

The ticket creation flow in `linear.md` (lines 84-178) shows the expected structure:
- Clear, action-oriented title
- 2-3 sentence summary of the problem/goal
- Key details as bullet points
- Implementation notes (if applicable)
- References to source material
- Assessment of ticket maturity stage (ideation/planning/ready to implement)

## Code References

Quick reference index of key files:

- `commands/ralph_research.md` - Closest analog; reads tickets, researches, updates tickets
- `commands/ralph_plan.md` - Reads tickets, creates plans, updates tickets
- `commands/ralph_impl.md` - Reads tickets, implements, creates PRs
- `commands/linear.md` - Full protocol for ticket CRUD operations, workflow states, comment quality
- `commands/linear_pm.md` - Product management operations (initiatives, milestones, updates)
- `skills/create-plan/SKILL.md` - Parallel research sub-agents, interactive clarification
- `skills/research-codebase/SKILL.md` - Codebase research with sub-agents, document generation
- `skills/ddd-align/SKILL.md` - Extracting business context, interactive validation
- `skills/ddd-discover/SKILL.md` - Interactive gap-filling with `AskUserQuestion`
- `skills/debug-issue/SKILL.md` - Problem understanding workflow, team mode
- `skills/implement-plan/SKILL.md` - Phase gates with `AskUserQuestion`
- `agents/codebase-locator.md` - File location sub-agent
- `agents/codebase-analyzer.md` - Code analysis sub-agent
- `agents/codebase-pattern-finder.md` - Pattern finding sub-agent
- `agents/thoughts-locator.md` - Documentation locator sub-agent
- `agents/thoughts-analyzer.md` - Documentation analyzer sub-agent
- `commands/founder_mode.md` - Retroactive ticket creation from implementation
- `commands/create_handoff.md` - Handoff document creation pattern
- `commands/resume_handoff.md` - Resuming from existing artifacts

## Architecture Documentation

### Patterns Used

- **Parallel sub-agent spawning**: Used by `create-plan`, `research-codebase`, `debug-issue` to investigate multiple aspects simultaneously
- **AskUserQuestion interactive gates**: Used by all DDD skills, `create-plan`, `implement-plan` for structured user input with multi-choice options
- **Ticket fetch -> read -> research -> update cycle**: Established by `ralph_research`, `ralph_plan`, `ralph_impl`
- **Thoughts directory as artifact store**: Research docs, plans, tickets, handoffs stored under `thoughts/shared/`
- **Status-based workflow progression**: Linear workflow states drive which commands operate on which tickets
- **Comment quality guidelines**: Focus on insights, decisions, blockers rather than mechanical summaries

### Data Flow for Issue Processing

```
Linear/GitHub Issue
  -> Fetch via MCP tools or CLI
    -> Store locally (thoughts/shared/tickets/ENG-xxxx.md)
      -> Read ticket + comments + linked docs
        -> Research codebase (parallel sub-agents)
          -> Synthesize findings
            -> Ask user clarifying questions (AskUserQuestion)
              -> Update ticket (mcp__linear__update_issue, mcp__linear__create_comment)
                -> Move ticket to next workflow state
```

## Clarified Requirements

1. **Goal**: Enrich the issue itself (description, acceptance criteria, context) -- NOT produce a local research document. This is about improving the ticket so an engineer can pick it up.
2. **Platforms**: Both Linear and GitHub Issues.
3. **Workflow stage**: Pre-research. This operates at `Triage -> Spec Needed` or `Spec Needed -> Research Needed`. It looks at existing documentation and project artifacts only -- NO codebase deep-dives.
4. **Output**: Just enrich the ticket. No separate research document.

## Key Distinction from `ralph_research`

`ralph_research` is a deep codebase research phase that produces a standalone document. The "improve issue" skill is earlier in the pipeline: it reads the ticket, checks existing project artifacts (thoughts/, docs, linked materials), asks the user clarifying questions interactively via `AskUserQuestion`, and writes the findings back into the ticket description itself. It does not dig into source code.

## Open Questions

1. Should the skill auto-detect whether the issue is Linear or GitHub, or should the user specify?
2. What's the minimum bar for a "well-specified" ticket -- when does the skill consider itself done?
3. Should it update the workflow state (e.g., move from Triage to Spec Needed) or just enrich the content?
