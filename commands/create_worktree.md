---
description: Create worktree and launch implementation session for a plan
---

1. set up worktree for implementation:
1a. read `hack/create_worktree.sh` and create a new worktree with the Linear branch name: `./hack/create_worktree.sh ENG-XXXX BRANCH_NAME`

2. determine required data:

- branch name
- path to plan file (use relative path only)

**IMPORTANT PATH USAGE:**
- The thoughts/ directory is synced between the main repo and worktrees
- Always use ONLY the relative path starting with `thoughts/shared/...` without any directory prefix
- Example: `thoughts/shared/plans/fix-mcp-keepalive-proper.md` (not the full absolute path)
- This works because thoughts are synced and accessible from the worktree

3. confirm with the user:

```
Based on the input, I plan to create a worktree with the following details:

worktree path: ~/wt/ENG-XXXX
branch name: BRANCH_NAME
path to plan file: $FILEPATH

Launch prompt for the worktree session:
    /implement_plan at $FILEPATH — once complete and tests pass, use /commit, then /describe-pr, then add a comment to the Linear ticket with the PR link
```

Incorporate any user feedback then:

4. launch a Claude Code session in the worktree directory with the launch prompt above
