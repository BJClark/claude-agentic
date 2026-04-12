---
date: 2026-02-18T14:00:00-08:00
researcher: Claude
git_commit: 363e3ac5f53b307291d262583d7d22d93addca78
branch: main
repository: claude-agentic
topic: "Do we have the right skills to create a command that iterates through Linear project stories, identifies unclear areas (backend and frontend UX), and improves or suggests new stories?"
tags: [research, linear, improve-issue, pm, skills-audit]
status: complete
last_updated: 2026-02-18
last_updated_by: Claude
---

# Research: Linear Project Story Improvement Capabilities

**Date**: 2026-02-18
**Researcher**: Claude
**Git Commit**: 363e3ac
**Branch**: main
**Repository**: claude-agentic

## Research Question

Do we have the right skills to create a command which will take a Linear project, iterate through all the stories looking for areas where it's unclear, both on the backend implementation and the front end of how the user experience should work, and then improve the individual stories or suggest new ones?

## Summary

The existing skill and tool ecosystem contains most of the building blocks needed for this command. The key capabilities required are: (1) listing all issues within a Linear project, (2) reading and assessing each story for clarity, (3) updating stories with enriched content, and (4) creating new stories. All four are present today across different skills and tools. What does not exist is a single orchestrating skill that composes these capabilities into a project-level iteration workflow.

The closest existing skill is `improve-issue`, which assesses a single ticket against a quality checklist, searches for existing artifacts, runs interactive clarification, and appends enriched content back to the ticket. It operates on one ticket at a time and requires user interaction per ticket. The `linear` skill provides the CRUD operations for tickets (list, get, create, update), and the `linear-pm` skill provides project-level operations (list projects, milestones, project updates). The MCP tools (`mcp__mise-tools__linear_{workspace}_*`) provide the underlying API access across three workspaces (Stellar, Kickplan, Meerkat).

Key discoveries:
- The `improve-issue` skill already implements a quality assessment framework with five criteria (problem statement, actors, acceptance criteria, context/references, ambiguities) that could serve as the per-story evaluation logic
- The Linear MCP tools include `list_issues` (with projectId filtering), `get_issue`, `update_issue`, and `create_issue` -- all the CRUD operations needed for project-level iteration
- The `pm-synthesize` and `pm-architect` workflows demonstrate a pattern for bulk-processing stories and creating them in Linear, providing an orchestration model
- No existing skill combines "iterate through a project's stories" with "assess and improve each one"

## Detailed Findings

### 1. Linear MCP Tool Capabilities

**Location**: Available via `mcp__mise-tools__linear_{workspace}_*` (deferred tools loaded via ToolSearch)

**Available operations relevant to this command**:

| Tool | Purpose |
|------|---------|
| `list_issues` | List issues with filtering by projectId, teamId, stateId, query, limit |
| `get_issue` | Fetch full issue details including description, comments, labels, state |
| `update_issue` | Update issue description, state, labels, links, assignee, priority |
| `create_issue` | Create new issues with full metadata (title, description, teamId, stateId, projectId, labelIds, parentId) |
| `list_projects` | List all projects in a workspace |
| `get_project` | Get project details |
| `create_comment` | Add comments to issues |
| `list_comments` | Read existing comments on issues |

**Workspaces**: Stellar, Kickplan, Meerkat -- each with their own tool namespace and reference IDs documented at `skills/linear/references/ids.md`.

### 2. The `improve-issue` Skill

**Location**: `/Users/willclark/Developer/scidept/claude-agentic/skills/improve-issue/SKILL.md`

**Purpose**: Enrich a single ticket so it is ready for an engineer to start planning.

**Quality Assessment Framework** (Step 3 of the skill):

| Criterion | What it checks |
|-----------|---------------|
| Problem to solve | Clear description of what problem this addresses and why it matters |
| Actors/users | Who is affected? Who will use this? |
| Acceptance criteria | How do we know when this is done? What does success look like? |
| Context & references | Links to relevant docs, designs, or prior discussions |
| No ambiguities | No open questions that would block an engineer from planning |

**Process flow**: Parse ticket identifier -> Fetch ticket content -> Assess quality against checklist -> Search existing artifacts (thoughts/ directory) -> Interactive clarification via AskUserQuestion for each gap -> Preview proposed additions -> Confirm and update ticket.

**Relevant characteristics**:
- Operates on a single ticket at a time (takes one ticket identifier as input)
- Uses `context: fork` (runs as a sub-agent)
- Allowed tools: `Read, Grep, Glob, Task, AskUserQuestion, Bash`
- Does not have write access to Linear MCP tools directly -- it uses `mcp__linear__get_issue` and `mcp__linear__update_issue` (referenced in Step 7 without the workspace namespace, suggesting it predates the multi-workspace setup)
- Appends content to existing descriptions, never overwrites
- Searches `thoughts/` directory for related artifacts
- Interactive per-ticket: asks the user to clarify each gap individually

### 3. The `linear` Skill

**Location**: `/Users/willclark/Developer/scidept/claude-agentic/skills/linear/SKILL.md`

**Purpose**: Manage Linear tickets -- create, update, comment, search, and follow workflow patterns.

**Relevant capabilities**:
- Search/list issues with filtering (Step 2): `mcp__mise-tools__linear_{workspace}_list_issues` with query, teamId, stateId, limit 20
- Create tickets with full metadata (Step 1): title, description, teamId, priority, stateId, labelIds, assigneeId
- Update ticket status through the workflow (Step 3)
- Add comments and links (Step 4)
- Multi-workspace aware with correct tool namespacing

**Workflow states** documented per workspace and team at `skills/linear/references/ids.md`:
```
Backlog -> Todo -> Ready for Research -> In Research -> Ready for Plan -> In Plan -> In Progress -> In Review -> Done
```

### 4. The `linear-pm` Skill

**Location**: `/Users/willclark/Developer/scidept/claude-agentic/skills/linear-pm/SKILL.md`

**Purpose**: Manage Linear product management at the strategic layer -- initiatives, milestones, project updates, project labels.

**Relevant capabilities**:
- List projects (`list_projects`)
- Get project details (`get_project`)
- List milestones within a project (`list_milestones`)
- The hierarchy: Initiative > Project > Milestone > Issue

This skill provides the project-level entry point -- listing projects and understanding their structure -- but delegates issue-level work to `/linear`.

### 5. The `pm-synthesize` Skill and `pm-architect` Agent

**Location**: `/Users/willclark/Developer/scidept/claude-agentic/skills/pm-synthesize/SKILL.md` and `/Users/willclark/Developer/scidept/claude-agentic/agents/pm-architect.md`

**Purpose**: Translate Jeff story maps and DDD artifacts into a structured build plan, then bulk-create Linear items.

**Relevant patterns**:
- **Bulk issue processing**: The `pm-architect` agent creates issues in dependency order (Labels -> Initiative -> Projects -> Milestones -> Issues), demonstrating how to orchestrate multiple Linear API calls
- **Progress reporting**: Reports progress every 5 items during bulk creation
- **Error handling**: Logs failures, skips items, continues, reports all failures at end
- **Write-back pattern**: After building, updates a local build-plan file with all Linear IDs for traceability
- **State assignment logic**: Assigns workflow states based on detail richness (Minimal -> Backlog, Moderate -> Todo, Rich -> Ready for Research)

This is the closest existing model for "iterate through many stories and do something with each one."

### 6. The `create-plan` Skill

**Location**: `/Users/willclark/Developer/scidept/claude-agentic/skills/create-plan/SKILL.md`

**Purpose**: Create detailed implementation plans through interactive research and iteration, with optional Linear sync.

**Relevant characteristics**:
- Demonstrates the pattern of creating sub-issues on a parent ticket (Step 7, "Create sub-issues for each phase")
- Shows how to detect and use Linear ticket context
- Uses parallel research agents (codebase-locator, codebase-analyzer, codebase-pattern-finder, thoughts-locator)

### 7. The `research-codebase` Skill

**Location**: `/Users/willclark/Developer/scidept/claude-agentic/skills/research-codebase/SKILL.md`

**Purpose**: Research codebase comprehensively by exploring components, patterns, and connections.

**Relevant characteristics**:
- Provides the codebase research capability that would be needed to assess backend implementation clarity
- Spawns parallel sub-agents for different research perspectives (locator, analyzer, pattern-finder)
- Could be composed into per-story research for backend assessment

### 8. The `qa` Skill

**Location**: `/Users/willclark/Developer/scidept/claude-agentic/skills/qa/SKILL.md`

**Purpose**: Walk through acceptance criteria in the browser to validate features work.

**Relevant characteristics**:
- Extracts and evaluates acceptance criteria from tickets
- Demonstrates the pattern of iterating through criteria, evaluating each, and producing a structured report
- The per-criterion evaluation pattern (announce step, perform action, evaluate result, record verdict) could inform how per-story assessment works

### 9. Orchestrating Commands

**Location**: `/Users/willclark/Developer/scidept/claude-agentic/commands/`

Existing commands show how to compose skills:
- `commands/pm.md`: Orchestrates `pm-synthesize` via the `pm-architect` agent
- `commands/ddd.md`: Orchestrates 7 DDD skills via the `ddd-architect` agent
- `commands/ralph_research.md`: Fetches Linear tickets, selects one, conducts research, updates ticket
- `commands/ralph_plan.md`: Fetches Linear tickets, creates implementation plans, updates ticket

The `ralph_research` command is notable because it demonstrates the pattern of: fetch tickets from Linear by status -> select one -> do work on it -> update it. The proposed command would extend this from "work on one ticket" to "iterate through all tickets in a project."

### 10. Agent Infrastructure

**Location**: `/Users/willclark/Developer/scidept/claude-agentic/agents/`

Available agents that could participate in a project-level story improvement workflow:
- `pm-architect.md`: Demonstrates bulk Linear operations with progress reporting
- `ddd-architect.md`: Demonstrates multi-step orchestration with confirmation gates
- `codebase-analyzer.md`: Analyzes how code works, traces data flows
- `codebase-locator.md`: Finds where files/components live
- `thoughts-analyzer.md`: Extracts insights from documentation
- `thoughts-locator.md`: Finds relevant documents

### 11. Skill Authoring Infrastructure

**Location**: `/Users/willclark/Developer/scidept/claude-agentic/skills/skill-builder/SKILL.md`

The `skill-builder` skill exists to create new skills following Context Engineering principles (Research, Plan, Implement). It references conventions at `skills/skill-builder/references/conventions.md` and uses a template at `skills/skill-builder/templates/skill-template.md`.

The `scripts/install.sh` script syncs skills, commands, and agents from the repo to `~/.claude/` for use in any project.

## Architecture Documentation

### Capability Map for the Proposed Command

```
Proposed command: "Improve Linear Project Stories"
├── List project's issues .............. linear skill (list_issues with projectId)
├── For each issue:
│   ├── Assess clarity ................. improve-issue skill (quality checklist)
│   │   ├── Backend clarity ............ research-codebase skill (codebase analysis)
│   │   └── Frontend UX clarity ........ No existing skill (would need UX assessment criteria)
│   ├── Improve unclear stories ........ improve-issue skill (enrichment workflow)
│   └── Suggest new stories ............ linear skill (create_issue)
├── Report findings .................... pm-architect pattern (progress reporting, summary)
└── Batch vs interactive ............... No existing pattern for batch-with-selective-interaction
```

### Existing Composition Patterns

| Pattern | Where it exists | How it works |
|---------|----------------|-------------|
| Single-ticket improvement | `improve-issue` | Fetch -> Assess -> Clarify -> Update |
| Bulk Linear creation | `pm-architect` | Synthesize plan -> Build in dependency order -> Write back IDs |
| Ticket selection from list | `ralph_research` | Fetch by status -> Select highest priority -> Process one |
| Multi-step orchestration | `ddd-architect` | Chain of skills with confirmation gates between steps |
| Parallel sub-agent research | `research-codebase`, `create-plan` | Spawn locator/analyzer/pattern-finder agents in parallel |

### MCP Tool Access Pattern

Skills access Linear via deferred MCP tools that must be loaded via ToolSearch before use:
```
ToolSearch("select:mcp__mise-tools__linear_{workspace}_list_issues")
-> mcp__mise-tools__linear_{workspace}_list_issues(projectId: "...", limit: 50)
```

Three workspaces exist (Stellar, Kickplan, Meerkat), each with their own tool namespace. Reference IDs for teams, workflow states, labels, and users are documented per workspace at `skills/linear/references/ids.md`.

### Skill Composition Model

Skills use `context: fork` to run as sub-agents. They communicate with the user via `AskUserQuestion`. An orchestrating command or agent can call skills via the `Skill` tool and pass arguments. The `pm-architect` and `ddd-architect` agents demonstrate this pattern.

## Code References

Quick reference index of key files:

- `skills/improve-issue/SKILL.md` - Single-ticket quality assessment and enrichment
- `skills/linear/SKILL.md` - Linear ticket CRUD operations
- `skills/linear-pm/SKILL.md` - Project-level Linear operations
- `skills/linear/references/ids.md` - All workspace, team, state, label, and user IDs
- `skills/pm-synthesize/SKILL.md` - Bulk story synthesis from artifacts
- `agents/pm-architect.md` - Bulk Linear creation with progress reporting
- `agents/ddd-architect.md` - Multi-step orchestration with confirmation gates
- `commands/ralph_research.md` - Ticket fetch -> process -> update pattern
- `skills/research-codebase/SKILL.md` - Codebase analysis capabilities
- `skills/qa/SKILL.md` - Per-criterion evaluation and reporting pattern
- `skills/skill-builder/SKILL.md` - Skill authoring infrastructure
- `scripts/install.sh` - Syncs skills/commands/agents to ~/.claude/

## Open Questions

1. **Batch interaction model**: The `improve-issue` skill is heavily interactive (asks user per gap per ticket). For a project with 20-50 stories, this would be impractical. How should the new command handle the tension between thoroughness (per-story clarification) and efficiency (batch assessment)?

2. **Frontend UX assessment criteria**: The `improve-issue` quality checklist covers general clarity (problem, actors, acceptance criteria, context, ambiguities) but does not have a specific lens for "is the UX clear enough?" -- no criteria for wireframes, user flows, interaction patterns, error states from a UX perspective, or accessibility considerations.

3. **Backend implementation assessment criteria**: The `improve-issue` skill explicitly avoids deep codebase research ("Don't deep-dive into code: Only check existing documentation artifacts -- codebase research is what `/ralph_research` does"). Assessing backend implementation clarity for each story would require integrating codebase analysis, which `improve-issue` currently delegates elsewhere.

4. **"Suggest new stories" scope**: Existing skills can create tickets (`linear` skill, `create_issue` MCP tool), but no existing skill contains logic for _identifying_ what new stories are needed based on gaps found across a set of existing stories. This gap-analysis-to-new-story pipeline would be novel.

5. **Linear API rate limits**: Iterating through an entire project's stories involves many API calls (list + get for each story, update for improvements, create for new stories). The `pm-architect` agent handles errors by logging and continuing, but rate limit behavior across workspaces is not documented.

6. **`improve-issue` MCP tool references**: The `improve-issue` skill references `mcp__linear__get_issue` and `mcp__linear__update_issue` without workspace namespacing, which differs from the multi-workspace pattern used by the `linear` skill (`mcp__mise-tools__linear_{workspace}_*`). This would need reconciling in a composed workflow.
