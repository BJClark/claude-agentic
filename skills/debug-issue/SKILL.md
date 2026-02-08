---
name: debug-issue
description: Debug issues by investigating logs, database state, and git history
model: opus
context: fork
user-invocable: true
allowed-tools: Read, Grep, Glob, Bash, Task, AskUserQuestion
argument-hint: [issue-description-or-plan-path]
---

# Debug

Ultrathink about the problem space before investigating. Consider what could cause the symptom, what evidence would confirm or rule out each hypothesis, and which investigation paths to pursue first.

Investigate issues by examining logs, database state, and git history without editing files. Bootstrap a debugging session without consuming the primary window's context.

**Input**: $ARGUMENTS

## Current Context

- **Branch**: !`git branch --show-current`
- **Last Commit**: !`git log -1 --oneline`
- **Modified Files**: !`git status --short | head -10`

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

## Environment Information

**Logs** (if available):
- Application logs in project-standard locations
- Check for `.log` files or `logs/` directories

**Database** (if applicable):
- SQLite databases can be queried with `sqlite3`
- Check for `.db` files in project or home directory

**Git State**:
- Current branch, recent commits, uncommitted changes

**Service Status**:
- Check running processes relevant to the project

## Process Steps

### Step 1: Understand the Problem

1. **Read any provided context** (plan, ticket, error output)
2. **Quick state check**: git branch, recent commits, uncommitted changes

### Step 2: Investigate in Parallel

Spawn parallel Task agents:

**Task 1 - Check Recent Logs**: Find and analyze the most recent logs for errors, stack traces, repeated issues.

**Task 2 - Database State** (if applicable): Check schema, query recent data, look for stuck states.

**Task 3 - Git and File State**: Check status, recent commits, uncommitted changes, file permissions.

### Step 3: Present Findings

```markdown
## Debug Report

### What's Wrong
[Clear statement based on evidence]

### Evidence Found

**From Logs**:
- [Error/warning with timestamp]

**From Database** (if checked):
- [Finding]

**From Git/Files**:
- [Recent changes that might be related]

### Root Cause
[Most likely explanation]

### Next Steps

1. **Try This First**:
   [Specific command or action]

2. **If That Doesn't Work**:
   [Alternative approach]

### Outside My Reach
- Browser console errors
- External service state
- System-level issues

Would you like me to investigate something specific further?
```

## Guidelines

- **Focus on manual testing scenarios**: For debugging during implementation
- **Always require problem description**: Can't debug without knowing what's wrong
- **Read files completely**: No limit/offset
- **No file editing**: Pure investigation only
- **Guide back to user**: Some issues are outside reach
