# Test Strategy: Establishing Loop Success Criteria

Read this during Phase 0 Step 4 ("Establish test strategy"). It answers the question the skill exists to solve: what does the loop check before it's willing to call a bounded context *done*? Two independent suites, for two independent claims:

| Suite | Claims | Source of truth |
|---|---|---|
| **Characterization (golden-master)** | "The new slice behaves like the old app did, for the flows that matter." | The legacy app itself, captured *before* any implementation starts |
| **Architecture** | "The new slice actually follows Explicit Architecture" — ports, purity, ledger invariants, etc. | `references/explicit-architecture-hanami.md` §4, §7, §10-§13 |

Neither suite alone is sufficient. Passing architecture tests proves the new code is well-structured, not that it does the right thing. Passing characterization tests proves behavioral parity, not that the new code is maintainable. Both go into the context's plan as automated success criteria — that's what makes the loop's stop condition ("Linear ticket reaches Done") mechanically trustworthy instead of a vibe check.

## 1. Characterization / golden-master tests

**Scope**: derive from the bounded context's entries in `research/ddd/02-event-catalog.md` and the BC Canvas in `research/ddd/06-canvases.md` — the commands, business rules, and key scenarios (including edge cases: declines, empty states, permission boundaries) attributed to this context. Don't try to characterize the entire legacy app at once; scope to what's in this context's plan.

**Capture mechanism** — chosen per what Phase 0 Step 1 found about the legacy app, in priority order:
1. **HTTP-level**: if the legacy app exposes HTTP endpoints for this context's flows, record real request/response pairs (status, headers worth asserting on, body) against a seeded/known state. Store as `spec/characterization/<context-slug>/http/<flow-name>.json` — `{request: {...}, response: {...}}`.
2. **CLI/job-level**: if the behavior is a background job, CLI command, or console-only flow, record input arguments/state and captured stdout/return value/resulting persisted state. Store as `spec/characterization/<context-slug>/cli/<flow-name>.json`.
3. **Unit/function-level**: if the legacy app has isolable pure logic (pricing calculations, eligibility rules, state transitions), record input → output pairs directly. Store as `spec/characterization/<context-slug>/unit/<flow-name>.json`.

Fixtures are **framework-agnostic** (plain JSON/YAML) deliberately — the target app doesn't exist yet when these are captured, so nothing Hanami-specific can wrap them until `implement-plan` scaffolds the slice. The subagent capturing them needs Bash access to actually run the legacy app (start a server, run a CLI command, execute a script) — dispatch a `general-purpose` or `qa-engineer` agent for this, never do it from the orchestrator's own (deliberately Bash-git-only) tool set.

**Wiring into the new app**: the injected "Phase 0" of each context's plan (see §3 below) must include the concrete step "write a spec harness that loads `spec/characterization/<context-slug>/**/*.json` and replays each fixture against the new Hanami slice's driving adapter (action/CLI), asserting the response matches." This is what turns a pile of JSON into an enforced CI gate.

**What NOT to characterize**: legacy bugs nobody wants preserved, timing-dependent output (timestamps, request IDs) — normalize those out of the fixture rather than asserting on them, and any behavior the DDD alignment step already flagged as being intentionally changed in the replatform (check `research/ddd/01-alignment.md` for explicit scope changes).

## 2. Architecture tests

Pull the decision from the mapping doc (`research/…-mapping-<slug>.md`, produced in Phase 0 Step 3) for this context, then require the matching tests per the reference doc:

| Mapping doc says | Required tests | Reference doc section |
|---|---|---|
| Any port declared (payment gateway, notifier, etc.) | Shared-example group per port + `it_behaves_like` for every adapter including the null object | §4 |
| Always (every context) | Domain purity check — no `Deps`, no `Hanami::`, no `_repo`/`relations.` inside `domain/**` | §7, §13 fitness fn 3 |
| Any driven adapter | Port-leakage check — vendor name/exceptions appear only in `adapters/` and `config/providers/` | §13 fitness fn 4 |
| Ports declared | Port-coverage check — every adapter class is asserted to run its port's shared examples | §13 fitness fn 5 |
| Slice created (always, from slice #2 onward) | Boot-isolation check (`HANAMI_SLICES=<slice> bundle exec rspec spec/slices/<slice>`) + container-surface-approval spec | §13 fitness fn 1-2 |
| Event-sourced (mapping doc marks ES: yes) | Event-store contract tests (ordering, isolation, concurrent-write rejection) | §10, example in §10 |
| Ledger-shaped (mapping doc marks ledger: yes) | Conservation fitness fn (sums to zero per commodity) + projection-reconciliation fitness fn | §11 fitness fn 6-7 |
| Ledger + non-atomic (movement crosses a slice boundary, §12) | Clearing-balance, timeliness, and completeness fitness fns | §12 fitness fn 8-10 |
| Any `Dry::Validation::Contract` | Contract spec asserting structural/contextual rule split — never invariants leaking into the schema | §5 |

Don't over-apply: a CRUD-only slice (mapping doc says no domain layer, no ports) only needs the domain-purity and boot-isolation checks — forcing port-coverage or ledger fitness functions on it is scope creep the reference doc itself warns against (§15, §16 adoption sequence: "the pattern set is a menu, not a checklist").

## 3. Injecting into the plan

For each context's `ddd-plan`-produced plan file, `Edit` it to:

1. Insert a **Phase 0: Land characterization fixtures + test harness** (before the first real implementation phase) whose automated success criteria are: fixtures exist under `spec/characterization/<context-slug>/`, the replay harness exists and currently *fails* against a not-yet-built slice (red, on purpose — this is the pre-implementation baseline).
2. For each subsequent phase, append to its existing "Success Criteria (automated)" bullets the specific architecture tests from the table above that phase's work makes relevant (e.g., the phase that adds the payment adapter also adds "payment_gateway port coverage spec passes").
3. Add a final phase (or extend the last phase) whose success criteria include: **all** characterization fixtures now replay green against the real slice, **and** all applicable architecture fitness functions pass.

This is the whole mechanism — once these are in the plan, `implement-plan` verifies them phase-by-phase and `babysit-pr`/CI enforce them before the PR merges, so `qrspi` driving the ticket to Linear "Done" already means these tests passed. The loop doesn't need to re-invent verification; it needs the `qa-engineer` double-check in Phase 1 to catch the case where "Done" happened without CI actually running them (manual override, flaky pipeline, etc.) — see `backlog-schema.md`'s forbidden-operations list.
