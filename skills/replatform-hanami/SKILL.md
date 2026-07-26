---
name: replatform-hanami
description: "Orchestrate a full replatform of a large external legacy application to the Explicit Architecture / Hanami stack (DDD + Ports & Adapters + Onion + Clean + CQRS on Hanami slices): characterizes the legacy app, runs DDD discovery, maps bounded contexts to Hanami slices, establishes characterization and architecture tests as loop success criteria, then drives each context to done via /qrspi across /loop turns. Use for large, cross-language migrations to this specific target stack — not small refactors or same-language cleanups. Triggers on 'replatform this app to Hanami', 'migrate to explicit architecture', 'port this codebase to Hanami slices', 'replatform our legacy app'."
model: sonnet
allowed-tools: Read, Grep, Glob, Write, Edit, Bash(git *), Task, AskUserQuestion, Skill, TodoWrite
argument-hint: [legacy-app-path-or-repo]
---

# Replatform to Hanami (Explicit Architecture)

Ultrathink about what it means to shepherd a large migration across many sessions: you are not writing code directly, you are sequencing three heavyweight systems — DDD discovery, an architecture-mapping decision, and `qrspi`'s own per-ticket lifecycle — so that each turn does exactly one honest unit of work and leaves a trail the next turn (possibly days later, possibly a different context window) can pick up cold. The two things most likely to go wrong are the two this skill exists to prevent: replatforming code that silently changes behavior, and calling a slice "done" because a status field says so rather than because its tests actually ran. Treat both as first-class failure modes, not edge cases.

Drive a large external legacy application through a full replatform to the stack defined in [references/explicit-architecture-hanami.md](references/explicit-architecture-hanami.md) (DDD + Ports & Adapters + Onion + Clean + CQRS, implemented on Hanami slices). This skill runs **turn-based via `/loop`** — `/loop /replatform-hanami <legacy-path>` re-invokes automatically; onboarding happens once, then each turn advances the backlog by one step.

**Input**: $ARGUMENTS

## Architecture Note

This skill is **inline** (no `context: fork`) — it uses `AskUserQuestion` at every onboarding decision point. It composes two other inline orchestrators (`ddd` and `qrspi`) by invoking them via the `Skill` tool; because none of the three fork, invoking one loads its instructions into the *same* conversation rather than spawning an isolated subagent — control returns to this skill's remaining instructions once the invoked skill's own flow concludes its turn. Say so explicitly at each hand-off point below rather than assuming it's obvious.

**Model note**: `sonnet` is correct here because a human reviews every onboarding gate, and the recurring drive phase never acts without either `qrspi`'s own internal gates or (for anything genuinely destructive at this skill's own level — ticket creation, plan edits) an explicit gate of its own. If this skill is ever re-driven via `CronCreate` instead of `/loop`, regrade to `opus` per `references/loop-design.md`'s unattended-orchestrator rule in `skill-builder`.

## Current Context

- **Branch**: !`git branch --show-current`
- **Last Commit**: !`git log -1 --oneline`
- **Existing replatform backlogs**: !`ls thoughts/shared/replatform/*.md 2>/dev/null || echo "(none)"`
- **Existing DDD artifacts**: !`ls research/ddd/0*.md 2>/dev/null || echo "(none)"`

## Initial Response

1. **Derive the slug** from `$ARGUMENTS` per [references/backlog-schema.md](references/backlog-schema.md)'s slug-derivation rule (final path segment, strip `.git`, lowercase, non-alnum runs → `-`).

2. **Check for an existing backlog** at `thoughts/shared/replatform/<slug>.md`:
   - **Exists** → this is a resume. Read it. If `halt` is non-null, surface the reason and stop (see Troubleshooting). Otherwise show the backlog table and the most recent cycle-log entry, then jump straight to **Phase 1**.
   - **Absent + `$ARGUMENTS` provided** → fresh start. Before doing anything else, check the "Existing DDD artifacts" context above — if `research/ddd/0*.md` already exists, warn the user it will be read as-is (or overwritten by a fresh `ddd` run) and confirm via `AskUserQuestion` whether those artifacts belong to *this* replatform initiative before proceeding to **Phase 0**.
   - **Absent + `$ARGUMENTS` empty** → ask via `AskUserQuestion`: *"Which legacy application should I replatform? Provide a local path or a repo URL."* Wait, then re-enter with the answer.

## Phase 0 — Onboarding (fresh start only, one long gated session)

### Step 1: Characterize the legacy app

Resolve the source:
- **Local path**: confirm it exists (`Glob` or `Bash(git *)` for a quick `git -C <path> log -1` if it's a git checkout).
- **Repo URL**: gate first — *"I'll clone `<url>` into `thoughts/shared/replatform/<slug>/legacy-source/` for read-only inspection. Proceed?"* On yes, `Bash(git clone --depth 1 <url> thoughts/shared/replatform/<slug>/legacy-source)`. **Never clone into `/tmp`.**

Dispatch a `researcher` subagent (code-investigation mode) scoped to that path, read-only, to report: tech stack and framework(s), major feature areas / modules, external integrations, a first-pass informal list of candidate subdomains, and — critically for Step 4 later — **how the app can be exercised**: does it have a runnable dev server, a CLI, an existing test suite, seed data? This determines the characterization-capture mechanism.

Write the report via `Skill(write-artifact)` (template: `research`) to `research/YYYY-MM-DD-replatform-hanami-characterization-<slug>.md`.

Gate: present the summary, confirm via `AskUserQuestion` before proceeding to DDD discovery.

### Step 2: DDD discovery and design

Invoke `Skill(ddd, "<path to the characterization doc>")`, using the characterization doc in place of a PRD. Let it run to completion — it sequences all 7 of its own steps with its own internal `AskUserQuestion` gates, ending with `ddd-plan` writing one plan per bounded context to `plans/`. This can be a long sub-session; that's expected.

When it returns, resume here. Confirm `research/ddd/06-canvases.md` and at least one `plans/*.md` exist before continuing — if `ddd` was stopped early, don't proceed past this point (surface that to the user and hold).

### Step 3: Map bounded contexts to Hanami slices

Dispatch a `general-purpose` subagent (told explicitly to ultrathink this) reading `research/ddd/04-strategy.md`, `research/ddd/06-canvases.md`, and [references/explicit-architecture-hanami.md](references/explicit-architecture-hanami.md) end to end. For each bounded context, it must decide and justify:
- Slice name and which layers it actually needs (§15/§16: not every slice needs the full domain-layer treatment — CRUD-shaped contexts can stay repo + operation)
- Ports required, with their contract shape expressed as a null-object sketch (§4)
- Event-sourcing suitability (§10: is state a fold over past decisions? does an audit trail have standalone value?)
- Ledger suitability (§11: is there a conserved quantity that only moves?) and, if so, atomicity stance (§12: atomic unless a movement crosses a slice boundary)

Write the result via `Skill(write-artifact)` to `research/YYYY-MM-DD-replatform-hanami-mapping-<slug>.md`.

Gate: present the mapping table, confirm via `AskUserQuestion`.

### Step 4: Establish the test strategy

Follow [references/test-strategy.md](references/test-strategy.md) in full — it is the answer to "what tests does the loop use as success criteria," don't improvise around it. Per context: dispatch a subagent (Bash-capable — `general-purpose` or `qa-engineer` agent type, never the orchestrator's own tools) to capture characterization fixtures from the legacy app, determine the required architecture tests from the Step 3 mapping doc, then `Edit` that context's plan file to inject the test-strategy phase and append test requirements to each phase's success criteria.

Gate once for the whole batch (with an offered option to drill into any single context) via `AskUserQuestion` before moving on.

### Step 5: Build the backlog and create tickets

Determine delivery order from `ddd-plan`'s confirmed implementation sequence (Core domains first). Gate first — present the full backlog (context, proposed ticket title, order) and confirm via `AskUserQuestion` before creating anything.

On confirmation, for each context in order: `Skill(linear)` to create a ticket (status: "In Plan", description linking the plan/mapping/characterization docs). Then `Edit` that context's plan file to add a line near the top referencing the ticket ID (e.g. `**Linear Ticket**: ENG-456`) — this is what lets `qrspi`'s own plan-file lookup find it later; do not rely on filename conventions alone.

Write `thoughts/shared/replatform/<slug>.md` per [references/backlog-schema.md](references/backlog-schema.md), first context marked `active`, rest `pending`. Set `backlog_state: driving`.

Final gate: *"Backlog created — N contexts, N Linear tickets. Start driving <first context> (<ticket>) now?"* On yes, proceed directly into **Phase 1** within this same turn.

## Phase 1 — Recurring drive (every turn once a backlog exists)

1. Read the backlog state file. Find the `active` context. If none exists and none is `pending` either, every context is `verified-done` — see **Terminal** below.

2. **Dispatch**: `Skill(qrspi, <active context's ticket>)`. Let it run its normal one-stage flow, including any gate it presents — `qrspi` handles its own destructive-action gates; do not add a second gate here. Once its turn concludes, resume here.

3. **Check status**: `Skill(linear)` to re-fetch the ticket's current status.
   - **Still in progress** (any non-Done status): append a cycle-log entry, leave the context `active`, end the turn. The next `/loop` fire repeats from step 2.
   - **qrspi halted** (blocked/needs-user): do not advance anything. Surface qrspi's halt reason, append a cycle-log entry, end the turn. This context stays `active` until the user resolves it.
   - **Reached "Done"**: proceed to step 4.

4. **Independent verification** (do not skip — see forbidden operations in [references/backlog-schema.md](references/backlog-schema.md)): dispatch a `qa-engineer` subagent to confirm, by actually running them, that (a) every characterization fixture under `spec/characterization/<context-slug>/` replays green against the merged code, and (b) every architecture test the Step 3 mapping doc called for this context is present and passing.
   - **Pass** → mark the context `verified-done`, log the result, advance `active` to the next `pending` context (if any) — or set `backlog_state: complete` if that was the last one.
   - **Fail** → do **not** mark it done. Log the specific gap, surface it via `AskUserQuestion`: *"<Context> reached Linear Done but qa-engineer found: <gap>. How to proceed?"* Options: dispatch `qrspi` again to close the gap (creates a new stage for the same ticket), override and accept as-is (explicit user choice, logged), pause.

5. End the turn with a one-line summary, matching the convention used by `qrspi` and `babysit-pr`: e.g. *"Ordering (ENG-456) advanced to In Progress. 0/5 contexts verified-done."* or *"Ordering verified-done. Now driving Billing (ENG-457). 1/5 contexts verified-done."*

**Terminal**: when every context is `verified-done`, set `halt: terminal`, `backlog_state: complete`, and print:
```
Replatform complete for <slug>: N/N bounded contexts verified-done.
Backlog: thoughts/shared/replatform/<slug>.md
Durable artifacts: research/*-<slug>.md, research/ddd/, plans/*.md
```

## Troubleshooting

**Reset a halt**: edit `thoughts/shared/replatform/<slug>.md`, set `halt: null`, re-invoke.

**A context is stuck (attempt counter climbing)**: inspect the cycle log for that context, check the underlying `thoughts/shared/qrspi/<ticket>.md` state file directly — the problem is almost always inside `qrspi`'s own stage, not this skill's dispatch logic.

**`research/ddd/` had artifacts from unrelated prior work**: this skill doesn't namespace DDD output by slug (neither does `ddd` itself). If you're running two replatforms against the same target repo, finish or archive the first's `research/ddd/` and `plans/` before starting the second's Phase 0 Step 2.

**Want to redo Step 3 or Step 4 for one context after the backlog already exists**: edit the mapping doc or the context's plan file directly, then manually re-run the relevant subagent dispatch by invoking this skill and describing the specific context — onboarding as a whole does not re-run automatically once a backlog exists (see forbidden operations).

**`qa-engineer` keeps finding the same gap**: that's a signal the plan's Step 4 test-strategy injection was incomplete, not that `qa-engineer` is wrong — go back to [references/test-strategy.md](references/test-strategy.md), fix the plan file's success criteria, and re-dispatch.

## Guidelines

1. **Two suites, not one**: characterization tests prove behavioral parity with the legacy app; architecture tests prove the new code actually follows the target stack. Neither substitutes for the other — see `references/test-strategy.md`.
2. **The legacy app is read-only, always**: nothing in this skill's flow ever writes to the legacy path, cloned or local. If a step seems to need that, it's the wrong step.
3. **Don't grade your own homework**: a Linear ticket reaching "Done" is `qrspi`/`babysit-pr`'s claim, not this skill's. The `qa-engineer` dispatch in Phase 1 step 4 is what makes "verified-done" mean something.
4. **Menu, not checklist**: per the reference doc's own §15/§16, not every bounded context needs the full domain-layer, ports, ledger, and event-sourcing treatment. The Step 3 mapping doc should say "no" as often as it says "yes" — forcing every context into the heaviest pattern set is the failure mode the reference doc explicitly warns against.
5. **One active context at a time**: the backlog table should have exactly one `active` row. Two active contexts means two concurrent `qrspi` drives with no shared scope-freeze between them — don't do it, even if it seems faster.
6. **Onboarding is one-time**: once `thoughts/shared/replatform/<slug>.md` exists, Phase 0 does not re-run automatically. Changes to the mapping or test strategy after that point are manual edits, not a skill re-invocation.
