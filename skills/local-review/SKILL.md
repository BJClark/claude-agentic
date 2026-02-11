---
name: local-review
description: Set up worktree for reviewing colleague's branch with optional parallel review team
model: opus
context: fork
allowed-tools: Read, Grep, Glob, Bash, Write, Edit, AskUserQuestion, Task
argument-hint: [gh_username:branchName]
---

# Local Review

Set up a local review environment for a colleague's branch and optionally run a parallel review team.

**Input**: $ARGUMENTS

## Current Context

- **Branch**: !`git branch --show-current`
- **Last Commit**: !`git log -1 --oneline`
- **Remotes**: !`git remote -v | head -6`

## Worktree Setup

When invoked with `gh_username:branchName`:

1. **Parse input**: Extract GitHub username and branch name
2. **Extract ticket info**: Look for ticket numbers (e.g., `eng-1696`) for short directory name
3. **Set up remote and worktree**:
   - Check if remote exists: `git remote -v`
   - Add if needed: `git remote add USERNAME git@github.com:USERNAME/REPO`
   - Fetch: `git fetch USERNAME`
   - Create worktree: `git worktree add -b BRANCHNAME ~/wt/REPO/SHORT_NAME USERNAME/BRANCHNAME`
4. **Configure worktree**:
   - Copy Claude settings: `cp .claude/settings.local.json WORKTREE/.claude/`
   - Run setup if Makefile exists: `make -C WORKTREE setup`

If no parameter provided, ask for it in the format: `gh_username:branchName`

## Review Phase

After worktree setup, get review mode using AskUserQuestion:
- **Review mode**: Worktree is set up. How would you like to review?
- Options should include: Quick Diff Review, Agent Team Review (Recommended), Setup Only

Tailor recommendation based on the size of the diff.

### Quick Diff Review

Run `git diff main...HEAD` in the worktree and review the changes, providing feedback on:
- Code correctness and logic errors
- Security concerns
- Performance implications
- Test coverage gaps

### Agent Team Review (Experimental)

Create a team with 3 specialized reviewers:

```
Lead: Review Coordinator (you)
├─ Teammate 1: Security Reviewer — auth, input validation, injection, secrets, OWASP top 10
├─ Teammate 2: Performance Reviewer — N+1 queries, memory leaks, algorithmic complexity, caching
└─ Teammate 3: Test Coverage Reviewer — missing tests, edge cases, integration gaps, mocking quality
```

**Coordination rules:**
- All 3 reviewers start simultaneously on the same diff
- Each reviewer focuses exclusively on their domain
- Reviewers should message each other when they find cross-cutting concerns
- Lead synthesizes all findings into a single review summary

**Task setup:**
1. Get the diff: `git -C WORKTREE diff main...HEAD`
2. Create 3 parallel review tasks
3. Spawn reviewers, each with the diff and their review lens
4. Synthesize findings into severity-rated review summary

**Review output format:**
```
## Code Review Summary

### Critical (must fix)
- [finding with file:line reference]

### Warning (should fix)
- [finding with file:line reference]

### Info (consider)
- [finding with file:line reference]

### Positive
- [things done well]
```

Requires: `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` in settings or environment.

## Error Handling

- If worktree already exists, inform the user they need to remove it first
- If remote fetch fails, check if the username/repo exists
- If setup fails, provide the error but continue with the review
