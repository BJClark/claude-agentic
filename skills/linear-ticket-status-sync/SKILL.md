---
name: linear-ticket-status-sync
description: "Sync skill artifacts (research docs, plans, implementation notes, QA results) to a Linear ticket and advance its status. Use after running research, plan, implement, or QA skills to keep the ticket current. Triggers on 'sync to Linear', 'update the ticket status', 'attach artifacts to ENG-1234'."
model: sonnet
allowed-tools: Read, Grep, Glob, Bash(git *), Task, AskUserQuestion, ToolSearch, mcp__mise-tools__linear_*
argument-hint: [ticket-id] [skill-name?]
---

# Linear Ticket Status Sync

Sync the output of a completed skill to a Linear ticket so the next skill in the chain has everything it needs from just the ticket ID.

**Input**: $ARGUMENTS

## Current Context

- **Branch**: !`git branch --show-current`
- **Last Commit**: !`git log -1 --oneline`
- **Modified Files**: !`git status --short`

## Initial Response

1. **If ticket ID + skill name provided**: Begin Step 1
2. **If only ticket ID provided**: Begin Step 1, auto-detect skill in Step 2
3. **If no parameters**:
```
I'll sync skill artifacts to a Linear ticket and advance its status.

Please provide:
1. Linear ticket identifier (e.g. ENG-1234, PLAT-56)
2. Optionally, which skill just ran (research-codebase, create-plan, implement-plan, describe-pr, qa)

Tip: /linear-ticket-status-sync ENG-1234 research-codebase
```
Then wait for user input.

## Process Steps

### Step 1: Fetch Ticket Context

1. Parse the ticket identifier from input.

2. Determine the workspace. If the identifier prefix maps clearly to a workspace, use it. Otherwise get workspace using AskUserQuestion:
   - **Workspace**: Which Linear workspace is this ticket in?
   - Options: Stellar, Kickplan, Meerkat

3. Use ToolSearch to load the MCP tools for the workspace: `+linear_{workspace} get_issue`, `+linear_{workspace} save_comment`, `+linear_{workspace} save_issue`, `+linear_{workspace} list_comments`.

4. Fetch the ticket using `mcp__mise-tools__linear_{workspace}_get_issue`. Record:
   - Current status (state name and type)
   - Team (for looking up state IDs)
   - Title and description
   - Existing comments (use `list_comments` to check what's already been synced)

5. Present the ticket state:
   ```
   Ticket: [ID] — [Title]
   Status: [Current Status]
   Team: [Team Name]
   ```

### Step 2: Identify Skill & Artifacts

If a skill name was provided in the input, use it. Otherwise, auto-detect.

**Auto-detection**: Look for artifacts created or modified recently. Check these locations in order using Glob:

1. `research/*-qa-*.md` — indicates `/qa` was run
2. `prs/*_description.md` or `thoughts/shared/prs/*_description.md` — indicates `/describe-pr`
3. `thoughts/shared/plans/*.md` or `plans/*.md` — indicates `/create-plan`
4. `research/*.md` (excluding qa-* and ddd/) — indicates `/research-codebase`
5. Check git for uncommitted code changes beyond docs — indicates `/implement-plan`

For each match, check the file's modification date. Prefer files modified today.

If multiple skills detected or none detected, get clarification using AskUserQuestion:
- **Skill**: Which skill's output should I sync to the ticket?
- Options should cover the detected possibilities, or if none: research-codebase, create-plan, implement-plan, describe-pr, qa

See [references/skill-artifact-map.md](references/skill-artifact-map.md) for the full mapping.

### Step 3: Check for Duplicate Sync

Review the ticket's existing comments (fetched in Step 1) to avoid posting duplicate content.

Look for comment patterns that indicate a previous sync:
- Comments starting with `## Research:` — research already synced
- Comments starting with `## Plan:` — plan already synced
- Comments starting with `## Implementation:` — implementation already synced
- Comments starting with `## PR:` — PR already synced
- Comments starting with `## QA:` — QA already synced

If a matching comment already exists, get guidance using AskUserQuestion:
- **Duplicate detected**: A [skill-type] sync comment already exists on this ticket. How should I proceed?
- Options: Replace it with updated content, Add new comment alongside it, Skip the comment (just update status), Cancel

### Step 4: Compose & Post Artifact Comment

Read the artifact file(s) identified in Step 2 and compose a structured comment for the ticket.

**For research-codebase**:
```markdown
## Research: [Topic from file frontmatter or first heading]

**Document**: `[relative path to research file]`

**Key findings**:
- [Finding 1 — from the research summary section]
- [Finding 2]
- [Finding 3]

**Open questions**: [from the research doc, or "None"]
```

**For create-plan**:
```markdown
## Plan: [Plan title from file]

**Document**: `[relative path to plan file]`

**Approach**: [1-2 sentence summary of the chosen approach]

**Phases**:
1. [Phase 1 name] — [brief description]
2. [Phase 2 name] — [brief description]
...

**Key decisions**: [list any major technical decisions from the plan]
```

**For implement-plan**:
```markdown
## Implementation: [Plan title]

**Plan**: `[relative path to plan file]`
**Branch**: `[current git branch]`

**Progress**:
- [x] Phase 1: [name] — completed
- [x] Phase 2: [name] — completed
- [ ] Phase 3: [name] — pending
...

**Changes**: [brief summary of what was implemented]
```

Parse the plan file's checkboxes to determine phase completion status.

**For describe-pr**:
```markdown
## PR: [PR title]

**PR**: [PR URL from `gh pr view --json url`]
**Branch**: `[current git branch]`

**Summary**: [1-2 sentence summary from the PR description]

**Key changes**:
- [Change 1]
- [Change 2]
```

Get the PR URL by running: check if there's a PR number in the artifact filename, then read the artifact to extract the PR URL or title. If needed, use the branch name to look it up.

**For qa**:
```markdown
## QA: [Ticket title]

**Report**: `[relative path to QA report]`

**Verdict**: [N] PASS / [N] FAIL / [N] PARTIAL / [N] BLOCKED

**Results**:
- [Criterion 1]: PASS/FAIL — [brief note]
- [Criterion 2]: PASS/FAIL — [brief note]
...

**Issues found**: [list or "None"]
```

Post the comment using `mcp__mise-tools__linear_{workspace}_save_comment`.

### Step 5: Advance Ticket Status

Determine the target status from the [skill-artifact-map](references/skill-artifact-map.md):

| Skill | Target Status |
|-------|--------------|
| research-codebase | Ready for Plan |
| create-plan | In Plan |
| implement-plan | In Progress |
| describe-pr | In Review |
| qa | Done (all pass) or no change (failures) |

**Rules**:
- Only advance forward. If the ticket is already at or past the target status, do not change it.
- For QA: only advance to Done if all criteria passed. If there are failures, leave the status unchanged.
- Use the correct state ID from [Linear reference IDs](../linear/references/ids.md) matching the ticket's team and workspace.

If advancing, update the ticket using `mcp__mise-tools__linear_{workspace}_save_issue` with the new `stateId`.

### Step 6: Confirm Results

Present the sync summary:

```
Sync complete for [TICKET-ID]:
- Posted [skill-type] comment with artifact summary
- Status: [previous status] -> [new status] (or "unchanged — already at [status]")
- Artifact: [path to file]

The ticket now has full context for the next step in the workflow.
```

## Guidelines

1. **Forward-only status**: Never move a ticket backward in the workflow. If the ticket is already past the target status, leave it.
2. **Concise comments**: Post summaries, not full file contents. The comment should link to the artifact file for details.
3. **No duplicates**: Always check existing comments before posting. Avoid cluttering tickets with repeated syncs.
4. **Workspace-aware**: Use the correct workspace-namespaced MCP tools and state IDs throughout.
5. **Idempotent**: Running this skill twice with the same inputs should not create duplicate comments or status changes.
6. **Cheap model**: This skill uses sonnet because it's a straightforward sync operation — no deep research or planning needed.
