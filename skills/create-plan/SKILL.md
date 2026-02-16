---
name: create-plan
description: Create detailed implementation plans through interactive research and iteration. Optionally syncs plan to Linear tickets with phase sub-issues.
model: opus
context: fork
allowed-tools: Read, Grep, Glob, Write, Edit, Task, AskUserQuestion, TodoWrite
argument-hint: [ticket-or-description]
---

# Implementation Plan

Create detailed implementation plans through an interactive, iterative process. Be skeptical, thorough, and work collaboratively with the user.

Ultrathink about the problem space, existing architecture, and implementation approach before starting.

**Input**: $ARGUMENTS

## Current Context

- **Branch**: !`git branch --show-current`
- **Last Commit**: !`git log -1 --oneline`
- **Modified Files**: !`git status --short`

## Initial Response

1. **If parameters provided**: Read any files completely (no limit/offset), then begin research
2. **If no parameters**:
```
I'll help you create a detailed implementation plan.

Please provide:
1. Task/ticket description (or file path to ticket)
2. Relevant context, constraints, or requirements
3. Links to related research or implementations

Tip: Invoke with a file directly: `/create_plan path/to/ticket.md`
```
Then wait for user input.

## Linear Ticket Detection

If the input references a Linear ticket (e.g. `ENG-1234`, `PLAT-56`, or a `thoughts/shared/tickets/*.md` file):
1. Note the ticket identifier for later use in Step 7
2. If a ticket file exists, read it fully for context
3. If only an identifier is provided, fetch ticket details using Linear MCP tools (see [Linear reference IDs](../linear/references/ids.md) for workspace and team IDs)

## Process Steps

### Step 1: Context Gathering & Initial Analysis

1. **Read mentioned files FULLY** (no limit/offset)
2. **Spawn parallel research tasks**:
   - **codebase-locator**: Find related files
   - **codebase-analyzer**: Understand current implementation
   - **codebase-pattern-finder**: Find similar features
   - **thoughts-locator**: Find existing documentation (if thoughts/ exists)
3. **Read all identified files FULLY**
4. **Analyze and verify**: Cross-reference requirements with actual code
5. **Present informed understanding** with findings and unanswered questions

### Step 2: Research & Discovery

1. If user corrects misunderstanding, spawn new research to verify
2. Create research todo list using TodoWrite
3. Spawn parallel sub-tasks for targeted investigation
4. Wait for ALL sub-tasks, then present findings with design options

5. **Get structured decisions** using AskUserQuestion:
   - **Approach**: Which design option to pursue (from research)
   - **Priority**: Speed vs quality vs simplicity
   - **Scope**: Full vs MVP vs phased

   Tailor options based on actual discoveries. Don't use generic options.

### Step 3: Technical Decisions

If the research surfaced technical choices that affect the plan, resolve them now before writing.

For each significant technical decision (e.g. library choice, data model design, API pattern, migration strategy), get a decision using AskUserQuestion:
- **[Decision topic]**: Present the trade-offs clearly
- Options should reflect the realistic choices discovered during research, with brief pros/cons for each
- Include an "I need more info" option for decisions the user isn't ready to make

Common technical decisions to watch for:
- **Architecture**: Monolith extension vs new service vs library extraction
- **Data model**: Schema design choices, storage engine, indexing strategy
- **API design**: REST vs GraphQL vs RPC, endpoint structure, versioning
- **Migration**: Big bang vs incremental, backwards compatibility approach
- **Dependencies**: Build vs buy, library selection, version constraints
- **Testing strategy**: Unit-heavy vs integration-heavy, test data approach

Record each decision and its rationale -- these go into the plan's "Key Discoveries" section.

If no technical decisions are needed, skip this step.

### Step 4: Plan Structure Development

1. Create initial outline with phases
2. Get feedback on structure before writing details

### Step 5: Detailed Plan Writing

Write plan to `thoughts/shared/plans/YYYY-MM-DD-description.md` or `plans/YYYY-MM-DD-description.md`

Use the template in [templates/plan-template.md](templates/plan-template.md).

Always separate success criteria into **Automated Verification** and **Manual Verification**.

Include a **Technical Decisions** section in the plan documenting choices made in Step 3 with their rationale.

### Step 6: Review & Iteration

1. Present draft location, ask for review
2. Iterate based on feedback
3. Continue refining until satisfied

### Step 7: Linear Sync

After the plan is finalized and the user is satisfied, check if a Linear ticket was detected.

**If no Linear ticket**: Get decision using AskUserQuestion:
- **Linear sync**: Would you like to attach this plan to a Linear ticket?
- Options should cover: yes (provide ticket ID), no thanks, create a new ticket for this

If "no thanks", skip to summary. If "create a new ticket", ask for the workspace and team, then create one using the Linear MCP tools (see [Linear reference IDs](../linear/references/ids.md)).

**If a Linear ticket exists (detected or provided)**:

1. **Determine the workspace** from the ticket identifier prefix or ask using AskUserQuestion if ambiguous. Use the correct workspace-namespaced MCP tools: `mcp__mise-tools__linear_{workspace}_*`

2. **Post the plan as a comment** on the ticket using `mcp__mise-tools__linear_{workspace}_create_comment`:
   - Include a concise summary of the plan (not the full plan text)
   - Link to the plan file path
   - List the phases with brief descriptions

3. **Create sub-issues for each phase** using `mcp__mise-tools__linear_{workspace}_create_issue` with `parentId` set to the parent ticket's ID:
   - **Title**: `Phase N: [Phase descriptive name]` (e.g. "Phase 1: Database schema migration")
   - **Description**: The phase overview, key changes, and success criteria from the plan
   - **Team**: Same team as the parent ticket
   - **State**: Backlog
   - **Labels**: Same labels as the parent ticket
   - Set `blockedBy` so each phase is blocked by the previous one (Phase 2 blocked by Phase 1, etc.)

4. **Update the parent ticket**:
   - Move status to "In Plan" if it's currently in an earlier state (Backlog, Todo, Ready for Research, In Research, Ready for Plan)
   - Attach the plan file as a link using the `links` parameter if the plan has been synced to a URL

5. **Present the sync results**:
   ```
   Linear sync complete:
   - Comment posted to [TICKET-ID]
   - Created [N] phase sub-issues:
     - [TICKET-ID-1]: Phase 1: [name]
     - [TICKET-ID-2]: Phase 2: [name]
     ...
   - Parent ticket moved to "In Plan"
   ```

## Guidelines

1. **Be Skeptical**: Question vague requirements, identify issues early, verify with code
2. **Be Interactive**: Don't write full plan in one shot, get buy-in at each step
3. **Be Thorough**: Read files completely, include file:line references, write measurable criteria
4. **Be Practical**: Incremental testable changes, consider migration/rollback
5. **No Open Questions in Final Plan**: Research or ask immediately
6. **Decide Before Writing**: Resolve technical decisions interactively before committing them to the plan, not after
7. **Linear Sync is Optional**: Never force Linear integration -- always give the user an opt-out

## Common Patterns

**Database Changes**: Schema/migration -> Store methods -> Business logic -> API -> Clients
**New Features**: Research patterns -> Data model -> Backend -> API -> UI
**Refactoring**: Document current behavior -> Plan incremental changes -> Maintain backwards compat
