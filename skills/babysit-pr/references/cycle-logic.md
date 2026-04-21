# babysit-pr — cycle logic

Detailed branching for each event type a cycle can detect. Referenced from `SKILL.md` Step 3.

## Event detection

Fetch per cycle:

```bash
gh pr view <n> --json mergeable,mergeStateStatus,reviewDecision,statusCheckRollup,reviews,commits,comments,state
gh pr checks <n> --json name,state,conclusion,link,workflow
```

Snapshot relevant fields at end of each cycle into the status artifact's cycle block. "New event" = present in current fetch AND either absent or in a different state from the previous snapshot.

**First cycle (no prior snapshot):** the effective baseline is empty, so "new event" expands to *everything currently unresolved on the PR*:

- every `reviews[]` entry that is `CHANGES_REQUESTED` and not yet addressed
- every `comments[]` entry or review-thread comment that asks for a code change
- every failing check in `statusCheckRollup[]`
- any `mergeable == CONFLICTING` state

Cycle 1 typically processes several events and produces multiple `AskUserQuestion` turns (one per reviewer ask). The cycle is not complete — and Step 4 must not schedule the cron — until each first-cycle event has been routed through the matrix below (addressed via plan-implementer, deferred to next cycle, or recorded under `### Needs your reply`).

### Event types

| Event | Detection |
|---|---|
| `ci-green` | all `statusCheckRollup.state` == `SUCCESS` |
| `ci-red-trivial` | any check in {lint, format, prettier, eslint, typecheck-lint-only} failed with a diff that the repo's autofix command would resolve |
| `ci-red-nontrivial` | any check failed that isn't in the trivial set — test failures, build errors, integration failures, security scans |
| `review-new` | a `reviews[]` entry with `submittedAt` newer than last cycle's snapshot — or, on cycle 1, any unresolved `CHANGES_REQUESTED` review |
| `comment-new` | a `comments[]` entry with `createdAt` newer than last cycle's snapshot — or, on cycle 1, any open review-thread comment asking for a code change |
| `conflict` | `mergeable` == `CONFLICTING` OR `mergeStateStatus` == `DIRTY` |
| `mergeable` | `mergeable` == `MERGEABLE` AND `reviewDecision` in {`APPROVED`, null} AND all checks green AND no unresolved review threads |
| `closed` | `state` == `CLOSED` |
| `merged` | `state` == `MERGED` |

## Trivial autofix whitelist

A CI failure is **trivial** only if ALL of these hold:

1. The failing check's name matches `/(lint|format|prettier|eslint|fmt|style)/i`
2. The failing check is NOT a compound check that also runs tests (e.g., `lint-and-test` is non-trivial)
3. The repo has a detectable autofix command (see below)
4. Running the autofix produces a non-empty diff that, when committed and pushed, is expected to resolve the failure

If any condition is false, escalate to `ci-red-nontrivial`.

### Inline autofix command detection

Probe in this order. First match wins:

1. `package.json` scripts — in order: `format`, `lint:fix`, `lint --fix` — use `pnpm`, `yarn`, or `npm` based on lockfile (`pnpm-lock.yaml` → pnpm, `yarn.lock` → yarn, else npm).
   - `pnpm run format` / `pnpm run lint:fix`
2. `Makefile` targets — in order: `fmt`, `format`, `lint-fix`
   - `make fmt`
3. `Cargo.toml` present — `cargo fmt --all`
4. `.prettierrc*` present AND no matching script — `pnpm exec prettier --write .`
5. None found → NOT trivial. Escalate.

Probing is done each cycle via `Read` of the relevant file (do not cache across cycles; repos change).

## Per-event branching

### `ci-red-trivial`

1. Detect autofix command per above.
2. Run it. Capture stdout/stderr.
3. `git diff --stat` — if no changes, mark the failure as non-trivial and escalate.
4. `git add -A && git commit -m "fix: lint autofix (babysit-pr)"`
5. `git push`
6. Append to cycle block: `Actions taken: ran <cmd>, pushed <sha>`
7. The next cycle will observe CI re-running; no further action this cycle.

**No `AskUserQuestion`.** This is the one auto-action path.

### `ci-red-nontrivial`

1. Fetch failure detail: `gh run view <runId> --log-failed` for the first failing check.
2. Extract a compact summary (error type + top of failure output, ~20 lines max).
3. `AskUserQuestion`:
   - **CI failure**: `{checkName}` failed: `{summary-first-line}`. How to handle?
   - Options:
     - *Spawn plan-implementer to investigate and fix* — dispatch per template below
     - *Revert last commit* — `git revert HEAD && git push`; confirm with user before pushing
     - *Skip this check* — record in artifact; don't block on it; next cycle ignores this specific failure
     - *Pause babysit until I handle it* — CronDelete, update artifact state to `paused`

### `review-new` / `comment-new` requiring code change

1. Read the comment body. Classify intent:
   - **Code-change request** — imperative ("rename X", "extract Y", "use Z pattern")
   - **Discussion / question** — interrogative, or concerns about approach that don't propose a specific change
   - **Blocker** — review state `CHANGES_REQUESTED` with specific asks

2. **Check author first — bot vs human** (see "Bot comment auto-dispatch" below). If the author is a bot AND the intent is code-change or blocker, skip steps 3-4 entirely — dispatch `plan-implementer` immediately per the bot template. Do not draft an approach, do not ask the user.

3. For code-change or blocker (human authors only): draft a proposed approach (1-3 sentences). Do NOT write code yet.

4. `AskUserQuestion` (human authors only):
   - **Review comment**: Reviewer `{author}` on `{file}:{line}`: "{comment-excerpt}". My proposed approach: `{approach}`. What next?
   - Options:
     - *Apply my approach* — spawn plan-implementer with the approach as the plan
     - *Modify approach* — user provides alternate; re-ask with the new approach
     - *Defer to next cycle* — record in artifact `Outstanding`, move on
     - *I'll handle it manually* — record in artifact `Needs your reply`, don't touch

5. For discussion / question: **never respond on GitHub.** Append verbatim to `### Needs your reply` in the status artifact. Move on. (Bot-authored discussion/question comments — rare but possible, e.g. CodeRabbit "nitpick" commentary without an actionable ask — are also recorded here, not auto-dispatched.)

## Bot comment auto-dispatch

**Standing order (set by the user):** bot review comments are always addressed immediately via `plan-implementer` without `AskUserQuestion`. The user does not want to be prompted for each bot nit — they want them cleared as they arrive.

### Bot detection

A comment is bot-authored if ANY of:

1. `author.is_bot == true` in the `gh pr view --json comments,reviews` payload (GitHub's own flag — most reliable).
2. `author.login` ends with `[bot]` (GitHub App convention, e.g. `dependabot[bot]`, `github-actions[bot]`).
3. `author.login` matches any of these known review-bot logins (case-insensitive): `coderabbitai`, `coderabbitai[bot]`, `copilot-pull-request-reviewer[bot]`, `greptile-apps[bot]`, `greptileai`, `sonarcloud[bot]`, `sonarqubecloud[bot]`, `codecov[bot]`, `graphite-app[bot]`, `ellipsis-dev[bot]`, `sourcery-ai[bot]`, `deepsource-io[bot]`, `qlty-cloud[bot]`.

Cache the bot classification per comment-id in the cycle block so re-fires don't re-probe.

### Collection and ordering

Each cycle, after fetching review state:

1. Build the list of **outstanding bot code-change comments** — every bot-authored `comments[]` entry or review-thread comment that (a) is a code-change or blocker per step 1 of `review-new`, (b) is unresolved (thread not marked resolved), and (c) has not already been addressed by a commit in this PR (check via `Outstanding` entries in the artifact and commit subjects ending in `(babysit-pr bot: <comment-id>)`).
2. Order by `createdAt` ascending (oldest first).
3. Process **sequentially**: dispatch one `plan-implementer` via `Task`, await the return, record the outcome, then dispatch the next. Do not parallelize — the fixes touch overlapping files and plan-implementer's own git writes would race.

### Dispatch template (bot comment)

```
Task: address bot review comment on PR #<n>.

Context:
- Branch: <headRefName>
- Bot reviewer: <author.login>
- Location: <file>:<line>   (or "general comment" if no location)
- Comment id: <comment-id>
- Comment body (verbatim):
  <paste>

Standing order from user: address bot feedback directly without prompting. Use your judgement for the implementation.

Constraints:
- Commit message: "fix: address <bot-login> review (babysit-pr bot: <comment-id>)"
- Scope the change to what the bot flagged. If the bot's suggestion is wrong or would break something, return status: blocked with a short explanation — do NOT push an incorrect fix.
- If multiple bot nits in this thread point at the same symbol/file, it's fine to fix them together in one commit; reference the additional comment ids in the body.
- After the commit, push to the PR branch.
- Return status: completed | blocked | partial with files changed + commit sha.
```

### After each dispatch

- On `status: completed` → append to the cycle block under `Actions taken` and continue to the next bot comment.
- On `status: blocked` → **do not** auto-dispatch another for the same comment. Record under `Outstanding` with the blocker reason and surface via `AskUserQuestion` with options: *retry with more context*, *mark this bot comment as wontfix (ignore in future cycles)*, *I'll handle manually*, *pause babysit*. Continue processing remaining bot comments only after the user answers.
- On `status: partial` → record what was done, treat the remainder as a new outstanding bot-comment entry (same id) for the next cycle.

### Anti-loop guard

If the same bot comment-id has been dispatched 2 times across cycles and is still outstanding, stop auto-dispatching it and escalate via `AskUserQuestion` (options: *try one more time with extra context*, *mark wontfix*, *I'll handle manually*). Prevents infinite plan-implementer churn when a bot disagrees with the fix.

### `conflict`

1. Fetch: `git fetch origin {baseRefName}`
2. `AskUserQuestion`:
   - **Merge conflict**: PR has conflicts with `{baseRefName}`. How to resolve?
   - Options:
     - *Spawn plan-implementer to rebase and resolve* — dispatch with rebase context
     - *Defer* — record outstanding; skip until a future cycle
     - *Pause babysit until I resolve* — CronDelete, state → paused

### `mergeable`

See SKILL.md Step 5. Offer merge via `AskUserQuestion`.

### `closed` / `merged`

Terminal. Go to SKILL.md Step 5 cleanup.

## plan-implementer dispatch — prompt templates

When spawning `plan-implementer` via `Task` (`subagent_type: "plan-implementer"`):

### For CI failure investigation

```
Task: investigate and fix CI failure on PR #<n>.

Context:
- Branch: <headRefName>
- Failing check: <checkName>
- Failure output (first 50 lines):
  <paste>

Approach (from user via babysit-pr): <user's chosen approach, or "investigate freely">

Constraints:
- Commit message must end with "(babysit-pr)" so follow-up cycles can identify the commit.
- Do not edit files outside the scope of this failure.
- After fixing, push to the PR branch.
- Return status: completed | blocked | partial with a compact report.
```

### For review-comment code change

```
Task: address review comment on PR #<n>.

Context:
- Branch: <headRefName>
- Reviewer: <author>
- Location: <file>:<line>
- Comment body:
  <paste verbatim>

Proposed approach (approved by user via babysit-pr):
  <approach>

Constraints:
- Commit message: "fix: address review #<r-id> (babysit-pr)"
- Scope the change to what the reviewer asked for — do NOT bundle unrelated refactors.
- After the commit, push to the PR branch.
- Return status: completed | blocked | partial with files changed + commit sha.
```

### For merge-conflict resolution

```
Task: rebase PR #<n> onto <baseRefName> and resolve conflicts.

Context:
- Branch: <headRefName>
- Base: <baseRefName>
- Conflicts detected by `gh pr view`

Constraints:
- Use `git rebase origin/<baseRefName>` (not merge).
- Resolve conflicts preserving the PR's intent (not the base branch's).
- If a conflict is ambiguous (both sides modified the same logic non-trivially), STOP and return status: blocked with a description of the ambiguity.
- After resolution, force-push with lease: `git push --force-with-lease`.
- Return status: completed | blocked with commit sha.
```

## State tracking across cycles

Each cycle block in `thoughts/shared/prs/babysit-<n>.md` ends with a snapshot of the observed state. The next cycle diffs against this snapshot to identify new events. Fields to snapshot:

- `mergeable` + `mergeStateStatus`
- `reviewDecision`
- `statusCheckRollup[*].{name, state, conclusion}`
- Latest `reviews[*].submittedAt`
- Latest `comments[*].createdAt`
- Latest commit SHA on the PR branch

Store snapshot as a fenced `snapshot` code block at the end of each cycle for easy re-parsing.

## Quiet-cycle definition

A cycle is "quiet" if ALL of:

- Zero new events (no CI state change, no new review, no new comment, no new commit on base)
- No outstanding todos currently requiring action (deferred items don't count as action-needed unless they've been deferred > 2 cycles, in which case they become an action-needed item that prompts `AskUserQuestion`)

Three consecutive quiet cycles → trigger the back-off question in SKILL.md Step 4.

## Forbidden operations

Never invoked by this skill or its delegated subagents:

- `gh pr review --comment`, `gh pr review --approve`, `gh pr review --request-changes`
- `gh pr comment`
- `gh api` calls that create review threads, reactions, or issue comments
- Any commit that lacks `(babysit-pr)` in the message
- Any `git push --force` without `--force-with-lease`
- Any merge strategy other than the one the user explicitly chose via AskUserQuestion
