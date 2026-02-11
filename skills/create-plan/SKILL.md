---
name: create-plan
description: Create detailed implementation plans through interactive research and iteration
model: opus
context: fork
allowed-tools: Read, Grep, Glob, Write, Edit, Task, AskUserQuestion, TodoWrite
argument-hint: [ticket-or-description]
---

# Implementation Plan

Create detailed implementation plans through an interactive, iterative process. Be skeptical, thorough, and work collaboratively with the user.

Ultrathink about the problem space, existing architecture, and implementation approach before starting.

**Input**: $ARGUMENTS

## Current Context

- **Branch**: !`git branch --show-current 2>/dev/null || echo "N/A"`
- **Last Commit**: !`git log -1 --oneline 2>/dev/null || echo "N/A"`
- **Modified Files**: !`(git status --short 2>/dev/null || echo "N/A") | head -10`

## Initial Response

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

1. **Read mentioned files FULLY** (no limit/offset)
2. **Spawn parallel research tasks**:
   - **codebase-locator**: Find related files
   - **codebase-analyzer**: Understand current implementation
   - **codebase-pattern-finder**: Find similar features
   - **thoughts-locator**: Find existing documentation (if thoughts/ exists)
3. **Read all identified files FULLY**
4. **Analyze and verify**: Cross-reference requirements with actual code
5. **Present informed understanding** with findings and unanswered questions

### Step 2: Research & Discovery

1. If user corrects misunderstanding, spawn new research to verify
2. Create research todo list using TodoWrite
3. Spawn parallel sub-tasks for targeted investigation
4. Wait for ALL sub-tasks, then present findings with design options

5. **Get structured decisions** using AskUserQuestion:
   - **Approach**: Which design option to pursue (from research)
   - **Priority**: Speed vs quality vs simplicity
   - **Scope**: Full vs MVP vs phased

   Tailor options based on actual discoveries. Don't use generic options.

### Step 3: Plan Structure Development

1. Create initial outline with phases
2. Get feedback on structure before writing details

### Step 4: Detailed Plan Writing

Write plan to `thoughts/shared/plans/YYYY-MM-DD-description.md` or `plans/YYYY-MM-DD-description.md`

Use the template in [templates/plan-template.md](templates/plan-template.md).

Always separate success criteria into **Automated Verification** and **Manual Verification**.

### Step 5: Review & Iteration

1. Present draft location, ask for review
2. Iterate based on feedback
3. Continue refining until satisfied

## Guidelines

1. **Be Skeptical**: Question vague requirements, identify issues early, verify with code
2. **Be Interactive**: Don't write full plan in one shot, get buy-in at each step
3. **Be Thorough**: Read files completely, include file:line references, write measurable criteria
4. **Be Practical**: Incremental testable changes, consider migration/rollback
5. **No Open Questions in Final Plan**: Research or ask immediately

## Common Patterns

**Database Changes**: Schema/migration -> Store methods -> Business logic -> API -> Clients
**New Features**: Research patterns -> Data model -> Backend -> API -> UI
**Refactoring**: Document current behavior -> Plan incremental changes -> Maintain backwards compat
