---
date: 2026-04-16
topic: skill-builder / babysit-pr
status: research
---

# Skill Research: babysit-pr

## Use Cases

1. **Offload PR shepherding while user multitasks.** User opens a PR, runs `/babysit-pr 1234` (or a GitHub URL), walks away. The skill runs initial QA, then polls every ~17 min: watches CI, watches review comments, auto-fixes trivial failures (lint/format), and pings the user via `AskUserQuestion` only when an engineering decision is required. Returns to a mergeable PR or a ranked list of waiting decisions.
   - Trigger phrases: *"babysit this PR"*, *"watch PR 1234 to merge"*, *"shepherd this to green"*.

2. **React to a new reviewer comment by ADDRESSING it (not replying).** Reviewer asks for a rename or a small refactor. Skill detects new comment, proposes the code change, `AskUserQuestion` asks user to approve the approach, then either applies it directly (trivial) or delegates to a `plan-implementer` `Task` subagent for multi-file changes. Commits and pushes. Never posts a textual reply — that stays with the user.

3. **Auto-fix a transient/trivial CI failure without a context switch.** CI fails on `eslint --fix`-able issues, prettier, or a missing newline. Skill runs the repo's autofix command, commits (`fix: lint autofix from babysit-pr`), pushes. User sees it in the status artifact but isn't paged.

**Anti-pattern (explicitly NOT this skill):** auto-replying to review comments with canned text. Per user: *"we won't be replying to review comments but actually addressing them. If they do require reply, then the user can do it."*

## Category

**Workflow Automation** — multi-step orchestration with validation gates, delegating to other skills (`/qa`, `/linear-ticket-status-sync`) and subagents (`plan-implementer`), with cross-session persistence via `CronCreate`.

## Scope

**Complex** (~200 lines SKILL.md, plus 1-2 reference files). Multi-phase (initial QA → recurring cycle → terminal), uses `Task` subagents for non-trivial fixes, uses `CronCreate`/`CronDelete` for scheduling, branches on 4+ PR states (CI red, new review, merge conflict, mergeable).

## Requirements

- **Trigger**: User runs `/babysit-pr <pr-url-or-number>`, or `/babysit-pr` with no args to infer from current branch.
- **Input**: One positional argument — a GitHub PR URL, a PR number, or empty. Optional second arg `check` / `cycle` used internally by the scheduled prompt to mean "run one cycle only, don't re-create the cron job" (the existing job handles scheduling).
- **Output**: Running status artifact at `thoughts/shared/prs/babysit-<number>.md` (NOT `research/` — this is ephemeral per-PR state, discarded when the PR merges; see `skills/write-artifact/references/api.md:117-119` for the durable vs ephemeral convention). **One file per PR**, appended on each cycle (cycle header + findings + actions taken). Serves as both the user's catch-up log and the skill's memory across fires.
- **Tools**:
  - `Read, Grep, Glob` — read code for context when investigating CI failures / review comments
  - `Bash(gh *)` — `gh pr view`, `gh pr diff`, `gh run list`, `gh run view`, `gh pr merge`
  - `Bash(git *)` — branch/ticket extraction, commit, push
  - `Bash(pnpm *), Bash(npm *), Bash(make *)` — run trivial autofixers (`pnpm lint --fix`, `make fmt`, etc.)
  - `Write, Edit` — update the running status artifact (NOT source code — that's delegated)
  - `Task` — spawn `plan-implementer` for any non-trivial code change
  - `AskUserQuestion` — all engineering decisions; all approach confirmations before pushing
  - `Skill` — chain `/qa <ticket-id>` (first cycle), `/linear-ticket-status-sync <ticket-id> babysit-pr` (terminal)
  - `TodoWrite` — track outstanding items (new comments, failing checks) across the session
  - `ToolSearch` — load deferred `CronCreate` / `CronDelete` / `CronList` at runtime
- **Interactions** (all via `AskUserQuestion`):
  1. Ambiguous PR target (multiple open PRs on branch, or no PR on current branch)
  2. Non-trivial CI failure — approach: investigate / revert last commit / skip this check / pause babysit
  3. Review comment needing code change — approach: apply proposed fix / modify approach / defer / escalate for user to handle manually
  4. Merge conflict — resolve now via plan-implementer / defer / pause
  5. PR reaches mergeable state — merge now (squash/rebase/merge) / wait / hand off
- **Success criteria**:
  - **Quantitative**: zero code pushes happen without `AskUserQuestion` approval except for whitelisted autofix commands (`lint --fix`, `fmt`, `prettier --write`). At least one cycle runs between every two PR events (new commit, new review, CI state change) while the job is active.
  - **Qualitative**: user can invoke `/babysit-pr 1234`, lock their screen, and return to either (a) a mergeable PR ready for their merge command, or (b) a short ranked list of decisions waiting for their input — never to an unexpected commit or a dead polling loop.

## Similar Skills

- **`skills/qa/SKILL.md`** — borrow: `Skill`-tool chaining pattern at tail (line 5 allowed-tools includes `Skill`; autoinvokes `/linear-ticket-status-sync`); `AskUserQuestion` option-set structure; `research/YYYY-MM-DD-[slug].md` artifact convention. Differentiate: `qa` is one-shot in-browser verification; `babysit-pr` is long-running event-reactive. `babysit-pr` calls `/qa` on its first cycle, so the two compose — they don't duplicate.
- **`skills/describe-pr/SKILL.md`** — borrow: `gh pr view --json url,number,title,state` PR normalization (line 31); branch-name-to-Linear-ticket regex (line 84 — "branch name contains a Linear ticket reference e.g., `ENG-1234`, `eng-1234`"); `Bash(gh *)` + `Bash(git *)` scoped tool permissions (line 5). Differentiate: one-shot write vs long-running reactive.
- **`skills/implement-plan/SKILL.md`** — borrow: orchestrator/subagent split ("delegate, gate, sync. Do NOT read files or make edits yourself"); `plan-implementer` `Task` spawn pattern; phase-gate `AskUserQuestion` structure. Differentiate: `implement-plan` is a synchronous phase loop; `babysit-pr` survives multiple cron fires in the same session.
- **`skills/linear-ticket-status-sync/SKILL.md`** — call it, don't replicate. Workspace detection from ticket-ID prefix is already solved there.
- **`skills/debug-issue/SKILL.md`** — borrow: `user-invocable: true` explicit flag; parallel `Task` pattern for simultaneous investigation (useful when cycle finds both CI failure *and* review comment).

## Conventions to Follow

- **Frontmatter**: `model: opus`; `user-invocable: true`; **no `context: fork`** (AskUserQuestion is unavailable in forked subagents per user memory — this skill needs it inline); `argument-hint: [pr-url-or-number]`.
- **Scoped Bash**: `Bash(gh *), Bash(git *), Bash(pnpm *), Bash(npm *), Bash(make *)` — principle of least privilege per `describe-pr`.
- **Current Context block**: standard `!` backtick git/gh commands at top (branch, last commit, `gh pr status --json 2>/dev/null`).
- **Skill chaining**: `Skill` tool to invoke `/qa` (initial) and `/linear-ticket-status-sync` (terminal) — don't re-implement.
- **Artifact path**: `thoughts/shared/prs/babysit-<number>.md` (ephemeral per-PR; discarded when PR merges). The skill-builder research doc itself stays in `research/` because it's durable.
- **Non-trivial code changes**: delegate to `plan-implementer` `Task` subagent, never edit source files directly in the skill.
- **Cron discipline**: off-minute interval (`*/17 * * * *`), `durable: true` (persists to `.claude/scheduled_tasks.json`, survives Claude restarts — addresses the session-termination concern in the scheduled-tasks docs), `recurring: true`. Self-cancel via `CronDelete` when terminal state reached.
- **Scheduled-prompt re-entry**: the CronCreate `prompt` is `/babysit-pr <pr#> cycle` — a second-arg convention that tells the skill "run one cycle, don't re-create the job."

## Key Design Decisions (from user in Phase 1 questions)

1. **Auto-action policy = "Auto-fix trivial, ask otherwise"** — whitelist of autofix commands (lint --fix, fmt, prettier --write) runs without asking. Anything else: AskUserQuestion.
2. **Scheduling = Dynamic self-paced** — default interval `*/17 * * * *`; after 3 consecutive quiet cycles, cancel and re-create with `*/47 * * * *` (back-off); reset on any PR event.
3. **Review comments = address, don't reply** — skill handles comments by editing code & pushing. If a comment is purely a question/discussion that needs a textual reply, the skill flags it in the status artifact and leaves the reply to the user. No `gh pr review --comment` calls.

## Open Questions for Plan Phase

- **Autofix command detection**: each repo ships with different autofix commands (`pnpm lint --fix`, `make fmt`, `cargo fmt`, `prettier --write`, etc.). Two approaches:
  - **(a) Inline detection**: skill checks for the repo's package.json / Makefile / etc. on each cycle and picks the right command — logic lives in SKILL.md body.
  - **(b) Reference file**: skill ships `skills/babysit-pr/references/autofix-commands.md` cataloging known repo → command mappings, which is consulted on each cycle.
- **Merge action**: does babysit-pr itself run `gh pr merge` when the PR is mergeable, or does it just flag "ready to merge" and exit? (Leaning: `AskUserQuestion` offers merge with squash/rebase/merge options; user can pick one or decline to merge manually.)

## Resolved

- **Status artifact = one file per PR, appended on each cycle** (user, 2026-04-16). Path moved from `research/` to `thoughts/shared/prs/babysit-<number>.md` per user feedback that running state is not a durable artifact.
