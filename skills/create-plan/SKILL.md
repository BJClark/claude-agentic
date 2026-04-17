---
name: create-plan
description: "Create detailed implementation plans through interactive research and iteration. Optionally syncs the plan to Linear with phase sub-issues. Use when a ticket or feature needs a plan before coding. Triggers on 'plan this ticket', 'make a plan for X', 'create an implementation plan'."
model: opus
allowed-tools: Read, Grep, Glob, Write, Edit, Task, AskUserQuestion, TodoWrite, Skill
argument-hint: [ticket-or-description]
---

# Implementation Plan

Create detailed implementation plans through an interactive, iterative process. Be skeptical, thorough, and work collaboratively with the user.

Ultrathink about the problem space, existing architecture, and implementation approach before starting.

**Input**: $ARGUMENTS

## Current Context

- **Branch**: !`git branch --show-current`
- **Last Commit**: !`git log -1 --oneline`
- **Modified Files**: !`git status --short`

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

## Linear Ticket Detection

If the input references a Linear ticket (e.g. `ENG-1234`, `PLAT-56`, or a `thoughts/shared/tickets/*.md` file):
1. Note the ticket identifier for later use in Step 7
2. If a ticket file exists, read it fully for context
3. If only an identifier is provided, fetch ticket details using Linear MCP tools (see [Linear reference IDs](../linear/references/ids.md) for workspace and team IDs)

## Process Steps

### Step 1: Context Gathering & Initial Analysis

1. **Read mentioned files FULLY** (no limit/offset)
2. **Spawn parallel research tasks**:
   - **codebase-locator**: Find related files
   - **codebase-analyzer**: Understand current implementation
   - **codebase-pattern-finder**: Find similar features
   - **artifacts-locator**: Find existing research, plans, and .jeff/ discovery artifacts
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

### Step 3: Technical Decisions

If the research surfaced technical choices that affect the plan, resolve them now before writing.

For each significant technical decision (e.g. library choice, data model design, API pattern, migration strategy), get a decision using AskUserQuestion:
- **[Decision topic]**: Present the trade-offs clearly
- Options should reflect the realistic choices discovered during research, with brief pros/cons for each
- Include an "I need more info" option for decisions the user isn't ready to make

Common technical decisions to watch for:
- **Architecture**: Monolith extension vs new service vs library extraction
- **Data model**: Schema design choices, storage engine, indexing strategy
- **API design**: REST vs GraphQL vs RPC, endpoint structure, versioning
- **Migration**: Big bang vs incremental, backwards compatibility approach
- **Dependencies**: Build vs buy, library selection, version constraints
- **Testing strategy**: Unit-heavy vs integration-heavy, test data approach

Record each decision and its rationale -- these go into the plan's "Key Discoveries" section.

If no technical decisions are needed, skip this step.

### Step 3.5: Spec-First Gating (Outside-In)

**Run this step only if research detected a BDD / outside-in test harness** (Cucumber, pytest-bdd, RSpec feature specs, Playwright+cucumber, Behave, Cypress cucumber-preprocessor, Capybara, etc.). If research explicitly confirmed none exists, skip to Step 4.

When a harness exists, the plan **must** be organized spec-first:

1. **Phase 0 is always "Write failing executable specifications"**. Author `.feature` files (or equivalent) covering the acceptance criteria before any production code is planned for later phases.
2. **Specs must fail for the right reason.** The plan must require running the new specs and documenting the expected failure mode — e.g. "missing step definition", "route not found", "assertion on not-yet-built behavior". Syntax errors, environment errors, or unrelated test failures do not count as "failing correctly" and must be fixed before Phase 0 closes.
3. **Every later phase's Automated Verification must include the exact spec command that goes green when that phase is done.** Use the runner command and tag/filter captured in research (e.g. `cucumber features/checkout.feature:42`, `pytest tests/acceptance -m checkout`).
4. **Final phase cannot close** until all new scenarios pass and the pre-existing suite shows no regressions.
5. **Record the spec↔phase mapping** in the plan's "Executable Specifications" section (see template).

Goal: every phase gate is backed by an executable behavior check, compounding verifiable knowledge of the system.

### Step 4: Plan Structure Development

1. Create initial outline with phases
2. Get feedback on structure before writing details

### Step 5: Detailed Plan Writing

Write plan to `thoughts/shared/plans/YYYY-MM-DD-description.md` or `plans/YYYY-MM-DD-description.md`

Use the template in [templates/plan-template.md](templates/plan-template.md).

Always separate success criteria into **Automated Verification** and **Manual Verification**.

Include a **Technical Decisions** section in the plan documenting choices made in Step 3 with their rationale.

### Step 6: Review & Iteration

1. Present draft location, ask for review
2. Iterate based on feedback
3. Continue refining until satisfied

### Step 7: Sync to Linear

If a Linear ticket was detected in the input, automatically invoke `/linear-ticket-status-sync [TICKET-ID] create-plan` using the Skill tool to sync the plan artifact and advance the ticket status.

## Guidelines

1. **Be Skeptical**: Question vague requirements, identify issues early, verify with code
2. **Be Interactive**: Don't write full plan in one shot, get buy-in at each step
3. **Be Thorough**: Read files completely, include file:line references, write measurable criteria
4. **Be Practical**: Incremental testable changes, consider migration/rollback
5. **No Open Questions in Final Plan**: Research or ask immediately
6. **Decide Before Writing**: Resolve technical decisions interactively before committing them to the plan, not after
7. **Linear Sync is Separate**: Linear sync is handled by `/linear-ticket-status-sync`, not this skill
8. **Spec-First When Possible**: If the codebase has an outside-in / BDD harness, specs lead implementation. Phase 0 writes failing scenarios that fail for the right reason; later phases close only when their designated specs pass. Always invest in executable behavior knowledge over ad-hoc verification.

## Common Patterns

**Database Changes**: Schema/migration -> Store methods -> Business logic -> API -> Clients
**New Features**: Research patterns -> Data model -> Backend -> API -> UI
**Refactoring**: Document current behavior -> Plan incremental changes -> Maintain backwards compat
