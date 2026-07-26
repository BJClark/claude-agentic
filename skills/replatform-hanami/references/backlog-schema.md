# Backlog State-File Schema

Read this before writing or updating `thoughts/shared/replatform/<slug>.md`. Modeled on `skills/qrspi/SKILL.md`'s state file (halt flag, attempt_count anti-loop guard) and `skills/babysit-pr/references/cycle-logic.md`'s status artifact (frontmatter + append-only cycle log, whitelist/forbidden lists). This file exists because a recurring `/loop` turn cannot rely on conversation memory — each fire may start cold.

## Slug derivation

Take the final path segment of the `$ARGUMENTS` value (strip a trailing `.git`, strip a trailing `/`), lowercase it, replace any run of non-alphanumeric characters with a single `-`, trim leading/trailing `-`. Examples:
- `/Users/x/code/Legacy_CRM` → `legacy-crm`
- `git@github.com:org/legacy-crm.git` → `legacy-crm`
- `https://github.com/org/Legacy-Booking-App` → `legacy-booking-app`

If a state file already exists at a slug that looks like a near-miss of the current input (e.g. user passed a slightly different path to the same app), surface it to the user via `AskUserQuestion` rather than silently creating a second parallel backlog.

## Frontmatter

```yaml
---
slug: legacy-crm
source: /Users/x/code/legacy-crm          # or the git URL originally given
source_kind: local_path                    # local_path | cloned_repo
legacy_clone_path: null                     # set if source_kind: cloned_repo
characterization_doc: research/2026-07-25-replatform-hanami-characterization-legacy-crm.md
ddd_complete: true
mapping_doc: research/2026-07-25-replatform-hanami-mapping-legacy-crm.md
backlog_state: driving                      # onboarding | driving | complete
halt: null                                  # null | needs-user | blocked | terminal
updated: 2026-07-25
---
```

## Backlog table (body, machine-readable)

A markdown table immediately after the frontmatter, one row per bounded context, in Core-first delivery order (from `ddd-strategize`'s confirmed sequence):

```markdown
## Backlog

| Context   | Ticket   | Plan file                                  | Status         | Attempt |
|-----------|----------|---------------------------------------------|----------------|---------|
| Ordering  | ENG-456  | plans/2026-07-25-ddd-ordering.md            | active         | 1       |
| Billing   | ENG-457  | plans/2026-07-25-ddd-billing.md             | pending        | 0       |
| Catalog   | ENG-458  | plans/2026-07-25-ddd-catalog.md             | pending        | 0       |
```

**Status enum** (per context): `pending` (not yet started) → `active` (currently being driven via `qrspi`) → `qrspi-done` (Linear ticket reached Done, `qa-engineer` verification not yet run) → `verified-done` (both test suites independently confirmed passing) → `blocked` (qrspi halted, or `qa-engineer` found a gap the user chose not to override).

Exactly one context should be `active` at a time — this is what "current turn's unit of work" means. `attempt`: consecutive times this context has been dispatched to `qrspi` without its Linear status advancing; mirrors `qrspi`'s own `attempt_count` but tracked independently per context here (qrspi tracks its own anti-loop guard internally per ticket — this column is for a coarser "is this context stuck" signal at the backlog level, e.g. qrspi itself halted twice in a row).

## Append-only cycle log

After the table, one section per turn:

```markdown
## Cycle 7 — 2026-07-26 09:14

**Active context**: Ordering (ENG-456)
**Dispatched**: Skill(qrspi, ENG-456)
**qrspi result**: advanced In Plan → In Progress
**Backlog change**: none
```

When a context completes verification:

```markdown
## Cycle 12 — 2026-07-28 16:02

**Active context**: Ordering (ENG-456)
**Dispatched**: Skill(qrspi, ENG-456)
**qrspi result**: ticket reached Done
**qa-engineer verification**: PASS — spec/characterization/ordering/ (14 fixtures) green; port coverage spec green; domain purity spec green
**Backlog change**: Ordering → verified-done. Billing (ENG-457) → active.
```

When verification finds a gap, do not mark done — log it and gate:

```markdown
## Cycle 15 — 2026-07-29 10:41

**Active context**: Billing (ENG-457)
**Dispatched**: Skill(qrspi, ENG-457)
**qrspi result**: ticket reached Done
**qa-engineer verification**: FAIL — spec/characterization/billing/invoice_generation.json fixture has no corresponding spec run; ledger conservation fitness function not present
**Backlog change**: none — held at qrspi-done, gated to user
```

## Whitelisted auto-actions (no `AskUserQuestion` needed)

- Dispatching `Skill(qrspi, <ticket>)` for the active context (qrspi gates internally on anything destructive)
- Re-checking Linear status via `Skill(linear)`
- Appending a cycle-log entry and updating the backlog table
- Advancing the `active` pointer to the next `pending` context once the current one reaches `verified-done`
- Declaring `backlog_state: complete` once every row is `verified-done`

## Forbidden operations (hard nos)

- Never `Write` or `Edit` anything under the legacy app's path (local or cloned) — characterization is strictly read-only. The one exception is the initial `git clone` destination itself.
- Never mark a context `verified-done` without an independent `qa-engineer` pass confirming both the characterization suite and the required architecture tests (§ of the mapping doc) actually exist and pass — Linear status "Done" alone is not sufficient (a human could have manually overridden a stage).
- Never create a Linear ticket before the full backlog has been presented to and confirmed by the user.
- Never force-advance the `active` pointer past a context whose `qrspi` dispatch returned halted/blocked — surface it and wait.
- Never clone a remote legacy repo into `/tmp` — use `thoughts/shared/replatform/<slug>/legacy-source/`.
- Never re-run the full onboarding phase (Steps 1-5) once a backlog exists for a slug — onboarding is one-time; if the user wants to redo a step, that's a Troubleshooting path (see SKILL.md), not an automatic re-run.

## Anti-loop guard

Same shape as `qrspi`'s: if the active context's `attempt` counter reaches 3 without its Linear status changing between turns, set `halt: blocked`, log why, and surface to the user instead of continuing to dispatch `qrspi` into the same stuck state.
