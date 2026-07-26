# Loop Design for Skills

Distilled from ["Loop Engineering in Claude Code"](https://claude.com/blog/getting-started-with-loops) and this repo's one production loop skill, `skills/babysit-pr/`. Consult this when a skill's cadence (Phase 1a) is anything other than **One-shot**.

## Start simple

> "Not all tasks require complex loops; start with the simplest solution and use these patterns selectively."

Default every skill to one-shot. Add loop machinery only when the task genuinely spans time or requires repeated observation of something that changes without the user watching. A skill that finishes correctly in one turn should never grow a status artifact and a cron job just because "it could run again someday."

## The four loop types

| Type | Primitive | Trigger | Stop condition | Best for | Example |
|---|---|---|---|---|---|
| Turn-based | (default agent loop) | User prompt | Claude judges the task complete, or needs more input | Short, non-recurring tasks | Most skills in this repo |
| Goal-based | `/goal` | Manual, real-time | Evaluator model checks the transcript against a stated condition, or max turns reached | Tasks with a verifiable exit criterion ("Lighthouse score ≥ 90") | `babysit-pr` sets a `/goal` in Step 1 to keep cycle 1 turning |
| Time-based | `/loop`, `/schedule` | A time interval | User cancels, or the work is done | Recurring work or monitoring an external system | — |
| Proactive | `CronCreate` (recurring, durable) | Schedule, no human present | A cycle detects a terminal state and tears down its own job | Well-defined recurring streams: shepherding, monitoring, digesting | `babysit-pr` |

Pick the *lightest* primitive that supplies the stop condition you need — don't reach for `CronCreate` + a status artifact when a single `/goal` call would do.

## Requirements to work out before writing the skill

Fold these into Phase 1c's requirements list whenever cadence ≠ One-shot:

1. **Stop condition.** Name it precisely enough that either an evaluator model (`/goal`) or your own cycle logic (`/loop`/cron) can check it mechanically — not "keep going until it feels done." Always give the user an explicit way out too (a pause/stop question or a natural terminal state), even when the "real" stop condition is automatic.
2. **State-tracking artifact.** Recurring loops can't rely on conversation memory — each fire may start cold. Persist a status artifact with machine-readable front-matter (job id, interval, scope, state enum) and an append-only cycle log. Convention: `thoughts/shared/<domain>/<skill>-<id>.md` (see `babysit-pr`'s `thoughts/shared/prs/babysit-<n>.md`).
3. **Re-entry detection.** A scheduled fire needs to skip onboarding (goal-setting, scope-freezing) and jump straight to the cycle body. Detect this either via an argument convention (`argument-hint: [id] [cycle?]`, checked in Initial Response) or by checking whether the state artifact already exists.
4. **Self-verification.** The blog's top quality point: "self-verification mechanisms via skills" and "secondary code review agents." A loop with no verification step drifts confidently. Build a QA/critique call into the cycle, or delegate to a dedicated reviewer subagent — don't let the loop grade its own homework with the same pass that did the work.
5. **Scope/blast-radius freeze.** Autonomous cycles compound small overreaches. Freeze the touched-file set (or equivalent boundary) at loop start; pass it as a hard constraint to every dispatched subagent; require out-of-scope work to escalate (`status: off-topic`) rather than silently expand.
6. **Whitelisted auto-actions.** Enumerate exactly what runs without `AskUserQuestion` (e.g. a lint-autofix + commit). Everything else asks. "Unattended" must never mean "no gate at all" — it means the gate moved from every-turn to whitelisted-actions-only.
7. **Anti-spiral guard.** Track how many times a given event (a bot comment, a failing check) has been auto-addressed in a ledger. Cap re-dispatch (e.g. ≥2 attempts) and escalate instead of retrying indefinitely.
8. **Forbidden operations.** For any loop with write access, list explicit hard-nos (never reply in the user's voice, never force-push without `--force-with-lease`, never merge without an explicit user choice). Don't rely on the model inferring restraint from context alone.
9. **Interval hygiene** (cron-backed loops only). Use off-minute, non-round intervals (`*/17 * * * *`, `*/47 * * * *`) — never `*/15`, `*/30`, or `0 * * * *` — to avoid fleet-wide API pile-ups. Back off the interval after N consecutive quiet cycles, but ask before doing so rather than silently slowing down.
10. **Durability + expiry.** Use `durable: true` on `CronCreate` jobs so they survive restarts, but mention any auto-expiry (cron jobs in this environment die after 7 days) to the user on first schedule, and make sure re-invoking the skill finds the existing artifact and reattaches instead of starting over.
11. **Idempotent cycles.** A fire might repeat (retry after a missed cron, a restart). Diff the current observed state against the last persisted snapshot; only act on genuinely new events. A no-op cycle still gets recorded (so the next diff has a baseline) but does nothing else.
12. **Pilot before scaling.** Per the blog: "pilot dynamic workflows on small data slices first." For a skill that will govern bulk or repeated work, have it run once, on one item, under direct observation, before flipping on the recurring schedule.

## Model tier for loop skills

The repo's default is `sonnet` for most workflow skills, reserving `opus` for open-ended judgment (see Phase 2a). That default assumes a human reviews each turn. It breaks for unattended cadences:

- **Goal-driven or recurring/proactive loops that write autonomously** (push commits, merge, message externally) → `model: opus`. There is no human gate between cycles to catch a bad call — the next check-in might be hours away. `babysit-pr` uses `opus` for exactly this reason.
- **Turn-based iterative-refinement loops where a human reviews the output before the next round** (e.g. `iterate-plan`, `grill-me`) can stay on `sonnet` — the human-in-the-loop gate that justifies the cheap tier is still intact, just spread across turns instead of one-shot.

The distinguishing question is not "does this loop," it's "does a human see and can correct every cycle's output before the next one fires." If no, default to `opus`.

## Token / context management

From the blog's guidance, folded into skill design:

- Size the primitive to the task — a single `/goal` call beats a cron job + status artifact for anything that resolves in a handful of turns.
- Write the stop condition precisely; a vague one burns turns on the evaluator repeatedly guessing wrong.
- Push deterministic work into fixed tool calls inside the cycle body (a specific `gh pr view --json ...` shape, not "figure out how to check status") rather than re-deriving the check each fire.
- Mention `/usage`, `/goal`, and `/workflows` to the user if they express cost concerns about a loop skill — those are the built-in ways to monitor spend.

## Anti-patterns

- A `CronCreate`-backed loop for something that finishes in one turn — the blog explicitly warns against over-engineering here.
- "Keep monitoring forever" with no stop condition and no user-facing pause/stop path.
- Re-deriving "am I done yet" from vibes each cycle instead of diffing persisted state.
- Autonomous write access with no forbidden-operations list.
- Round-number cron intervals causing thundering-herd load across many concurrent loop skills.
- Treating "unattended" as license to skip verification — self-checks matter *more*, not less, when no one's watching each cycle.

## Reference implementation

`skills/babysit-pr/SKILL.md` + `skills/babysit-pr/references/cycle-logic.md` implement nearly every pattern above end-to-end: mode detection (fresh vs `cycle` re-entry), a `/goal` for cycle-1 completeness plus `CronCreate` for ongoing cycles, a status-artifact schema with front-matter + append-only log, a scope freeze passed to every dispatched subagent, a bot-dispatch ledger for anti-spiral, an explicit forbidden-operations list, and off-minute cron intervals with a quiet-cycle back-off question. Read it alongside this file when designing a new recurring skill.
