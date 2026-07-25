---
name: validate-plan
description: Validate implementation against plan, verify success criteria, identify issues. Delegates heavy verification to the qa-engineer subagent; surfaces the report inline.
model: sonnet
allowed-tools: Read, Grep, Glob, Bash, Task, AskUserQuestion, TodoWrite
argument-hint: [plan-file-path]
---

# Validate Plan

You are tasked with validating that an implementation plan was correctly executed. The heavy verification work (running checks, parallel research) is delegated to the `qa-engineer` subagent; only the report surfaces inline.

**Input**: $ARGUMENTS

## Step 1: Read the Plan

1. **Locate the plan**:
   - If plan path provided in $ARGUMENTS, use it
   - Otherwise, search `plans/` for recent plan files or ask user
2. **Read the plan file completely** — note all phases, checklist items, success criteria, and automated verification commands

## Step 2: Delegate Verification to qa-engineer

Spawn a `qa-engineer` Task subagent with this contract:

```
You are a senior staff-level code reviewer. Validate that the implementation plan was correctly executed.

Plan path: [PLAN_PATH]

Contract:
1. Read the plan file fully
2. For each phase: check completion status (look for - [x] checkmarks), verify actual code matches claimed completion
3. Run ALL automated verification commands listed in the plan's "Automated Verification" sections
4. Spawn parallel Tasks (researcher subagent) as needed to investigate specific areas:
   - Database/schema changes
   - Code changes per file
   - Test coverage
5. Generate a comprehensive validation report covering:
   - Phase-by-phase implementation status (pass/fail)
   - Automated verification results (each command + pass/fail)
   - Deviations from plan (list each)
   - Potential issues found
   - Manual testing steps required
6. Return the full validation report as your output — nothing else
```

## Step 3: Surface the Report

Present the qa-engineer's validation report inline. Add a brief executive summary at the top:

```markdown
## Validation Summary: [Plan Name]

**Overall status**: [PASS / PARTIAL / FAIL]
**Phases complete**: N of M
**Automated checks**: N passed, M failed

---
[qa-engineer full report below]
```

## Guidelines

1. **Be thorough but practical** — focus on what matters
2. **Run all automated checks** — don't skip verification commands
3. **Think critically** — question if the implementation truly solves the problem

## Validation Checklist

Always verify:
- [ ] All phases marked complete are actually done
- [ ] Automated tests pass
- [ ] Code follows existing patterns
- [ ] No regressions introduced
- [ ] Error handling is robust
- [ ] Documentation updated if needed
- [ ] Manual test steps are clear

## Relationship to Other Skills

Recommended workflow:
1. `/implement-plan` — Execute the implementation
2. `/commit` — Create atomic commits for changes
3. `/validate-plan` — Verify implementation correctness (this skill)
4. `/describe-pr` — Generate PR description
