---
name: debug-issue
description: Debug issues by investigating logs, database state, and git history. Use when something is broken and you need to investigate the cause without editing files.
model: opus
user-invocable: true
allowed-tools: Read, Grep, Glob, Bash, Task, AskUserQuestion
argument-hint: [issue-description-or-plan-path]
hooks:
  TaskCompleted:
    - hooks:
        - type: command
          command: "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/verify-artifact-exists.sh"
          timeout: 10
          statusMessage: "Verifying debug findings..."
---

# Debug

Ultrathink about the problem space before investigating. Consider what could cause the symptom, what evidence would confirm or rule out each hypothesis, and which investigation paths to pursue first.

Investigate issues by examining logs, database state, and git history without editing files. Bootstrap a debugging session without consuming the primary window's context.

**Input**: $ARGUMENTS

## Current Context

- **Branch**: !`git branch --show-current`
- **Last Commit**: !`git log -1 --oneline`
- **Modified Files**: !`git status --short`

## Initial Response

When invoked WITH a plan/ticket file:
```
I'll help debug issues with [file name]. Let me understand the current state.

What specific problem are you encountering?
- What were you trying to test/implement?
- What went wrong?
- Any error messages?
```

When invoked WITHOUT parameters:
```
I'll help debug your current issue.

Please describe what's going wrong:
- What are you working on?
- What specific problem occurred?
- When did it last work?

I can investigate logs, database state, and recent changes.
```

## Process Steps

### Step 1: Understand the Problem

1. **Read any provided context** (plan, ticket, error output)
2. **Quick state check**: git branch, recent commits, uncommitted changes

### Step 2: Investigate

Spawn parallel investigation tasks and present findings as a debug report. See [references/investigation-playbook.md](references/investigation-playbook.md) for parallel task setup, report template, and Agent Team Mode for complex bugs.

### Step 3: Present Findings

Present a structured debug report with: what's wrong, evidence found, root cause analysis, and next steps.

For complex bugs with unclear root cause, consider offering Agent Team Mode (competing hypothesis investigation) — see the playbook for details.

## Guidelines

- **Focus on manual testing scenarios**: For debugging during implementation
- **Always require problem description**: Can't debug without knowing what's wrong
- **Read files completely**: No limit/offset
- **No file editing**: Pure investigation only
- **Guide back to user**: Some issues are outside reach
- **Team mode is optional**: Only offer when the root cause is genuinely unclear
