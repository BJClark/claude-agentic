---
name: babysit-pr
description: "Monitor a PR end-to-end: run initial QA, watch CI, auto-fix trivial failures, address review comments by editing code (not replying), gate engineering decisions via AskUserQuestion, and poll on a schedule until the PR is mergeable. Use when a PR is open and needs autonomous shepherding to merge-ready. Triggers on 'babysit this PR', 'watch PR 1234 to merge', 'shepherd this to green'."
model: opus
user-invocable: true
allowed-tools: Read, Grep, Glob, Bash(gh *), Bash(git *), Bash(pnpm *), Bash(npm *), Bash(make *), Bash(cargo *), Bash(yarn *), Write, Edit, Task, AskUserQuestion, Skill, TodoWrite, ToolSearch
argument-hint: [pr-url-or-number] [cycle?]
---

# Babysit PR

Ultrathink about what it means to shepherd a PR autonomously: you are acting on the user's behalf across minutes or hours, between their other work. Every line you push carries their name. Every reply to a reviewer carries their voice. The right posture is **observe carefully, act only on trivial maintenance, and ask the user before anything substantive** — and never impersonate the user in review conversations. The PR is theirs; you are a diligent assistant, not a stand-in.

Monitor a PR end-to-end: run initial QA via `/qa`, poll on a `CronCreate` schedule, watch CI + review comments + merge state, auto-fix whitelisted trivial failures, **address review comments by editing code rather than replying**, and gate every non-trivial decision through `AskUserQuestion`. Stops when the PR is merged, closed, or the user pauses.

**Input**: $ARGUMENTS

## Current Context

- **Branch**: !`git branch --show-current`
- **Last Commit**: !`git log -1 --oneline`
- **Open PR on branch**: !`gh pr view --json number,title,url,state 2>/dev/null || echo "(none)"`
- **Active babysit jobs**: !`ls thoughts/shared/prs/babysit-*.md 2>/dev/null | head -5 || echo "(none)"`

## Initial Response

Detect mode first:

- **`$ARGUMENTS` contains a second word `cycle`** → this is a fired cron invocation. Skip initial response. Jump directly to **Step 3: Run the cycle** using the PR number from the first word.
- **`$ARGUMENTS` has exactly one non-empty word** (PR URL or number) → begin **Step 1**.
- **`$ARGUMENTS` is empty**:
  - Run `gh pr view --json number,url,title,state 2>/dev/null` on current branch.
  - If a PR exists on the current branch: use it and begin **Step 1**.
  - If not, run `gh pr list --author @me --state open --limit 10 --json number,title,headRefName,url` and ask the user which PR to babysit via `AskUserQuestion` (options: one per PR returned, plus "cancel").
  - If no open PRs found, print:
    ```
    No open PR found on this branch or in your recent PRs.

    Please provide a PR URL or number:
      /babysit-pr 1234
      /babysit-pr https://github.com/org/repo/pull/1234
    ```
    Then wait.

## Process Steps

### Step 1: Normalize PR & extract Linear ticket

1. Run `gh pr view <input> --json number,url,title,headRefName,baseRefName,state,mergeable,mergeStateStatus`. Store the result as `PR`.
   - If `gh` errors with "no default remote," instruct the user to run `gh repo set-default` and stop.
   - If `PR.state` is `MERGED` or `CLOSED`, print "PR is already {state}; nothing to babysit" and stop.

2. Extract the Linear ticket from `PR.headRefName` using the regex `(?i)(ENG|PLAT|OPS|STELLAR|MEERKAT|KICKPLAN|AURA)-\d+`. Store as `TICKET` (may be null).
   - If null: ask with `AskUserQuestion`:
     - **Ticket**: No Linear ticket found in branch `{headRefName}`. What would you like to do?
     - Options: *Provide a ticket ID*, *Skip QA and only watch CI/reviews*, *Cancel babysit*

3. Check for an existing status artifact at `thoughts/shared/prs/babysit-<PR.number>.md`:
   - **If exists**: we're re-attaching to an already-babysat PR. Read it to recover `cron_job_id`, previous cycle state, and outstanding todos. Skip **Step 2** (QA already ran). Jump to **Step 3**.
   - **If not**: create the artifact (see "Status artifact format" below) and continue to **Step 2**.

### Step 2: First-cycle QA (new babysit only)

Invoke `/qa <TICKET>` via the `Skill` tool. `/qa` handles its own interactivity (acceptance criteria extraction, browser verification, per-criterion AskUserQuestion). When it returns, append a `## QA Result` section to the status artifact summarizing pass/fail and any blockers.

If QA reports blocking failures, ask with `AskUserQuestion`:
- **QA blockers**: QA found {N} blocker(s): {summary}. How to proceed?
- Options: *Continue babysitting, will address during cycles*, *Pause babysit until blockers resolved*, *Abort babysit*

### Step 3: Run one cycle

Delegate the full event-handling matrix to the reference: see **[references/cycle-logic.md](references/cycle-logic.md)** for the complete (CI × review × merge-state) branching, the trivial-autofix whitelist, and the plan-implementer dispatch prompt templates.

High-level:

1. **Fetch current state** in one `gh` call:
   ```
   gh pr view <n> --json mergeable,mergeStateStatus,reviewDecision,statusCheckRollup,reviews,commits,comments,state
   ```
   Plus `gh pr checks <n> --json name,state,conclusion,link` for per-check detail.

2. **Diff against last cycle** (stored in the status artifact's last cycle block). Identify NEW events only — a failing check that was already failing last cycle is not a new event, it's an outstanding todo.

3. **For each new event, route through references/cycle-logic.md**:
   - CI red + trivial → inline autofix detection (probe `package.json` scripts, `Makefile`, `Cargo.toml`, etc.) → run → commit → push. No AskUserQuestion.
   - CI red + non-trivial → AskUserQuestion (spawn plan-implementer / revert / skip / pause)
   - New review comment needing code change → AskUserQuestion approach confirmation → Task(plan-implementer). **Never post a reply via `gh pr review`.**
   - New review comment needing textual reply → append to status artifact under `### Needs your reply`. Do not respond.
   - Merge conflict → AskUserQuestion (resolve via plan-implementer / defer / pause)
   - Mergeable (CI green + no unresolved reviews + no conflicts) → **Step 5**.

4. **TodoWrite** every outstanding item: failing checks still red, review comments not yet addressed, deferred decisions. Persist equivalent entries in the status artifact so the next cron fire can see them.

5. **Append a cycle block** to the status artifact (format below).

### Step 4: Schedule next cycle

Load the cron tools: use `ToolSearch` with query `select:CronCreate,CronDelete,CronList` once per session.

1. **If `$ARGUMENTS` ends with `cycle`** and a cron job is already active for this PR (check via `CronList` + stored `cron_job_id` in the artifact): **do nothing** — the existing job will fire again. Skip to end.

2. **If first invocation** (no `cycle` arg, no existing job): call
   ```
   CronCreate(
     cron: "*/17 * * * *",
     prompt: "/babysit-pr <PR.number> cycle",
     recurring: true,
     durable: true
   )
   ```
   Record the returned `id` as `cron_job_id` in the artifact front-matter. The off-minute interval (`*/17`) avoids API pile-ups; `durable: true` persists to `.claude/scheduled_tasks.json` so the loop survives Claude restarts.

3. **Back-off after quiet**: if this is the 3rd consecutive cycle with zero new events AND no outstanding todos, ask:
   - **Quiet PR**: No changes for 3 cycles. Slow down polling?
   - Options: *Back off to every 47 min*, *Keep every 17 min*, *Pause until I say resume*, *Stop babysitting*

   On back-off: `CronDelete(old_id)` then `CronCreate(cron: "*/47 * * * *", ...)` with same prompt and update artifact.

### Step 5: Terminal path (mergeable / merged / closed / paused)

Triggered when the cycle body detects a terminal state:

- **Mergeable** (CI green + no unresolved reviews + no conflicts):
  - Ask:
    - **PR ready to merge**: All checks pass, no unresolved reviews. Merge now?
    - Options: *Squash and merge*, *Rebase and merge*, *Merge commit*, *I'll merge it myself*, *Wait (keep watching)*
  - On a merge choice: run `gh pr merge <n> --{squash|rebase|merge} --auto` (or without `--auto` if user prefers immediate). Confirm success.
  - On "I'll merge it myself": print the exact `gh pr merge` command as a hint. Continue to cleanup.
  - On "Wait": skip cleanup; next cycle will re-evaluate.

- **Merged / Closed / Paused** (detected at start of cycle or after the merge question):
  1. `CronDelete(cron_job_id)`
  2. Append `## Final` section to the status artifact with outcome + timestamp.
  3. If `TICKET` was found, invoke `/linear-ticket-status-sync <TICKET> babysit-pr` via the `Skill` tool.
  4. Print a one-line summary to the user: `Babysit complete: PR #<n> {merged|closed|paused}. Log: thoughts/shared/prs/babysit-<n>.md`.

## Status artifact format

Path: `thoughts/shared/prs/babysit-<number>.md`

```markdown
---
pr: 1234
url: https://github.com/org/repo/pull/1234
title: <PR title>
ticket: ENG-5678
started: 2026-04-16T14:17:00
cron_job_id: cron_abc123
interval: "*/17 * * * *"
state: active  # active | paused | terminal
---

# Babysit log: PR #1234 — <title>

## QA Result (cycle 0)
- 4/5 acceptance criteria verified
- Blocker: criterion 5 — see /qa report at research/2026-04-16-qa-ENG-5678.md

## Cycle 1 — 2026-04-16 14:34
**State**: mergeable=CONFLICTING, CI=PENDING (3/5 green, 2 pending), reviews=1 requesting changes
**New events**:
- review-comment #r1: "rename `fooBar` → `foo_bar` in 3 files"
**Actions taken**:
- Asked user; approved plan-implementer dispatch
- Spawned plan-implementer → committed 8dadb24 "fix: rename fooBar to foo_bar (babysit-pr)" → pushed
**Outstanding**:
- Merge conflict with main (new commits on main since branch)
- CI check `integration-tests` still pending
**Needs your reply**:
- (none)

## Cycle 2 — 2026-04-16 14:51
...
```

## Guidelines

1. **Never reply to review comments in the user's voice.** The only permitted GitHub write actions are: `gh pr merge` (after explicit user choice), `git commit` + `git push` (for approved code changes). `gh pr review --comment`, `gh pr comment`, and `gh pr review --approve|--request-changes` are **forbidden**.
2. **Auto-run whitelist.** Only these commands run without `AskUserQuestion`: the detected repo autofix command (one of `pnpm lint --fix`, `pnpm format`, `make fmt`, `cargo fmt`, `yarn lint --fix`, `npm run format`), plus the final `git commit -m "fix: ... (babysit-pr)"` + `git push` immediately following a successful autofix. Everything else asks.
3. **No direct source edits.** The skill never calls `Edit` or `Write` on source files. For any code change, delegate to a `plan-implementer` `Task` subagent. `Write`/`Edit` are scoped to the status artifact at `thoughts/shared/prs/babysit-<n>.md`.
4. **Off-minute cron.** Use `*/17 * * * *` and `*/47 * * * *`, never `*/15` or `*/30` or `0 * * * *`. Avoids fleet-wide API pile-ups; `CronCreate`'s own jitter is insufficient on its own.
5. **7-day auto-expiry.** Recurring cron jobs die after 7 days. If the PR isn't merged by then, the skill must be re-invoked. Mention this to the user on first schedule.
6. **Cycle idempotency.** A cycle might fire on the same PR state twice (cron retry after missed fire). Always diff against the last cycle block in the artifact; if nothing is new, record an empty cycle and exit the cycle body cleanly.
7. **Terminal closure recovery.** Because `durable: true`, the cron job persists. When Claude restarts, the job will fire and re-enter the skill in cycle mode. If for any reason it doesn't, the user re-invoking `/babysit-pr <n>` will find the existing artifact and reattach in Step 1.
8. **Linear sync on terminal only.** Don't sync mid-cycle; only on merged / closed / paused via `/linear-ticket-status-sync`.

## Troubleshooting

- **`gh: no default remote`** → instruct the user: `gh repo set-default`, then retry.
- **Cron job not firing** → `CronList` to verify. If missing, recreate. If present but idle, the REPL has been mid-response continuously — this is rare; surface to the user.
- **`plan-implementer` returns `status: blocked`** → do not spawn another; surface the blocker to the user via `AskUserQuestion` with options: *retry with more context*, *I'll handle manually*, *defer*, *pause babysit*.
- **Autofix command detection fails** (no known script in package.json / no Makefile target) → do not guess. `AskUserQuestion` with options: *Provide the command*, *Treat as non-trivial CI failure*, *Skip this check*.
- **Two cron jobs for the same PR** (stale from a previous session) → on re-attach, `CronList`, identify duplicates by matching the `/babysit-pr <n> cycle` prompt, `CronDelete` all but the newest, update the artifact's `cron_job_id`.
