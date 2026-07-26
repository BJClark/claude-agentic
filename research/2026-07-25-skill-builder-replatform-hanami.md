# Skill Research: replatform-hanami

## Use Cases
1. Primary: "Replatform our legacy Rails/Django/whatever app at `~/code/legacy-crm` to the Explicit Architecture / Hanami stack" — user hands the skill a path (or repo) to a large external application and expects it to drive the *entire* migration, end to end, across many sessions, via `/loop /replatform-hanami <path>`.
2. Secondary: Resuming an in-progress replatform after stepping away for days — re-invoking with no path (or the same path) picks up the backlog exactly where it left off, mirroring `/qrspi`'s resume-by-state-file convention.
3. Anti-pattern to avoid: using this for a small, one-file, or already-Ruby/Hanami refactor — that's `improve-codebase-architecture` or a plain `/create-plan`, not this. This skill exists for *large, cross-language, multi-subsystem* migrations where DDD boundary discovery and phased delivery genuinely matter.

## Category
Workflow Automation (a long-running multi-phase orchestrator composing other orchestrator skills)

## Cadence
Recurring, but **turn-based via `/loop`, not `CronCreate`** — user confirmed. Mirrors `qrspi`'s own "one step per invocation, designed for `/loop`" pattern rather than `babysit-pr`'s fully-unattended cron pattern. Gates stay live every turn (via `AskUserQuestion`), so `model: sonnet` is correct per the loop-design.md rule ("a human reviews each cycle's output before the next").

## Requirements

- **Trigger**: User provides a path or repo pointer to a legacy application and asks to replatform/migrate/port it to the Hanami/Explicit-Architecture stack.
- **Input**: `$ARGUMENTS` = `[legacy-app-path-or-repo]`. No `cycle` re-entry marker needed (unlike `babysit-pr`) — resume is implicit via state-file presence, exactly like `qrspi`.
- **Output**:
  - `research/YYYY-MM-DD-replatform-hanami-characterization-<slug>.md` — legacy app inventory (durable)
  - `research/ddd/0N-*.md` — produced by the existing `ddd` skill sequence, fed the characterization doc in place of a PRD
  - `research/YYYY-MM-DD-replatform-hanami-mapping-<slug>.md` — bounded-context → Hanami-slice architecture mapping, using the bundled reference doc's decision rules (ports, ES suitability, ledger suitability)
  - `plans/YYYY-MM-DD-ddd-<context>.md` — produced by `ddd-plan`, then **augmented** (via Edit) with the test-strategy phase/success-criteria content, then tagged with the eventual Linear ticket ID so `qrspi`'s plan-file lookup finds it
  - `thoughts/shared/replatform/<slug>.md` — the running backlog/progress state file (ephemeral)
  - Characterization test fixtures inside the *target* repo (framework-agnostic golden-master snapshots), wired into real specs during `implement-plan`
- **Tools**: `Read, Grep, Glob, Write, Edit, Bash(git *), Task, AskUserQuestion, Skill, TodoWrite`. No direct Linear MCP tools — ticket creation goes through `Skill(linear)`, matching repo convention of orchestrators delegating rather than embedding MCP tool names.
- **Interactions**: Gates at every onboarding decision point (characterization scope, DDD steps — handled by `ddd`'s own internal gates, architecture mapping, test strategy, backlog/ticket creation). The recurring per-context drive step does **not** re-gate before calling `Skill(qrspi, ticket)` — `qrspi` already gates internally; double-gating would just be redundant friction.

## Loop Design

- **Stop condition**: Every bounded context in the backlog reaches `verified-done` — Linear ticket status is "Done" **and** an independent `qa-engineer` check confirms both the characterization suite and the architecture-test suite (contract shared-examples, invariant tests, ledger fitness functions where applicable) exist and pass in the merged code. This is the mechanical answer to "tests the loop can use as success criteria": tests are baked into each context's plan as automated success criteria *before* `qrspi`/`implement-plan`/`babysit-pr` ever runs, so the existing CI-gating machinery enforces them without new invention. The `qa-engineer` pass is the one added self-verification step (loop-design.md requirement — don't let the loop grade its own homework with the same pass that did the work).
- **State artifact**: `thoughts/shared/replatform/<slug>.md` (slug derived from the legacy path/repo name). Schema modeled on `babysit-pr`'s status artifact (state enum, append-only cycle log) and `qrspi`'s state file (halt flag, attempt_count anti-loop guard), adapted for a backlog of contexts instead of a single ticket/PR. Full schema goes in `references/backlog-schema.md`.
- **Re-entry detection**: State-file existence, exactly like `qrspi` (no `cycle` keyword needed since this isn't cron-fired).
- **Auto-run whitelist**: dispatching `Skill(qrspi, ticket)` (it gates internally), refreshing Linear status, updating the backlog state file, advancing to the next context once the current one is `qa-engineer`-verified done.
- **Forbidden operations**: no Write/Edit against the legacy app path (characterization is strictly read-only); never mark a context done without the independent `qa-engineer` verification; never create Linear tickets before the user confirms the full backlog; never scratch-clone a remote legacy repo into `/tmp` (user's global CLAUDE.md forbids `/tmp` — use `thoughts/shared/replatform/<slug>/legacy-source/` instead); never force-advance a context whose `qrspi` ticket is halted/blocked.
- **Interval / trigger**: N/A — user-paced via repeated `/loop` turns, not cron.

## Similar Skills
- `qrspi`: the direct model for turn-based-with-gates cadence, resume-by-state-file, halt/attempt_count anti-loop guard, and per-stage dispatch-then-gate structure. `replatform-hanami` sits one level above it — each of its recurring turns delegates one unit of work to `Skill(qrspi, ticket)`.
- `ddd`: the model for chaining a sequence of step-skills inline with `AskUserQuestion` gates between each — `replatform-hanami`'s onboarding phase calls `Skill(ddd, ...)` wholesale rather than re-implementing its steps.
- `babysit-pr` + `references/cycle-logic.md`: the model for a status-artifact schema (frontmatter + append-only log), whitelisted-auto-actions vs. forbidden-operations lists, and scope-freeze discipline — reused for the backlog artifact even though this skill stays turn-based rather than cron-driven.
- `improve-codebase-architecture`: the closest existing example of a skill that *ends* by hand off to another top-level orchestrator (`grill-me`, then `improve-issue`) — differentiate from it: `replatform-hanami` doesn't hand off once at the end, it dispatches repeatedly to `qrspi` across many turns for many contexts.
- **Gap confirmed by research**: no existing skill investigates a codebase outside the current repo, and no existing skill composes `ddd` *and* `qrspi` together. Both are designed fresh here.

## Conventions to Follow
- Frontmatter: `model: sonnet`, no `context: fork` (uses `AskUserQuestion` throughout), `argument-hint: [legacy-app-path-or-repo]`.
- Durable vs. ephemeral split: `research/` for characterization/mapping docs and DDD artifacts (survive the task), `thoughts/shared/replatform/<slug>.md` for the running backlog state (discarded once the migration finishes) — per `feedback_artifact_locations.md`.
- Keep SKILL.md under the word budget by pushing the backlog-state schema, the test-strategy methodology, and the full Hanami mapping/testing reference into `references/`, exactly as `babysit-pr` pushes its event-matrix into `references/cycle-logic.md`.
- Bundle the user-supplied `explicit-architecture-hanami.md` doc into `skills/replatform-hanami/references/` verbatim so the skill is self-contained (not dependent on a path in `~/Downloads`) and can be cited by file:line-equivalent section references during the mapping and test-strategy steps.
