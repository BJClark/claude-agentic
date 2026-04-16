---
name: analyze-project
description: "Analyze a Linear project's stories for completeness and gaps, improve them, and move cards to Ready for Research. Use when starting a Linear project and needing to audit story quality before research or planning. Triggers on 'analyze this project', 'audit the stories', 'prep project for research'."
model: sonnet
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

**Gate**: Get confirmation using AskUserQuestion:
- **Scope**: Does this scope summary accurately capture what this project is trying to achieve?
- Options should cover: Yes proceed to assessment, Needs adjustment, I want to clarify the end state

### Step 3: Assess Stories, Identify Gaps, and Execute

See [references/analysis-criteria.md](references/analysis-criteria.md) for the detailed story assessment checklist, gap analysis dimensions, triage report template, and story improvement/creation process.

Follow the criteria to:
1. Assess every story against the project-level checklist
2. Perform gap analysis across all 5 dimensions
3. Present the triage report with proposed actions
4. Execute approved improvements (batch updates, new stories, flagged story decisions)
5. Transition all cards to "Ready for Research"

### Step 4: Summary

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
