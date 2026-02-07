---
name: implement-plan
description: Implement technical plans from thoughts/shared/plans with automated verification and phase gates
model: opus
context: fork
allowed-tools: Read, Edit, Write, Grep, Glob, Bash, TodoWrite, AskUserQuestion
argument-hint: [plan-file-path]
---

# Implement Plan

Implement the approved technical plan at: **$ARGUMENTS**

## Current Context

- **Branch**: !`git branch --show-current`
- **Last Commit**: !`git log -1 --oneline`
- **Modified Files**: !`git status --short | head -10`

## Getting Started

When given a plan path:
- Read the plan completely and check for existing checkmarks (- [x])
- Read the original ticket and all files mentioned in the plan
- **Read files fully** - never use limit/offset parameters
- Think deeply about how the pieces fit together
- Create a todo list to track your progress
- Start implementing if you understand what needs to be done

If no plan path provided, ask for one.

## Implementation Philosophy

Plans are carefully designed, but reality can be messy. Your job is to:
- Follow the plan's intent while adapting to what you find
- Implement each phase fully before moving to the next
- Verify your work makes sense in the broader codebase context
- Update checkboxes in the plan as you complete sections

When things don't match the plan exactly, think about why and communicate clearly.

If you encounter a mismatch:
- STOP and think deeply about why the plan can't be followed
- Present the issue clearly:
  ```
  Issue in Phase [N]:
  Expected: [what the plan says]
  Found: [actual situation]
  Why this matters: [explanation]

  How should I proceed?
  ```

## Verification Approach

After implementing a phase:
- Run the success criteria checks (usually `make check test` covers everything)
- Fix any issues before proceeding
- Update your progress in both the plan and your todos
- Check off completed items in the plan file itself using Edit

### Phase Gate

After completing all automated verification for a phase, use AskUserQuestion to gate progress:

```
Phase [N] Complete - Ready for Manual Verification

Automated verification passed:
- [List automated checks that passed]

Please perform the manual verification steps listed in the plan:
- [List manual verification items from the plan]
```

Then ask:

<invoke name="AskUserQuestion">
  questions: [{
    "question": "Phase [N] automated checks passed. How would you like to proceed?",
    "header": "Phase Gate",
    "multiSelect": false,
    "options": [
      {
        "label": "Proceed to Next Phase",
        "description": "Manual verification looks good, continue implementation"
      },
      {
        "label": "Fix Issues First",
        "description": "I found problems during manual testing that need attention"
      },
      {
        "label": "Review Changes",
        "description": "I want to review the changes before moving on"
      }
    ]
  }]
</invoke>

If instructed to execute multiple phases consecutively, skip the pause until the last phase. Otherwise, assume you are just doing one phase.

Do not check off items in the manual testing steps until confirmed by the user.

## If You Get Stuck

When something isn't working as expected:
- First, make sure you've read and understood all the relevant code
- Consider if the codebase has evolved since the plan was written
- Present the mismatch clearly and ask for guidance

Use sub-tasks sparingly - mainly for targeted debugging or exploring unfamiliar territory.

## Resuming Work

If the plan has existing checkmarks:
- Trust that completed work is done
- Pick up from the first unchecked item
- Verify previous work only if something seems off

Remember: You're implementing a solution, not just checking boxes. Keep the end goal in mind and maintain forward momentum.
