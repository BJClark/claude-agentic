---
name: analyze-project
description: "Analyze a Linear project's stories for completeness and gaps, improve them, and prepare all cards for research"
model: opus
context: fork
allowed-tools: Read, Grep, Glob, Task, AskUserQuestion, TodoWrite
argument-hint: [project-name or project-id]
disable-model-invocation: true
---

# Analyze Project

Ultrathink about the project as a whole: what is its starting state, what is its end state, and what work is needed to bridge the gap. Consider each story not in isolation but as part of a narrative that gets the project from where things are today to where they need to be. Identify missing chapters in that narrative.

Analyze a Linear project's stories for completeness and coverage gaps, improve story quality, create missing stories, and transition all cards to "Ready for Research".

**Input**: $ARGUMENTS

## Current Context

- **Branch**: !`git branch --show-current`
- **Last Commit**: !`git log -1 --oneline`

## Initial Response

1. **If a project identifier is provided**: Parse it and begin the workflow
2. **If no parameters**:
```
I'll help you analyze a Linear project for completeness and gaps.

Please provide a project name or ID.
```
Then wait for user input.

## Process Steps

### Step 1: Resolve Project & Load Context

1. Parse `$ARGUMENTS` for a project identifier (name or ID)
2. If the workspace is ambiguous, get it using AskUserQuestion:
   - **Workspace**: Which Linear workspace?
   - Options: Stellar, Kickplan, Meerkat
3. Use ToolSearch to load MCP tools for the selected workspace: `get_project`, `list_issues`, `get_issue`, `update_issue`, `create_issue`, `create_comment`, `get_initiative`, `list_projects`, `list_issue_statuses`
4. If the input is a name (not a UUID), use `list_projects` to find it
5. Fetch the project details via `get_project`
6. Fetch the parent initiative via `get_initiative` for strategic context
7. Fetch sibling projects in the initiative via `list_projects` for overlap/gap awareness
8. Read `skills/linear/references/ids.md` for workflow state IDs

Present project context:

```
## Project Context

**Project**: [name] — [description]
**Initiative**: [initiative name] — [initiative description]
**Sibling projects**: [list with brief descriptions]
**Stories**: [count] stories found
```

### Step 2: Analyze Current State & Define Scope

1. Fetch all issues in the project via `list_issues`
2. For each issue, fetch full details via `get_issue` (title, description, status, labels, comments)
3. Analyze the project holistically:
   - **Starting state**: What exists today? What is the current situation?
   - **End state**: When this project is done, what has changed? What has been delivered?
   - **Workstreams**: What are the major logical groupings of work?
4. Consider sibling projects — what do they cover that this project doesn't need to?

Present scope analysis:

```
## Project Scope Analysis

**Starting state**: [description of current situation]
**End state**: [description of what the project delivers]

**Workstreams**:
1. [Workstream name] — [brief description, N stories]
2. [Workstream name] — [brief description, N stories]
...

**Sibling project boundaries**: [what adjacent projects cover]
```

**Gate**: Get confirmation using AskUserQuestion:
- **Scope**: Does this scope summary accurately capture what this project is trying to achieve?
- Options should cover: Yes proceed to assessment, Needs adjustment, I want to clarify the end state

If the user adjusts, incorporate their feedback and re-present. Do not proceed until the scope is confirmed.

### Step 3: Assess Each Story

Evaluate every story against this project-level checklist:

| Criterion | What to look for |
|-----------|-----------------|
| **Problem statement** | Clear description of what this story addresses and why it matters for the project |
| **Acceptance criteria** | How do we know this story is done? What does success look like? |
| **Scope clarity** | Is it clear what's in and out of scope for this story? |
| **Dependencies** | Are upstream/downstream dependencies on other stories or projects identified? |
| **Fits the narrative** | Does this story clearly contribute to getting from start state to end state? |

Classify each story:
- **Ready** — clear enough for an engineer to begin research
- **Needs improvement** — has specific, identifiable gaps
- **Unclear** — fundamentally unclear purpose or scope within the project

### Step 4: Gap Analysis

With the full picture of all stories and the confirmed scope, identify:

1. **Missing stories** — work needed to get from start state to end state that no existing story covers. Think about what an engineer would need to build that isn't captured.
2. **Overlap** — stories that seem to duplicate effort or cover the same ground
3. **Ordering concerns** — stories that imply a sequence but don't express dependencies
4. **Scope creep** — stories that don't clearly serve the project's end state
5. **Cross-project gaps** — work that falls between this project and sibling projects in the initiative

### Step 5: Present Triage Report

Present everything as a structured report:

```
## Project Triage Report

### Scope
**Start state**: [what exists today]
**End state**: [what the project delivers]

### Story Assessment

**Ready** ([N] stories):
- [ID] — [Title]

**Needs Improvement** ([N] stories):
| Story | Issues |
|-------|--------|
| [ID] — [Title] | [specific gaps: missing AC, unclear scope, etc.] |

**Unclear** ([N] stories):
| Story | Issues |
|-------|--------|
| [ID] — [Title] | [why it's unclear] |

### Gaps Identified
1. **[Gap name]** — [description of missing work]
2. **[Gap name]** — [description of missing work]

### Overlaps & Concerns
- [Any overlaps, ordering issues, scope creep, cross-project gaps]

### Proposed Actions
- Improve [N] existing stories (fill gaps in descriptions/AC)
- Create [N] new stories (cover identified gaps)
- Flag [N] stories for discussion (unclear purpose or possible scope creep)
```

**Gate**: Get decision using AskUserQuestion:
- **Actions**: How would you like to proceed?
- Options should cover: Execute all proposed actions, Let me review each action individually, Adjust the plan first, Stop here

Tailor options based on the scale of proposed changes.

### Step 6: Execute Improvements

Based on user's decision from Step 5, execute the approved actions.

#### 6a. Improve Existing Stories

For stories classified as "Needs improvement":

1. Draft the updated description for each story, filling identified gaps
2. Present changes in batches of up to 5 stories:

```
## Proposed Updates (Batch [N])

### [ID] — [Title]
**Adding**:
- Problem statement: [drafted content]
- Acceptance criteria: [drafted content]
- [Other sections as needed]

### [ID] — [Title]
...
```

3. Get batch approval using AskUserQuestion:
   - **Batch [N]**: Apply these updates?
   - Options should cover: Apply all, Skip some, Edit before applying

4. For approved updates:
   - Fetch current description via `get_issue`
   - Append new sections (never overwrite original content)
   - Update via `update_issue`
   - Add comment: "Story enriched during project analysis: [brief note of what was added]"

5. Report progress every 5 items:
```
Progress: [8/15 stories updated]
```

#### 6b. Create New Stories

For gaps that need new stories:

1. Draft each new story with:
   - Title
   - Description with problem statement
   - Acceptance criteria
   - Which workstream it belongs to
   - Why it's needed (which gap it fills)

2. Present all new stories for approval:

```
## Proposed New Stories

### [Title]
**Fills gap**: [which gap from the triage report]
**Workstream**: [which workstream]
**Description**: [full draft]
**Acceptance criteria**: [list]
```

3. Get approval using AskUserQuestion:
   - **New stories**: Create these stories?
   - Options should cover: Create all, Let me pick which ones, Edit before creating

4. Create approved stories via `create_issue` with:
   - The project's team ID
   - Appropriate labels
   - Link to the project

#### 6c. Handle Flagged Stories

For stories flagged for discussion, present each and get a decision using AskUserQuestion:
- **[ID] — [Title]**: This story [reason for flag]. What should we do?
- Options should cover: Keep as-is, Rewrite it, Remove from project, Merge with another story

### Step 7: Transition All Cards to Ready for Research

1. Fetch the current list of all stories in the project (including newly created ones)
2. Identify which stories are NOT already at or past "Ready for Research" in the workflow
3. Look up the correct "Ready for Research" state ID from `skills/linear/references/ids.md` for the team and workspace

Present the transition plan:

```
## Status Transitions

**Will move to "Ready for Research"**:
- [ID] — [Title] (currently: [current status])
- [ID] — [Title] (currently: [current status])

**Already at or past "Ready for Research"**:
- [ID] — [Title] (currently: [current status])

**Total**: [N] stories to transition
```

**Gate**: Get confirmation using AskUserQuestion:
- **Confirm transitions**: Ready to move these cards to "Ready for Research"?
- Options should cover: Yes move them all, Let me exclude some, Cancel

Execute approved transitions via `update_issue` with the state ID.

### Step 8: Summary

```
## Project Analysis Complete

**Project**: [name]

| Action | Count |
|--------|-------|
| Stories assessed | [N] |
| Stories improved | [N] |
| New stories created | [N] |
| Moved to Ready for Research | [N] |

All cards are now in "Ready for Research" and ready for engineers to begin investigation.
```

If there are remaining concerns (flagged stories, cross-project gaps), list them clearly.

## Guidelines

1. **Think holistically**: Every assessment should consider the story in context of the whole project, not in isolation
2. **Start state to end state**: The project is a journey. Every story should be a clear step on that journey
3. **Don't rewrite stories**: Append sections to existing descriptions, never replace original content
4. **Batch interactions**: Use batched approvals (5 at a time) rather than per-story confirmation for efficiency
5. **Be specific about gaps**: "Missing error handling story" is better than "something might be missing"
6. **Respect scope boundaries**: Don't suggest stories that belong in sibling projects
7. **Forward-looking**: Assess whether the plan is clear enough, not whether the current implementation is correct
8. **No meta-questions**: Never ask "should I continue?" — use the defined gates. Never print questions as plain text — always use AskUserQuestion
9. **Progress visibility**: Report progress during batch operations so the user knows what's happening
