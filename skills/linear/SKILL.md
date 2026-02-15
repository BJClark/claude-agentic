---
name: linear
description: "Manage Linear tickets - create, update, comment, search, and follow workflow patterns. Use when working with Linear issues or tickets."
model: opus
context: fork
allowed-tools: Read, Grep, Glob, Task, AskUserQuestion, Bash(linear *), Bash(gh *), TodoWrite
argument-hint: [action or ticket-id]
---

# Linear Ticket Management

Ultrathink about the team's workflow stages and how this request fits into the Triage -> Spec -> Research -> Plan -> Dev -> Review -> Done lifecycle. Consider what the user needs and the most efficient path to accomplish it.

Manage Linear tickets: create from thoughts documents, update status, add comments and links, search and filter. For product management (initiatives, milestones, project updates), use `/linear-pm` instead.

**Input**: $ARGUMENTS

## Current Context

- **Branch**: !`git branch --show-current 2>/dev/null || echo "N/A"`
- **Last Commit**: !`git log -1 --oneline 2>/dev/null || echo "N/A"`

## Initial Setup

First, verify that Linear MCP tools are available by checking if any `mcp__linear__` tools exist. If not, respond:
```
I need access to Linear tools to help with ticket management. Please run the `/mcp` command to enable the Linear MCP server, then try again.
```

## Initial Response

1. **If a specific action or ticket ID is provided**: Parse the input and begin the appropriate workflow
2. **If no parameters**:

Get the action using AskUserQuestion:
- **Action**: What would you like to do with Linear?
- Options should cover: Create ticket from thoughts document, Add comment to a ticket, Search for tickets, Update ticket status, Product management (initiatives/milestones) -> use /linear-pm

Tailor options based on available context. If a ticket was recently discussed, include that context.

Then wait for user input.

## Team Workflow & Status Progression

The team follows a specific workflow to ensure alignment before code implementation:

1. **Triage** -> All new tickets start here for initial review
2. **Spec Needed** -> More detail needed - problem and solution outline necessary
3. **Research Needed** -> Investigation required before plan can be written
4. **Research in Progress** -> Active investigation underway
5. **Research in Review** -> Research findings under review (optional)
6. **Ready for Plan** -> Research complete, needs implementation plan
7. **Plan in Progress** -> Actively writing the plan
8. **Plan in Review** -> Plan is written and under discussion
9. **Ready for Dev** -> Plan approved, ready for implementation
10. **In Dev** -> Active development
11. **Code Review** -> PR submitted
12. **Done** -> Completed

**Key principle**: Review and alignment happen at the plan stage (not PR stage) to move faster and avoid rework.

## Process Steps

### Step 1: Create Ticket from Thoughts Document

1. **Locate the document:**
   - If given a path, read it directly
   - If given a topic, search `thoughts/` using Grep to find relevant documents
   - If multiple matches, present the list and get selection using AskUserQuestion:
     - **Document**: Which thoughts document should this ticket be based on?
     - Options: the matching documents found

2. **Analyze the document content:**
   - Identify the core problem or feature
   - Extract key implementation details
   - Note referenced files or areas
   - Determine what stage the idea is at (ideation vs ready to implement)

3. **Get Linear workspace context:**
   - List teams: `mcp__linear__list_teams`
   - List projects: `mcp__linear__list_projects`

4. **Draft the ticket and present it:**
   ```
   ## Draft Linear Ticket

   **Title**: [Clear, action-oriented title]

   **Description**:
   ## Problem to solve
   [2-3 sentence summary]

   ## Key Details
   - [Important details from thoughts]
   - [Technical decisions or constraints]

   ## Implementation Notes (if applicable)
   [Technical approach or steps outlined]

   ## References
   - Source: `thoughts/[path]` ([View on GitHub](url))
   ```

5. **Get ticket configuration using AskUserQuestion:**
   - **Priority**: What priority for this ticket?
   - Options should cover: Urgent (critical blockers), High (important with deadlines), Medium (standard - default), Low (nice-to-have)

   Then get project confirmation using AskUserQuestion:
   - **Project**: Which project?
   - Options: default to M U L T I C L A U D E, plus other active projects found

6. **Get final confirmation using AskUserQuestion:**
   - **Create**: Ready to create this ticket?
   - Options should cover: create it, needs changes to description, cancel

7. **Create the ticket:**
   Use `mcp__linear__create_issue` with title, description, teamId, projectId, priority, stateId (Triage), labelIds (auto-assigned), and links.

8. **Post-creation:** Show the created ticket URL. Get next action using AskUserQuestion:
   - **Follow-up**: Ticket created. What next?
   - Options should cover: add sub-tasks, update thoughts doc with ticket reference, done

### Step 2: Add Comments and Links

1. **Identify the ticket:**
   - Use context from conversation to identify the relevant ticket
   - If uncertain, use `mcp__linear__get_issue` to confirm

2. **Format comments for quality:**
   - Keep comments concise (~10 lines) unless more detail needed
   - Focus on key insights, not mechanical summaries
   - Include file references with backticks and GitHub links
   - Wrap paths in backticks: `thoughts/allison/example.md`

3. **For comments with links:**
   First update the issue with the link via `mcp__linear__update_issue`, then create the comment via `mcp__linear__create_comment`.

4. **For links only:**
   Update the issue with the link and add a brief comment noting what was added.

### Step 3: Search for Tickets

1. **Gather search criteria** using AskUserQuestion if not specified:
   - **Filter**: How would you like to filter results?
   - Options should cover: by status, by project, by assignee, all recent

2. **Execute search** with `mcp__linear__list_issues` using query, teamId, projectId, stateId, limit 20.

3. **Present results** showing ticket ID, title, status, assignee, grouped by project if multiple.

### Step 4: Update Ticket Status

1. **Get current status** by fetching ticket details.

2. **Suggest the next status** based on workflow progression and get confirmation using AskUserQuestion:
   - **Status**: Move [ticket] to the next stage?
   - Options should cover: the logical next status(es) in the workflow, plus "different status" and "cancel"

   Tailor options based on current status (e.g., from Triage suggest Spec Needed; from Research in Progress suggest Ready for Plan or Research in Review).

3. **Update** with `mcp__linear__update_issue` and consider adding a comment explaining the change.

## Comment Quality Guidelines

Focus on extracting the most valuable information for a human reader:

- **Key insights over summaries**: What's the critical understanding?
- **Decisions and tradeoffs**: What approach was chosen and what it enables/prevents
- **Blockers resolved**: What was preventing progress and how it was addressed
- **State changes**: What's different now and what it means for next steps
- **Surprises or discoveries**: Unexpected findings that affect the work

Avoid mechanical lists of changes, restating what's obvious from diffs, or generic summaries.

## Guidelines

1. **Problem first**: All tickets MUST include a clear "problem to solve". If the user only gives implementation details, ask for the problem from a user perspective
2. **Concise but complete**: Keep tickets scannable, not walls of text
3. **Links via parameter**: Always use the `links` parameter for external URLs, not just markdown links in description
4. **Don't create from brainstorming**: Don't create tickets from early-stage brainstorming unless explicitly requested
5. **Ask, don't guess**: Ask for clarification on project/status rather than guessing
6. **Preserve sources**: Always link back to source material
7. **Auto-label**: Apply labels automatically based on ticket content (see [references/ids.md](references/ids.md))
8. **Cross-reference**: For product management tasks, direct users to `/linear-pm`

See [references/ids.md](references/ids.md) for team, label, workflow state, and user IDs.
