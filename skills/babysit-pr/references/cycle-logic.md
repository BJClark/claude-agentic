# babysit-pr — cycle logic

Detailed branching for each event type a cycle can detect. Referenced from `SKILL.md` Step 3.

## Event detection

Fetch per cycle:

```bash
gh pr view <n> --json mergeable,mergeStateStatus,reviewDecision,statusCheckRollup,reviews,commits,comments,state
gh pr checks <n> --json name,state,conclusion,link,workflow
```

Snapshot relevant fields at end of each cycle into the status artifact's cycle block. "New event" = present in current fetch AND either absent or in a different state from the previous snapshot.

### Event types

| Event | Detection |
|---|---|
| `ci-green` | all `statusCheckRollup.state` == `SUCCESS` |
| `ci-red-trivial` | any check in {lint, format, prettier, eslint, typecheck-lint-only} failed with a diff that the repo's autofix command would resolve |
| `ci-red-nontrivial` | any check failed that isn't in the trivial set — test failures, build errors, integration failures, security scans |
| `review-new` | a `reviews[]` entry with `submittedAt` newer than last cycle's snapshot |
| `comment-new` | a `comments[]` entry with `createdAt` newer than last cycle's snapshot |
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

2. For code-change or blocker: draft a proposed approach (1-3 sentences). Do NOT write code yet.

3. `AskUserQuestion`:
   - **Review comment**: Reviewer `{author}` on `{file}:{line}`: "{comment-excerpt}". My proposed approach: `{approach}`. What next?
   - Options:
     - *Apply my approach* — spawn plan-implementer with the approach as the plan
     - *Modify approach* — user provides alternate; re-ask with the new approach
     - *Defer to next cycle* — record in artifact `Outstanding`, move on
     - *I'll handle it manually* — record in artifact `Needs your reply`, don't touch

4. For discussion / question: **never respond on GitHub.** Append verbatim to `### Needs your reply` in the status artifact. Move on.

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
