---
description: Manage Linear initiatives, project milestones, project updates, and project labels
---

# Linear - Product Management

You are tasked with managing Linear product management artifacts: initiatives, project milestones, project updates, and project labels. These operate at the strategic layer above individual issues.

> For issue-level management (create tickets, update status, add comments), use `/linear` instead.

## Initial Setup

First, verify that Linear MCP tools are available by checking if any `mcp__linear__` tools exist. If not, respond:
```
I need access to Linear tools to help with product management. Please run the `/mcp` command to enable the Linear MCP server, then try again.
```

If tools are available, respond based on the user's request:

### For general requests:
```
I can help you with Linear product management. What would you like to do?
1. Create or edit an initiative
2. Create an initiative status update
3. Create or edit project milestones
4. Create a project update (progress report)
5. Manage project labels
6. Search initiatives or projects
```

Then wait for the user's input.

## Concepts

### Hierarchy
```
Initiatives (strategic goals / OKRs)
  └── Projects (execution containers)
        ├── Milestones (key deliverables with target dates)
        ├── Project Updates (periodic progress reports)
        ├── Project Labels (categorization)
        └── Issues (individual work items — managed via /linear)
```

### When to use what
- **Initiative**: A strategic goal spanning multiple projects (e.g. "Launch v2 platform", "Reduce p95 latency by 50%")
- **Project Milestone**: A key deliverable or checkpoint within a project (e.g. "API complete", "Beta launch")
- **Project Update**: A periodic progress report on a project — what's done, what's blocked, what's next
- **Project Label**: Categorize projects by theme, team, quarter, or initiative

## Action-Specific Instructions

### 1. Initiatives

#### Creating an Initiative

1. **Gather information:**
   - Name (clear, goal-oriented — e.g. "Q1 Platform Reliability" not "Fix stuff")
   - Description (what success looks like, why it matters)
   - Status (backlog, planned, active, completed, paused)
   - Projects to include (optional — can add later)

2. **Draft and confirm with user:**
   ```
   ## Draft Initiative

   **Name**: [name]
   **Description**: [description]
   **Status**: [status]
   **Projects**: [list or "none yet"]

   Does this look right? Any changes before I create it?
   ```

3. **Create the initiative:**
   ```
   mcp__linear__create_initiative with:
   - name: [name]
   - description: [description]
   - status: [status]
   ```

4. **Add projects if specified:**
   ```
   mcp__linear__add_project_to_initiative with:
   - initiativeId: [initiative ID]
   - projectId: [project ID]
   ```

#### Editing an Initiative

1. Fetch current state with `mcp__linear__get_initiative` or `mcp__linear__list_initiatives`
2. Show current values to user
3. Update with `mcp__linear__update_initiative`

#### Linking Projects to Initiatives

Use `mcp__linear__add_project_to_initiative` and `mcp__linear__remove_project_from_initiative` to manage the initiative-project relationship.

### 2. Initiative Status Updates

Initiative updates communicate strategic progress to leadership and stakeholders.

1. **Gather information:**
   - Initiative to update (search if needed)
   - Health status: onTrack, atRisk, or offTrack
   - Body text covering:
     - Progress since last update
     - Key wins or completions
     - Blockers or risks
     - Next steps

2. **Quality guidelines** (same principles as ticket comments):
   - **Key insights over summaries**: What's the critical takeaway?
   - **Decisions and tradeoffs**: What was chosen and why
   - **Blockers and risks**: What could derail progress
   - **Next steps**: What's coming and when
   - Keep it scannable — use headers and bullets
   - Avoid mechanical lists of changes

3. **Create the update:**
   ```
   mcp__linear__create_initiative_update with:
   - initiativeId: [initiative ID]
   - health: [onTrack|atRisk|offTrack]
   - body: [formatted markdown body]
   ```

### 3. Project Milestones

Milestones mark key deliverables or checkpoints within a project timeline.

#### Creating a Milestone

1. **Gather information:**
   - Project to add milestone to (list projects if needed)
   - Name (specific deliverable — e.g. "API v2 endpoints complete" not "Phase 1")
   - Description (what "done" means for this milestone)
   - Target date (optional but recommended)
   - Sort order (optional — for ordering within the project)

2. **Confirm with user:**
   ```
   ## Draft Milestone

   **Project**: [project name]
   **Name**: [milestone name]
   **Target date**: [date or "not set"]
   **Description**: [description]

   Create this milestone?
   ```

3. **Create the milestone:**
   ```
   mcp__linear__create_project_milestone with:
   - projectId: [project ID]
   - name: [name]
   - description: [description]
   - targetDate: [ISO date, if provided]
   - sortOrder: [number, if provided]
   ```

#### Editing a Milestone

1. List milestones for the project
2. Show current values
3. Update with `mcp__linear__update_project_milestone`

#### Milestone Best Practices
- Milestones should represent meaningful deliverables, not arbitrary dates
- Each milestone should have clear completion criteria in the description
- Keep milestone count per project manageable (3-7 is typical)
- Update target dates proactively when timelines shift

### 4. Project Updates

Project updates are periodic progress reports that communicate status to stakeholders.

#### Creating a Project Update

1. **Identify the project:**
   - If not specified, list projects and ask user to select
   - Fetch current project state for context

2. **Gather update content:**
   - Health status: onTrack, atRisk, or offTrack
   - Body covering:
     - What was accomplished since last update
     - Current blockers or risks
     - What's planned next
     - Any milestone completions or target date changes

3. **Quality guidelines:**
   - Focus on what matters to someone NOT in the daily work
   - Lead with the most important information
   - Be honest about health — atRisk is better than a surprise offTrack later
   - Include specific examples and metrics where possible
   - Link to relevant tickets or documents

4. **Create the update:**
   ```
   mcp__linear__create_project_update with:
   - projectId: [project ID]
   - health: [onTrack|atRisk|offTrack]
   - body: [formatted markdown body]
   ```

#### Project Update Template
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

### 5. Project Labels

Project labels categorize projects (distinct from issue labels managed via `/linear`).

#### Adding Labels to a Project

1. List available project labels if needed
2. Add label:
   ```
   mcp__linear__add_project_label with:
   - projectId: [project ID]
   - labelId: [label ID]
   ```

#### Removing Labels from a Project

```
mcp__linear__remove_project_label with:
- projectId: [project ID]
- labelId: [label ID]
```

#### Common Label Uses
- Quarter: Q1, Q2, Q3, Q4
- Team: Engineering, Design, Product
- Theme: Infrastructure, Growth, Reliability
- Initiative alignment: links projects to strategic themes

### 6. Searching and Listing

#### List Initiatives
```
mcp__linear__list_initiatives
```
Show: name, status, project count, last updated.

#### List Project Milestones
```
mcp__linear__list_project_milestones with:
- projectId: [project ID]
```
Show: name, target date, completion status.

#### List Project Updates
```
mcp__linear__list_project_updates with:
- projectId: [project ID]
```
Show: date, health status, summary.

## Important Notes

- Initiative and project update health values are: `onTrack`, `atRisk`, `offTrack`
- All text fields support full Linear markdown
- When creating updates, focus on insights not mechanical summaries (see quality guidelines)
- Tool names above are based on expected conventions — if a tool name doesn't work, check available `mcp__linear__` tools and adapt
- For issue-level work (tickets, comments, status changes), use `/linear`
- Tag users in descriptions using `@[name](ID)` format

## Shared Reference IDs

These are the same IDs used by `/linear`:

### Engineering Team
- **Team ID**: `6b3b2115-efd4-4b83-8463-8160842d2c84`

### Linear User IDs
- allison: b157f9e4-8faf-4e7e-a598-dae6dec8a584
- dex: 16765c85-2286-4c0f-ab49-0d4d79222ef5
- sundeep: 0062104d-9351-44f5-b64c-d0b59acb516b
