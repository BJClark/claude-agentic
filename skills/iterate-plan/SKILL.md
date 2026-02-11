---
name: iterate-plan
description: Iterate on existing implementation plans with thorough research and updates
model: opus
context: fork
allowed-tools: Read, Grep, Glob, Write, Edit, Task, AskUserQuestion, TodoWrite
argument-hint: [plan-file-path feedback]
---

# Iterate Implementation Plan

Update existing implementation plans based on user feedback. Be skeptical, thorough, and ensure changes are grounded in actual codebase reality.

Ultrathink about how the requested changes affect the plan's coherence, phasing, and success criteria.

**Input**: $ARGUMENTS

## Current Context

- **Branch**: !`git branch --show-current 2>/dev/null || echo "N/A"`
- **Last Commit**: !`git log -1 --oneline 2>/dev/null || echo "N/A"`
- **Modified Files**: !`(git status --short 2>/dev/null || echo "N/A") | head -10`

## Initial Response

1. **Parse input** for plan file path and requested changes/feedback

2. **Handle input scenarios**:

   **If NO plan file**:
   ```
   I'll help you iterate on an existing plan.
   Which plan to update? Provide path (e.g., `plans/2025-10-16-feature.md`)
   Tip: List recent plans with `ls -lt plans/ | head`
   ```

   **If plan file but NO feedback**:
   ```
   Found plan at [path]. What changes would you like?
   Examples:
   - "Add phase for migration handling"
   - "Update success criteria to include performance tests"
   - "Adjust scope to exclude feature X"
   - "Split Phase 2 into two phases"
   ```

   **If BOTH**: Proceed immediately to Step 1

## Process Steps

### Step 1: Read and Understand Current Plan

1. Read existing plan COMPLETELY (no limit/offset)
2. Understand requested changes
3. Identify if changes require codebase research

### Step 2: Research If Needed

**Only spawn research if changes require new technical understanding.**

1. Create research todo list using TodoWrite
2. Spawn parallel sub-tasks (codebase-locator, analyzer, pattern-finder)
3. Read new files FULLY
4. Wait for ALL sub-tasks

### Step 3: Present Understanding and Approach

Before making changes, confirm interpretation with the user.

### Step 4: Update the Plan

1. Read current plan file again (latest version)
2. Make requested updates: add/modify/remove phases, update criteria, adjust scope
3. Preserve plan metadata
4. Write updated plan back to same file

### Step 5: Present Changes

```
Updated plan at: [path]

Changes made:
- [Summary of change 1]
- [Summary of change 2]

Please review. Any further changes needed?
```

## Guidelines

1. **Validate changes with code**: Verify feasibility with actual codebase
2. **Maintain consistency**: Keep structure and formatting consistent
3. **Preserve context**: Don't remove important context unless asked
4. **Research when uncertain**: Spawn research tasks if unsure
5. **Confirm understanding**: Always present interpretation before changes

## Common Update Patterns

**Adding a Phase**: Research needs, identify files/patterns, write complete success criteria, insert in order
**Updating Success Criteria**: Ensure measurable, separate automated from manual, include commands
**Adjusting Scope**: Update "NOT Doing" section, remove implementation details, adjust phases
**Splitting a Phase**: Find natural break point, ensure each new phase has complete criteria
