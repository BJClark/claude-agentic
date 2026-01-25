---
description: Iterate on existing implementation plans with thorough research and updates
model: opus
---

# Iterate Implementation Plan

Update existing implementation plans based on user feedback. Be skeptical, thorough, and ensure changes are grounded in actual codebase reality.

## Initial Response

When invoked:

1. **Parse input to identify**:
   - Plan file path (e.g., `plans/2025-10-16-feature.md`)
   - Requested changes/feedback

2. **Handle input scenarios**:

   **If NO plan file**:
   ```
   I'll help you iterate on an existing plan.
   Which plan to update? Provide path (e.g., `plans/2025-10-16-feature.md`)
   Tip: List recent plans with `ls -lt plans/ | head`
   ```
   Wait for input, then re-check for feedback.

   **If plan file but NO feedback**:
   ```
   Found plan at [path]. What changes would you like?
   Examples:
   - "Add phase for migration handling"
   - "Update success criteria to include performance tests"
   - "Adjust scope to exclude feature X"
   - "Split Phase 2 into two phases"
   ```
   Wait for input.

   **If BOTH plan AND feedback**:
   - Proceed immediately to Step 1

## Process Steps

### Step 1: Read and Understand Current Plan

1. **Read existing plan COMPLETELY** (no limit/offset)
2. **Understand requested changes**: What to add/modify/remove
3. **Identify if changes require codebase research**

### Step 2: Research If Needed

**Only spawn research if changes require new technical understanding.**

If user feedback requires understanding new code patterns or validating assumptions:

1. **Create research todo list** using TodoWrite
2. **Spawn parallel sub-tasks**:
   - **codebase-locator**: Find relevant files
   - **codebase-analyzer**: Understand implementation
   - **codebase-pattern-finder**: Find similar patterns
   - **thoughts-locator/analyzer**: Related research/decisions (if available)
3. **Read new files FULLY** into main context
4. **Wait for ALL sub-tasks** before proceeding

### Step 3: Present Understanding and Approach

Before making changes:
```
Based on your feedback, I understand you want to:
- [Change 1 with detail]
- [Change 2 with detail]

My research found:
- [Relevant technical detail with file:line]
- [Pattern or constraint discovered]

I'll update the plan to:
1. [Specific modification to Phase X]
2. [New section/phase to add]
3. [Item to remove or adjust]

Does this approach match your intent?
```

### Step 4: Update the Plan

1. **Read current plan file again** to ensure latest version
2. **Make the requested updates**:
   - Add/modify/remove phases as discussed
   - Update success criteria
   - Adjust scope or implementation approach
   - Maintain plan structure and formatting
   - Keep file:line references current
3. **Preserve the plan's metadata** (date, ticket reference, etc.)
4. **Write updated plan** back to same file

### Step 5: Present Changes

```
Updated plan at: [path]

Changes made:
- [Summary of change 1]
- [Summary of change 2]
- [Summary of change 3]

Key updates:
- [Important modification with reasoning]
- [New consideration added]

Please review the updated plan. Any further changes needed?
```

## Important Guidelines

1. **Validate Changes with Code**: If adding new technical requirements, verify they're feasible with actual codebase
2. **Maintain Consistency**: Keep plan structure, formatting, and style consistent
3. **Preserve Context**: Don't remove important context unless explicitly asked
4. **Research When Uncertain**: If unsure about technical feasibility, spawn research tasks
5. **Confirm Understanding**: Always present your interpretation before making changes
6. **Track Progress**: Use TodoWrite for research tasks

## Common Update Patterns

**Adding a Phase**:
- Research what the phase needs to accomplish
- Identify files to modify and patterns to follow
- Write complete success criteria (automated + manual)
- Insert in logical order within plan

**Updating Success Criteria**:
- Ensure criteria are measurable
- Separate automated from manual verification
- Include specific commands or test scenarios

**Adjusting Scope**:
- Update "What We're NOT Doing" section
- Remove implementation details for out-of-scope items
- Adjust phases to reflect new boundaries

**Splitting a Phase**:
- Identify natural break point
- Ensure each new phase has complete success criteria
- Maintain dependencies between phases

## Example Interaction

```
User: /iterate_plan plans/api-refactor.md - add phase for database migration
Assistant: Let me read the current plan...
[Reads plan]
I understand you want to add a database migration phase. Let me research the migration patterns...
[Spawns codebase-pattern-finder to find existing migrations]
Based on my research, I'll add Phase 1: Database Migration that creates the new schema before the refactoring work. Does this match your intent?
User: Yes, proceed
Assistant: [Updates plan]
Updated plan at plans/api-refactor.md
Added Phase 1: Database Migration with schema changes, rollback strategy, and success criteria
```
