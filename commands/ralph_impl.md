---
description: Implement highest priority small Linear ticket with worktree setup
model: sonnet
---

## PART I - IF A TICKET IS MENTIONED

0c. use `linear` cli to fetch the selected item into thoughts with the ticket number - ./thoughts/shared/tickets/ENG-xxxx.md
0d. read the ticket and all comments to understand the implementation plan and any concerns

## PART I - IF NO TICKET IS MENTIOND

0.  read .claude/commands/linear.md
0a. fetch the top 10 priority items from linear in status "ready for dev" using the MCP tools, noting all items in the `links` section
0b. select the highest priority SMALL or XS issue from the list (if no SMALL or XS issues exist, EXIT IMMEDIATELY and inform the user)
0c. use `linear` cli to fetch the selected item into thoughts with the ticket number - ./thoughts/shared/tickets/ENG-xxxx.md
0d. read the ticket and all comments to understand the implementation plan and any concerns

## PART II - NEXT STEPS

think deeply

1. move the item to "in dev" using the MCP tools
1a. identify the linked implementation plan document from the `links` section
1b. if no plan exists, move the ticket back to "ready for spec" and EXIT with an explanation

think deeply about the implementation

2. set up worktree for implementation:
2a. use `/create_worktree` to set up a worktree for ENG-XXXX
2b. launch a Claude Code session in the worktree with: `/implement_plan` — once implementation is complete and tests pass, use `/commit` to create a commit, `/describe-pr` to create a PR, then add a comment to the Linear ticket with the PR link

3. after PR creation, if the completed ticket is the last issue blocking a project milestone, suggest marking the milestone complete via `/linear_pm`
3a. after significant implementation work, suggest creating a project update via `/linear_pm` to communicate progress

think deeply, use TodoWrite to track your tasks. When fetching from linear, get the top 10 items by priority but only work on ONE item - specifically the highest priority SMALL or XS sized issue.
