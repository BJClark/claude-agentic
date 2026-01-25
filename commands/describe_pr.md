---
description: Generate comprehensive PR descriptions following repository templates
---

# Generate PR Description

Generate comprehensive pull request descriptions following the repository's standard template.

## Steps

### 1. Read PR Description Template

- Check if `.github/pull_request_template.md` or `docs/pr_template.md` exists
- If template found, read it to understand sections/requirements
- If no template, use standard format (see Template section below)

### 2. Identify PR to Describe

- Check current branch for PR: `gh pr view --json url,number,title,state 2>/dev/null`
- If no PR on current branch or on main/master, list open PRs: `gh pr list --limit 10 --json number,title,headRefName,author`
- Ask user which PR to describe

### 3. Check for Existing Description

- Check if `prs/{number}_description.md` or `thoughts/shared/prs/{number}_description.md` exists
- If exists, read it and inform user you'll update it
- Consider what changed since last description

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

Look for checklist items in "How to verify" section:
- **If command can be run** (`make check test`, `npm test`, etc.): Run it
  - Passes: Mark checked `- [x]`
  - Fails: Keep unchecked `- [ ]` with explanation
- **If requires manual testing**: Leave unchecked, note for user
- Document verification steps you couldn't complete

### 7. Generate Description

Fill out each template section thoroughly:
- Answer questions/sections based on analysis
- Be specific about problems solved and changes made
- Focus on user impact where relevant
- Include technical details in appropriate sections
- Write concise changelog entry
- Ensure all checklist items addressed

### 8. Save Description

- Write to `prs/{number}_description.md` or `thoughts/shared/prs/{number}_description.md` (if thoughts/ exists)
- Show user the generated description

### 9. Update PR

- Update PR description: `gh pr edit {number} --body-file [path-to-description]`
- Confirm update successful
- If verification steps unchecked, remind user to complete before merging

## Standard Template (if no template found)

```markdown
## What does this PR do?

[Brief description of the change]

## Why are we doing this?

[Problem being solved or feature being added]

## What changed?

- [Bullet point of major change 1]
- [Bullet point of major change 2]

## How to verify it

- [ ] Tests pass: `make test`
- [ ] Linting passes: `make lint`
- [ ] Manual verification: [specific steps]

## Breaking changes

[Any breaking changes, or "None"]

## Migration notes

[Any migration required, or "None"]
```

## Important Notes

- Works across different repositories - always read local template
- Be thorough but concise - descriptions should be scannable
- Focus on "why" as much as "what"
- Include breaking changes or migration notes prominently
- If PR touches multiple components, organize description accordingly
- Always attempt to run verification commands when possible
- Clearly communicate which verification steps need manual testing
