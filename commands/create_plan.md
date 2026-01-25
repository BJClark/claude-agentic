---
description: Create detailed implementation plans through interactive research and iteration
model: opus
---

# Implementation Plan

Create detailed implementation plans through an interactive, iterative process. Be skeptical, thorough, and work collaboratively with the user to produce high-quality technical specifications.

## Initial Response

When invoked:

1. **If parameters provided**: Read any files completely (no limit/offset), then begin research
2. **If no parameters**:
```
I'll help you create a detailed implementation plan.

Please provide:
1. Task/ticket description (or file path to ticket)
2. Relevant context, constraints, or requirements
3. Links to related research or implementations

Tip: Invoke with a file directly: `/create_plan path/to/ticket.md`
```

Then wait for user input.

## Process Steps

### Step 1: Context Gathering & Initial Analysis

1. **Read mentioned files FULLY first** (tickets, docs, JSON):
   - Use Read tool WITHOUT limit/offset parameters
   - DO NOT spawn sub-tasks before reading these yourself
   - Ensure complete understanding before proceeding

2. **Spawn parallel research tasks**:
   - **codebase-locator**: Find all related files
   - **codebase-analyzer**: Understand current implementation
   - **codebase-pattern-finder**: Find similar features to model after
   - **thoughts-locator**: Find existing documentation (if thoughts/ exists)
   - **linear-ticket-reader**: Get full ticket details (if applicable)

3. **Read all identified files FULLY** into main context

4. **Analyze and verify**:
   - Cross-reference requirements with actual code
   - Identify discrepancies or assumptions
   - Determine true scope based on codebase reality

5. **Present informed understanding**:
   ```
   Based on my research, I understand we need to [summary].

   Found:
   - [Implementation detail with file:line]
   - [Relevant pattern or constraint]
   - [Potential complexity or edge case]

   Questions my research couldn't answer:
   - [Technical question requiring human judgment]
   - [Business logic clarification]
   - [Design preference affecting implementation]
   ```

### Step 2: Research & Discovery

1. **If user corrects misunderstanding**:
   - Spawn new research tasks to verify
   - Read specific files/directories mentioned
   - Only proceed after verifying facts yourself

2. **Create research todo list** using TodoWrite

3. **Spawn parallel sub-tasks**:
   - **codebase-locator**: Find specific files
   - **codebase-analyzer**: Understand implementation details
   - **codebase-pattern-finder**: Find similar features
   - **thoughts-locator/analyzer**: Historical context (if available)
   - **linear-searcher**: Find related tickets (if applicable)

4. **Wait for ALL sub-tasks**, then present findings:
   ```
   **Current State:**
   - [Key discovery about existing code]
   - [Pattern or convention to follow]

   **Design Options:**
   1. [Option A] - [pros/cons]
   2. [Option B] - [pros/cons]

   **Open Questions:**
   - [Technical uncertainty]
   - [Design decision needed]

   Which approach aligns best with your vision?
   ```

### Step 3: Plan Structure Development

1. **Create initial outline**:
   ```
   Proposed plan structure:

   ## Overview
   [1-2 sentence summary]

   ## Implementation Phases:
   1. [Phase name] - [what it accomplishes]
   2. [Phase name] - [what it accomplishes]
   3. [Phase name] - [what it accomplishes]

   Does this phasing make sense?
   ```

2. **Get feedback on structure** before writing details

### Step 4: Detailed Plan Writing

1. **Write plan** to `thoughts/shared/plans/YYYY-MM-DD-description.md` or `plans/YYYY-MM-DD-description.md`
   - Format: `YYYY-MM-DD-[TICKET-ID]-description.md`
   - Examples: `2025-01-08-ENG-1478-parent-child-tracking.md` or `2025-01-08-improve-error-handling.md`

2. **Use this template**:

````markdown
# [Feature/Task Name] Implementation Plan

## Overview
[Brief description of what we're implementing and why]

## Current State Analysis
[What exists now, what's missing, key constraints discovered]

## Desired End State
[Specification of desired end state and how to verify it]

### Key Discoveries:
- [Important finding with file:line reference]
- [Pattern to follow]
- [Constraint to work within]

## What We're NOT Doing
[Explicitly list out-of-scope items]

## Implementation Approach
[High-level strategy and reasoning]

## Phase 1: [Descriptive Name]

### Overview
[What this phase accomplishes]

### Changes Required:

#### 1. [Component/File Group]
**File**: `path/to/file.ext`
**Changes**: [Summary]

```[language]
// Specific code to add/modify
```

### Success Criteria:

#### Automated Verification:
- [ ] Migration applies cleanly: `make migrate`
- [ ] Unit tests pass: `make test-component`
- [ ] Type checking passes: `make typecheck`
- [ ] Linting passes: `make lint`
- [ ] Integration tests pass: `make test-integration`

#### Manual Verification:
- [ ] Feature works as expected in UI
- [ ] Performance acceptable under load
- [ ] Edge case handling verified
- [ ] No regressions in related features

**Implementation Note**: After automated verification passes, pause for manual confirmation before next phase.

---

## Phase 2: [Descriptive Name]
[Similar structure...]

---

## Testing Strategy

### Unit Tests:
- [What to test]
- [Key edge cases]

### Integration Tests:
- [End-to-end scenarios]

### Manual Testing Steps:
1. [Specific verification step]
2. [Another verification step]

## Performance Considerations
[Performance implications or optimizations needed]

## Migration Notes
[How to handle existing data/systems]

## References
- Original ticket: `[path]`
- Related research: `[path]`
- Similar implementation: `[file:line]`
````

### Step 5: Review & Iteration

1. **Present draft location**:
   ```
   Created implementation plan at: `[path]`

   Please review:
   - Are phases properly scoped?
   - Are success criteria specific enough?
   - Any technical details needing adjustment?
   - Missing edge cases or considerations?
   ```

2. **Iterate based on feedback**:
   - Add missing phases
   - Adjust technical approach
   - Clarify success criteria
   - Add/remove scope items

3. **Continue refining** until satisfied

## Important Guidelines

1. **Be Skeptical**: Question vague requirements, identify issues early, ask "why" and "what about", verify with code
2. **Be Interactive**: Don't write full plan in one shot, get buy-in at each step, allow course corrections
3. **Be Thorough**: Read files completely, research actual patterns, include file:line references, write measurable criteria
4. **Be Practical**: Incremental testable changes, consider migration/rollback, think about edge cases
5. **Track Progress**: Use TodoWrite for planning tasks
6. **No Open Questions in Final Plan**: Research or ask for clarification immediately, plan must be complete and actionable

## Success Criteria Guidelines

**Always separate into two categories:**

1. **Automated Verification**: Commands that can be run (`make test`, `npm run lint`), file existence, compilation/type checking
2. **Manual Verification**: UI/UX functionality, performance under real conditions, edge cases hard to automate

Format:
```markdown
#### Automated Verification:
- [ ] Database migration runs: `make migrate`
- [ ] All unit tests pass: `go test ./...`
- [ ] No linting errors: `make lint`

#### Manual Verification:
- [ ] New feature appears correctly in UI
- [ ] Performance acceptable with 1000+ items
- [ ] Error messages user-friendly
```

## Common Patterns

**Database Changes**: Schema/migration → Store methods → Business logic → API → Clients

**New Features**: Research existing patterns → Data model → Backend logic → API endpoints → UI

**Refactoring**: Document current behavior → Plan incremental changes → Maintain backwards compatibility → Migration strategy

## Sub-task Spawning Best Practices

1. **Spawn multiple tasks in parallel** for efficiency
2. **Each task focused** on specific area
3. **Provide detailed instructions**: What to search, which directories, what to extract, expected format
4. **Be specific about directories**: Include full path context
5. **Specify read-only tools** to use
6. **Request file:line references** in responses
7. **Wait for all tasks** before synthesizing
8. **Verify sub-task results**: Spawn follow-ups if unexpected, cross-check findings, don't accept incorrect results

## Example Interaction

```
User: /create_plan
Assistant: I'll help you create a detailed implementation plan...

User: Add parent-child tracking for Claude sub-tasks. See tickets/eng_1478.md
Assistant: Let me read that ticket completely first...
[Reads file fully]
Based on the ticket, I understand we need to track parent-child relationships...
[Interactive process continues...]
```
