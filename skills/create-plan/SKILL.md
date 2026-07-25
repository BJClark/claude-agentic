---
name: create-plan
description: "Create detailed implementation plans through interactive research and iteration. Optionally syncs the plan to Linear with phase sub-issues. Use when a ticket or feature needs a plan before coding. Triggers on 'plan this ticket', 'make a plan for X', 'create an implementation plan'."
model: opus
allowed-tools: Read, Grep, Glob, Write, Edit, Task, AskUserQuestion, TodoWrite, Skill
argument-hint: [ticket-or-description]
---

You are operating in **Architect mode** — your role is to design a phased implementation plan with the user.

# Implementation Plan

Create detailed implementation plans through an interactive, iterative process. Be skeptical, thorough, and work collaboratively with the user.

Ultrathink about the problem space, existing architecture, and implementation approach before starting. Default to **vertical slices**: each phase ships a thin end-to-end user-visible capability, not a layer of the stack. Horizontal phasing (schema first, then services, then API, then UI) defers integration risk and produces non-shippable intermediate states.

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
   - **scout**: Find related files
   - **researcher** (code-investigation mode): Understand current implementation; find similar features — for at least one, return the **full vertical path** (e.g. DB migration → repository → service → API endpoint → UI/consumer) so new phases can be modeled on an existing end-to-end slice
   - **researcher** (artifact-research mode): Find existing research, plans, and .jeff/ discovery artifacts
3. **Read all identified files FULLY**
4. **Analyze and verify**: Cross-reference requirements with actual code
5. **Present informed understanding** with findings and unanswered questions

### Step 2: Research & Discovery

1. If user corrects misunderstanding, spawn new research to verify
2. Create research todo list using TodoWrite
3. Spawn at most 2 additional targeted sub-tasks, and only when a question needs a fan-out search across files you haven't already read. Otherwise investigate inline.
4. Wait for ALL sub-tasks, then present findings with design options

5. **Get structured decisions** using AskUserQuestion:
   - **Approach**: Which design option to pursue (from research)
   - **Priority**: Speed vs quality vs simplicity
   - **Scope**: Full vs MVP vs phased

   Tailor options based on actual discoveries. Don't use generic options.

### Step 3: Technical Decisions

If the research surfaced technical choices that affect the plan, resolve them now before writing.

**Triage by "what's the penalty for being wrong?"** Resolve the decisions that are *expensive to reverse* — data model, storage engine, public API shape, migration strategy, library choices the codebase will marry. Leave the *hours-to-fix* details (internal naming, a button's copy, a log level) to the implementer; pinning them in the plan adds noise without adding safety. If a tech spec already settled the costly decisions, inherit them rather than re-litigating.

For each significant (costly-to-reverse) technical decision (e.g. library choice, data model design, API pattern, migration strategy), get a decision using AskUserQuestion:
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

### Step 4: Plan Structure Development (Vertical-First)

1. **Default to vertical slices** — each phase delivers a thin end-to-end capability (one user story, one workflow, one scenario) cutting through every layer it touches. Phase 1 is the *walking skeleton*: the thinnest possible end-to-end path that exercises the full stack. Plan only the change that was asked for — adjacent improvements go in a "Not in scope" list, not a phase.
2. **Apply the shippable-phase smoke test** to every candidate phase: *"If we shipped only this phase, what new thing could a user / caller / downstream system do that they couldn't before?"* If the answer is "nothing — it's foundation," merge it into the phase that consumes its output, or justify it explicitly as a named exception (see [references/slicing-strategy.md](references/slicing-strategy.md)).
3. **Name phases by capability, not by layer.** `Phase 1: customer can submit a draft order` — yes. `Phase 1: order schema + repository` — no.
4. **Horizontal phasing is the named exception.** Mark any horizontal phase with its justification: pure data migration with no behavior change, library upgrade, cross-cutting refactor, or a genuine technical precondition. Rare.
5. Create initial outline with phases, each labeled with its user-visible capability.
6. Get feedback on structure before writing details.

### Step 5: Detailed Plan Writing

Write plan to `thoughts/shared/plans/YYYY-MM-DD-description.md` or `plans/YYYY-MM-DD-description.md`

Use the template in [templates/plan-template.md](templates/plan-template.md).

Each phase section covers what changes, why, and verification — no restated context, no summary sections, no padding.

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
3. **Be Precise**: Read files completely, include file:line references, write measurable criteria — without padding the plan beyond what's needed
4. **Be Practical**: Incremental testable changes, consider migration/rollback
5. **No Open Questions in Final Plan**: Research or ask immediately
6. **Decide Before Writing**: Resolve technical decisions interactively before committing them to the plan, not after
7. **Linear Sync is Separate**: Linear sync is handled by `/linear-ticket-status-sync`, not this skill
8. **Spec-First When Possible**: If the codebase has an outside-in / BDD harness, specs lead implementation. Phase 0 writes failing scenarios that fail for the right reason; later phases close only when their designated specs pass. Always invest in executable behavior knowledge over ad-hoc verification.
9. **Vertical Slices by Default**: Each phase must answer "what user-visible capability does this ship?" Horizontal phases (all schema, all API, all UI) defer integration risk and produce unshippable intermediate states. Acceptable exceptions: pure data migrations, library upgrades, cross-cutting refactors, or genuine technical preconditions — mark them explicitly. Reference: [references/slicing-strategy.md](references/slicing-strategy.md).
10. **Phases Named as Impact, Not Layer**: A phase title states the outcome a user/caller/downstream system gains ("customer can submit a draft order"), not the implementation that delivers it ("add order schema + repository"). A title that names a technology or layer is the same smell as a goal that says "Add Kubernetes" instead of "minimize deploy outages" — restate it as the capability shipped.
11. **Right-Size What the Plan Pins Down**: Spec the costly-to-reverse decisions; leave hours-to-fix details to the implementer. Over-specifying a plan buries the load-bearing choices in noise and invites churn when a trivial guess turns out wrong.

## Common Patterns

**New Features (vertical)**: Phase 1 = thinnest end-to-end happy path (one workflow through all layers — migration + repo + service + endpoint + UI/consumer); each subsequent phase extends with one more user-visible capability or edge case. *Avoid: Phase 1 = data model only.*

**Schema migrations (expand-contract)**: Phase 1 = expand (add new column/table, dual-write, old path still authoritative); Phase 2 = backfill + verify under production read traffic; Phase 3 = flip reads to new path, keep old as fallback; Phase 4 = contract (remove old path). Each phase is independently safe to halt at. Horizontal by nature — mark each phase as such.

**Refactoring (strangler / branch-by-abstraction)**: Slice by behavior, not by file. Phase 1 = introduce the new abstraction and route one complete user-facing flow through it end-to-end; subsequent phases migrate remaining flows one at a time. *Avoid: "Phase 1 = rewrite the service layer."*

**Performance / cross-cutting work**: Legitimate horizontal slicing — phase by hot path (P50 → P90 → P99) or by metric, not by user feature. State the metric delta each phase achieves.
