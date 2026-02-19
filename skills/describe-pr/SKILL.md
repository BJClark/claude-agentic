---
name: describe-pr
description: Generate comprehensive PR descriptions following repository templates
context: fork
allowed-tools: Read, Grep, Glob, Bash(gh *), Bash(git *), Write, Edit, AskUserQuestion
argument-hint: [pr-number]
---

# Generate PR Description

Generate comprehensive pull request descriptions following the repository's standard template.

**Input**: $ARGUMENTS

## Current Context

- **Branch**: !`git branch --show-current`
- **Last Commit**: !`git log -1 --oneline`
- **Modified Files**: !`git status --short`

## Steps

### 1. Read PR Description Template

- Check for `.github/pull_request_template.md` or `docs/pr_template.md`
- If found, read it to understand sections/requirements
- If no template, use the default in [templates/pr-template.md](templates/pr-template.md)

### 2. Identify PR to Describe

- Check current branch for PR: `gh pr view --json url,number,title,state 2>/dev/null`
- If no PR on current branch, list open PRs: `gh pr list --limit 10 --json number,title,headRefName,author`
- Ask user which PR to describe

### 3. Check for Existing Description

- Check for `prs/{number}_description.md` or `thoughts/shared/prs/{number}_description.md`
- If exists, read it and inform user you'll update it

### 4. Gather PR Information

- Full diff: `gh pr diff {number}`
- Commit history: `gh pr view {number} --json commits`
- Base branch: `gh pr view {number} --json baseRefName`
- PR metadata: `gh pr view {number} --json url,title,number,state`

If error about no default remote: instruct user to run `gh repo set-default`

### 5. Analyze Changes Thoroughly

- Read entire diff carefully
- For context, read referenced files not shown in diff
- Understand purpose and impact of each change
- Identify user-facing changes vs internal implementation
- Look for breaking changes or migration requirements

### 6. Handle Verification Requirements

- **If command can be run** (`make check test`, etc.): Run it and mark result
- **If requires manual testing**: Leave unchecked, note for user
- Document verification steps you couldn't complete

### 7. Generate Description

Fill out each template section thoroughly:
- Be specific about problems solved and changes made
- Focus on user impact where relevant
- Include technical details in appropriate sections
- Write concise changelog entry
- Ensure all checklist items addressed

### 8. Save Description

Write to `prs/{number}_description.md` or `thoughts/shared/prs/{number}_description.md`

### 9. Update PR

- Update PR: `gh pr edit {number} --body-file [path-to-description]`
- Confirm update successful
- If verification steps unchecked, remind user

### 10. Linear Ticket Status Reminder

After updating the PR, check if the branch name contains a Linear ticket reference (e.g., `ENG-1234`, `eng-1234`, or similar patterns):
- Extract the ticket identifier from the branch name
- Remind the user: "If you haven't already, move **[ticket-id]** to **In Review** status in Linear to reflect the PR submission."
- If running as part of a larger workflow (e.g., called from `/ralph_impl` or `/create_worktree`), the calling command should handle the status update via MCP tools.

## Guidelines

- Works across different repositories — always read local template
- Be thorough but concise — descriptions should be scannable
- Focus on "why" as much as "what"
- Include breaking changes or migration notes prominently
- Always attempt to run verification commands when possible
