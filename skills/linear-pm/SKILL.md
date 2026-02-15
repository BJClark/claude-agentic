---
name: linear-pm
description: "Manage Linear product management - initiatives, milestones, project updates, and project labels. Use when working at the strategic layer above individual issues."
model: opus
context: fork
allowed-tools: Read, Grep, Glob, Task, AskUserQuestion, TodoWrite
argument-hint: [action or initiative-name]
---

# Linear Product Management

Ultrathink about the strategic hierarchy: Initiatives contain Projects, Projects contain Milestones and Issues. Consider where this request fits in the strategic picture and how it relates to existing initiatives and projects.

Manage Linear product management artifacts: initiatives, project milestones, project updates, and project labels. These operate at the strategic layer above individual issues.

For issue-level management (create tickets, update status, add comments), use `/linear` instead.

**Input**: $ARGUMENTS

## Current Context

- **Branch**: !`git branch --show-current 2>/dev/null || echo "N/A"`
- **Last Commit**: !`git log -1 --oneline 2>/dev/null || echo "N/A"`

## Initial Setup

First, verify that Linear MCP tools are available by checking if any `mcp__linear__` tools exist. If not, respond:
```
I need access to Linear tools to help with product management. Please run the `/mcp` command to enable the Linear MCP server, then try again.
```

## Initial Response

1. **If a specific action is provided**: Parse the input and begin the appropriate workflow
2. **If no parameters**:

Get the action using AskUserQuestion:
- **Action**: What product management task would you like to do?
- Options should cover: Create or edit an initiative, Create an initiative status update, Create or edit project milestones, Create a project update (progress report), Manage project labels, Search initiatives or projects

Then wait for user input.

## Hierarchy Reference

```
Initiatives (strategic goals / OKRs)
  +-- Projects (execution containers)
        |-- Milestones (key deliverables with target dates)
        |-- Project Updates (periodic progress reports)
        |-- Project Labels (categorization)
        +-- Issues (individual work items -- managed via /linear)
```

## Process Steps

### Step 1: Initiatives

#### Creating an Initiative

1. **Gather information** -- get details using AskUserQuestion:
   - **Initiative type**: What kind of initiative is this?
   - Options should cover: Strategic goal (Q-level OKR), Technical initiative (infrastructure/reliability), Product initiative (feature/growth), Other

2. **Draft and present:**
   ```
   ## Draft Initiative

   **Name**: [name]
   **Description**: [description]
   **Status**: [backlog/planned/active]
   **Projects**: [list or "none yet"]
   ```

3. **Get confirmation using AskUserQuestion:**
   - **Status**: What status should this initiative start in?
   - Options should cover: backlog, planned, active

4. **Get creation confirmation using AskUserQuestion:**
   - **Create**: Ready to create this initiative?
   - Options should cover: create it, needs changes, cancel

5. **Create** with `mcp__linear__create_initiative` and optionally add projects with `mcp__linear__add_project_to_initiative`.

#### Editing an Initiative

1. Fetch current state with `mcp__linear__get_initiative` or `mcp__linear__list_initiatives`
2. Present current values
3. Get changes using AskUserQuestion:
   - **Edit**: What would you like to change?
   - Options should cover: name, description, status, add/remove projects
4. Update with `mcp__linear__update_initiative`

### Step 2: Initiative Status Updates

Updates communicate strategic progress to leadership and stakeholders.

1. **Identify the initiative** -- search if needed, confirm with user.

2. **Get health status using AskUserQuestion:**
   - **Health**: What's the current health of this initiative?
   - Options should cover: On Track (progressing as planned), At Risk (potential issues, needs attention), Off Track (significant problems, needs intervention)

3. **Draft the update body** covering:
   - Progress since last update
   - Key wins or completions
   - Blockers or risks
   - Next steps

4. **Get confirmation using AskUserQuestion:**
   - **Publish**: Ready to publish this initiative update?
   - Options should cover: publish it, needs edits, cancel

5. **Create** with `mcp__linear__create_initiative_update`.

### Step 3: Project Milestones

Milestones mark key deliverables or checkpoints within a project timeline.

#### Creating a Milestone

1. **Identify the project** -- list projects if needed, get selection using AskUserQuestion:
   - **Project**: Which project should this milestone belong to?
   - Options: active projects found via `mcp__linear__list_projects`

2. **Gather details:**
   - Name (specific deliverable, not "Phase 1")
   - Description (what "done" means)
   - Target date (optional but recommended)

3. **Get confirmation using AskUserQuestion:**
   - **Create**: Create this milestone?
   - Options should cover: create it, needs changes, cancel

4. **Create** with `mcp__linear__create_project_milestone`.

#### Milestone Best Practices
- Represent meaningful deliverables, not arbitrary dates
- Each milestone should have clear completion criteria
- Keep count per project manageable (3-7 typical)
- Update target dates proactively when timelines shift

### Step 4: Project Updates

Periodic progress reports communicating status to stakeholders.

1. **Identify the project** -- list and select if not specified.

2. **Get health status using AskUserQuestion:**
   - **Health**: What's the current health of this project?
   - Options should cover: On Track (progressing as planned), At Risk (potential issues), Off Track (significant problems)

3. **Draft update** using this structure:
   ```markdown
   ## Progress
   - [Key accomplishment 1]
   - [Key accomplishment 2]

   ## Blockers
   - [Blocker or risk, if any]

   ## Next Steps
   - [What's coming next]
   - [Target dates if relevant]
   ```

4. **Quality guidelines:**
   - Focus on what matters to someone NOT in the daily work
   - Lead with the most important information
   - Be honest about health -- atRisk is better than a surprise offTrack later
   - Include specific examples and metrics where possible

5. **Get confirmation using AskUserQuestion:**
   - **Publish**: Ready to publish this project update?
   - Options should cover: publish it, needs edits, cancel

6. **Create** with `mcp__linear__create_project_update`.

### Step 5: Project Labels

Project labels categorize projects (distinct from issue labels managed via `/linear`).

1. **Get action using AskUserQuestion:**
   - **Label action**: What would you like to do with project labels?
   - Options should cover: add a label, remove a label, list current labels

2. **Execute** with `mcp__linear__add_project_label` or `mcp__linear__remove_project_label`.

Common label uses: Quarter (Q1-Q4), Team, Theme (Infrastructure, Growth, Reliability), Initiative alignment.

### Step 6: Search and List

- **List Initiatives**: `mcp__linear__list_initiatives` -- show name, status, project count
- **List Milestones**: `mcp__linear__list_project_milestones` -- show name, target date, completion
- **List Project Updates**: `mcp__linear__list_project_updates` -- show date, health, summary

## Guidelines

1. **Strategic focus**: This skill operates at the strategic layer. For individual tickets, use `/linear`
2. **Honest health reporting**: atRisk is better than a surprise offTrack later
3. **Scannable content**: Use headers and bullets, lead with the most important information
4. **Insights over summaries**: Focus on what matters, not mechanical lists
5. **Link to context**: Reference relevant tickets and documents
6. **Initiative health values**: `onTrack`, `atRisk`, `offTrack`
7. **All text fields support full Linear markdown**

See [references/ids.md](references/ids.md) for team and user IDs.
