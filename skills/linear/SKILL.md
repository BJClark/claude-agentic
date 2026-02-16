---
name: linear
description: "Manage Linear tickets - create, update, comment, search, and follow workflow patterns. Use when working with Linear issues or tickets."
model: opus
context: fork
allowed-tools: Read, Grep, Glob, Task, AskUserQuestion, TodoWrite
argument-hint: [action or ticket-id]
---

# Linear Ticket Management

Ultrathink about the team's workflow stages and how this request fits into the Backlog -> Todo -> Ready for Research -> In Research -> Ready for Plan -> In Plan -> In Progress -> In Review -> Done lifecycle. Consider what the user needs and the most efficient path to accomplish it.

Manage Linear tickets: create, update status, add comments and links, search and filter. For product management (initiatives, milestones, project updates), use `/linear-pm` instead.

**Input**: $ARGUMENTS

## Current Context

- **Branch**: !`git branch --show-current`
- **Last Commit**: !`git log -1 --oneline`

## Workspaces

This skill works across three Linear workspaces via MCP. Tools are namespaced:
- **Stellar**: `mcp__mise-tools__linear_stellar_*`
- **Kickplan**: `mcp__mise-tools__linear_kickplan_*`
- **Meerkat**: `mcp__mise-tools__linear_meerkat_*`

See [references/ids.md](references/ids.md) for all team, user, workflow state, and label IDs per workspace.

## Initial Response

1. **If a workspace and action are clear from context**: Begin the appropriate workflow
2. **If the workspace is ambiguous**, get it using AskUserQuestion:
   - **Workspace**: Which Linear workspace?
   - Options should cover: Stellar, Kickplan, Meerkat
3. **If no action is specified**, get it using AskUserQuestion:
   - **Action**: What would you like to do?
   - Options should cover: Create a ticket, Search for tickets, Update ticket status, Add comment to a ticket

## Workflow

All teams follow the same status progression:

1. **Backlog** — parked, not yet prioritized
2. **Todo** — prioritized, ready for someone to pick up
3. **Ready for Research** — needs investigation before planning
4. **In Research** — active investigation underway
5. **Ready for Plan** — research complete, needs implementation plan
6. **In Plan** — actively writing the plan
7. **In Progress** — active development
8. **In Review** — PR submitted or work under review
9. **Done** — completed

**Key principle**: Review and alignment happen at the plan stage (not PR stage) to move faster and avoid rework.

## Process Steps

### Step 1: Create Ticket

1. **If given a thoughts document or topic**, read it and extract:
   - The core problem or feature
   - Key implementation details
   - Referenced files or areas
   - What stage the idea is at

2. **Get the team** using AskUserQuestion:
   - **Team**: Which team should own this ticket?
   - Options: teams from the selected workspace (see references/ids.md)

3. **Draft the ticket and present it:**
   ```
   ## Draft Linear Ticket

   **Title**: [Clear, action-oriented title]

   **Description**:
   ## Problem to solve
   [2-3 sentence summary]

   ## Key Details
   - [Important details]
   - [Technical decisions or constraints]

   ## References
   - Source: [link if applicable]
   ```

4. **Get priority** using AskUserQuestion:
   - **Priority**: What priority?
   - Options should cover: Urgent (critical blockers), High (important), Medium (standard), Low (nice-to-have)

5. **Get confirmation** using AskUserQuestion:
   - **Create**: Ready to create this ticket?
   - Options should cover: create it, needs changes, cancel

6. **Create the ticket** using `mcp__mise-tools__linear_{workspace}_create_issue` with:
   - title, description, teamId, priority
   - stateId: use the **Backlog** state for the selected team
   - labelIds: auto-assign based on content (see references/ids.md for label IDs)
   - assigneeId: Will's user ID for the workspace

7. **Post-creation:** Show the created ticket URL and identifier.

### Step 2: Search for Tickets

1. **Gather search criteria** — use context from the conversation or get it using AskUserQuestion:
   - **Filter**: How would you like to filter?
   - Options should cover: by status, by team, by keyword, all recent

2. **Execute search** with `mcp__mise-tools__linear_{workspace}_list_issues` using query, teamId, stateId, limit 20.

3. **Present results** showing ticket identifier, title, status, and assignee.

### Step 3: Update Ticket Status

1. **Get current status** by fetching ticket details with `mcp__mise-tools__linear_{workspace}_get_issue`.

2. **Suggest the next status** based on workflow progression and get confirmation using AskUserQuestion:
   - **Status**: Move to the next stage?
   - Options: the logical next status(es) in the workflow, plus "different status" and "cancel"

   Tailor options based on current status (e.g., from Todo suggest Ready for Research; from In Research suggest Ready for Plan).

3. **Update** with `mcp__mise-tools__linear_{workspace}_update_issue` using the stateId from references/ids.md for the correct team.

### Step 4: Add Comments and Links

1. **Identify the ticket** from conversation context or ask.

2. **Format comments for quality:**
   - Keep comments concise (~10 lines) unless more detail needed
   - Focus on key insights, not mechanical summaries
   - Include file references with backticks

3. **Create the comment** with `mcp__mise-tools__linear_{workspace}_create_comment`.

4. **If adding links**, update the issue with `mcp__mise-tools__linear_{workspace}_update_issue` first, then add a comment noting what was linked.

## Guidelines

1. **Problem first**: All tickets MUST include a clear "problem to solve". If the user only gives implementation details, ask for the problem from a user perspective
2. **Concise but complete**: Keep tickets scannable, not walls of text
3. **Links via parameter**: Use the `links` parameter for external URLs, not just markdown links in description
4. **Ask, don't guess**: Ask for clarification on team/status rather than guessing
5. **Auto-label**: Apply labels automatically based on ticket content (see references/ids.md)
6. **Cross-reference**: For product management tasks, direct users to `/linear-pm`
7. **Workspace-aware**: Always use the correct workspace-namespaced MCP tools and the matching IDs from references/ids.md
