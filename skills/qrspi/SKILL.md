---
name: qrspi
description: "Drive a Linear ticket through the full Q→R→S→P→I lifecycle: Qualify → Research → Spec → Plan → Implement. Runs ONE step per invocation, designed for /loop /qrspi ENG-123. Each step delegates to the appropriate role-skill, gates before destructive actions, and halts on block or anti-loop detection."
argument-hint: "[TICKET-ID]"
model: sonnet
allowed-tools: Read, Grep, Glob, Bash, Task, AskUserQuestion, TodoWrite, Skill
---

# QRSPI Orchestrator

Ultrathink about what it means to shepherd a ticket through the full lifecycle autonomously: you are routing on the user's behalf across turns and wakes. Every stage you launch writes artifacts or modifies code. Gate before destructive actions. Halt clearly on ambiguity — a clear halt the user can resolve in one look beats a confident wrong step.

Drive a Linear ticket through the full **Q → R → S → P → I** lifecycle. This skill runs **ONE step per invocation** and is designed for `/loop /qrspi ENG-123` — `/loop` re-invokes automatically; each wake picks up where the last left off.

**Input**: $ARGUMENTS

## Architecture Note

This skill is **inline** (no `context: fork`). It must stay inline because it uses `AskUserQuestion` for gates before every destructive action. Forked skills lose access to `AskUserQuestion`; any gate in a forked context silently degrades to a plain-text prompt the user never sees.

**Model note**: Sonnet is correct here *because gates are present* — a human is in the loop to catch a routing mistake. If you ever run `/qrspi` fully unattended (cron / headless, no human gate), you must regrade this skill to `model: opus` per the unattended-orchestrator rule: autonomous routing and anti-loop judgment have nothing catching a bad call without Opus-level judgment.

## Current Context

- **Branch**: !`git branch --show-current`
- **Last 5 commits**: !`git log --oneline -5`
- **Modified files**: !`git status --short`

Before proceeding, check whether a TICKET-ID was passed in `$ARGUMENTS`. If the argument is non-empty and looks like a ticket ID (e.g. `ENG-123`, `PLAT-56`), proceed with that ticket. If `$ARGUMENTS` is empty, see **Initial Response (without ticket)** below.

If a ticket is in scope, use the Linear MCP read tools to fetch its current status — load the workspace-appropriate tools by matching the ticket prefix to a workspace (e.g. `ENG-` → Stellar). Read the state file at `thoughts/shared/qrspi/<ticket>.md` if it exists.

## Initial Response (with ticket)

When a TICKET-ID is provided:

1. **Read or note the state file** at `thoughts/shared/qrspi/<ticket>.md`. If the file doesn't exist yet, it will be created after the first stage completes. Do not create it prematurely — the directory is created at runtime by the first write.

2. **Check the halt flag first.** If the state file exists and `halt` is non-null, surface the halt reason to the user and stop. Do not proceed to the state machine. Instruct the user to reset it (see Troubleshooting below).

3. **Fetch the current Linear status** for the ticket using MCP tools. Present:
   ```
   Ticket: [TICKET-ID] — [Title]
   Current Linear status: [status]
   Last recorded stage: [stage from state file, or "none"]
   Attempt count: [from state file, or 0]
   ```

4. **Look up the next stage** in the state machine table below. Show the user:
   - Current status
   - Intended next stage skill
   - Expected output / artifact
   - Whether a gate will be shown before execution

5. **Run the anti-loop check** (see Stop-State section).

6. **Dispatch to the appropriate stage** per the Per-Stage Dispatch section below.

## Initial Response (without ticket)

If no TICKET-ID is provided, ask the user which ticket to drive via `AskUserQuestion`:
- **Ticket**: Which Linear ticket should I drive through QRSPI?
- Options: *Provide a ticket ID (e.g. ENG-123)*, *Cancel*

Wait for the user's response, then re-enter the flow with the provided ticket ID.

## State Machine

| Current Linear status | Next stage skill | Advances ticket to |
|---|---|---|
| Backlog / Todo | `improve-issue` | Ready for Research |
| Ready for Research | `research-codebase` (gate: design needed? → `tech-spec`) | Ready for Plan |
| Ready for Plan | `create-plan` | In Plan |
| In Plan | `implement-plan` (→ `developer` subagent) | In Progress |
| In Progress | `implement-plan` / `describe-pr` | In Review |
| In Review | `babysit-pr` (its own loop → merge) | Done |
| Done | terminal — stop | — |

## Per-Stage Dispatch

### Backlog / Todo → `improve-issue`

Gate first:
- **Gate — improve-issue**: I'm about to invoke `improve-issue` for `[TICKET-ID]`. This will enrich the ticket with acceptance criteria and advance its Linear status to "Ready for Research". Proceed?
- Options: *Yes, run improve-issue*, *Skip (ticket already enriched)*, *Pause QRSPI*, *Stop*

On confirmation: Invoke the `improve-issue` skill, passing the ticket ID. `improve-issue` handles its own `AskUserQuestion` clarification flow. When it returns, re-fetch the Linear status. If status advanced to "Ready for Research", update the state file and end the turn cleanly.

### Ready for Research → `research-codebase` (then gate: `tech-spec`?)

Research is non-destructive — proceed without a gate:

Invoke the `research-codebase` skill, passing the ticket ID. `research-codebase` spawns researcher/scout subagents and produces a research document. When it returns, ask:

- **Gate — tech-spec**: Research is complete. Does this ticket require a technical design spec before planning (new API surface, architectural decision, cross-cutting change)?
- Options: *Yes, run tech-spec first*, *No, proceed directly to create-plan*

If yes: Invoke the `tech-spec` skill (it is inline and handles its own gates). `tech-spec` produces a design document. After it returns, update the state file with `last_stage: tech-spec` and end the turn — `/loop` will pick up at "Ready for Plan" if Linear status has advanced, or the next invocation can proceed to `create-plan`.

If no: Update the state file with `last_stage: research-codebase` and end the turn cleanly. The next invocation will find "Ready for Research" or "Ready for Plan" depending on whether `research-codebase` advanced the status.

### Ready for Plan → `create-plan`

Gate first:
- **Gate — create-plan**: I'm about to invoke `create-plan` for `[TICKET-ID]`. This will produce a phased implementation plan and advance the ticket to "In Plan". Proceed?
- Options: *Yes, run create-plan*, *Skip (plan already exists)*, *Pause QRSPI*, *Stop*

On confirmation: Invoke the `create-plan` skill, passing the ticket ID. `create-plan` is interactive (Opus inline persona) and handles its own clarification flow. When it returns, re-fetch Linear status. If status is "In Plan", update the state file and end the turn.

### In Plan → `implement-plan`

Gate first:
- **Gate — implement-plan**: I'm about to invoke `implement-plan` for `[TICKET-ID]`. This will implement the next unchecked phase of the plan, delegating code changes to the `developer` subagent. Proceed?
- Options: *Yes, run implement-plan*, *Specify a plan file path*, *Pause QRSPI*, *Stop*

On confirmation: Locate the plan file — check `plans/` and `thoughts/shared/plans/` for a file referencing the ticket ID, or ask the user for the path. Invoke the `implement-plan` skill, passing the plan file path. `implement-plan` delegates each phase to a `developer` subagent and gates between phases. When it returns, re-fetch Linear status. If status advanced to "In Progress", update the state file and end the turn.

### In Progress → `implement-plan` / `describe-pr`

Check whether a PR exists for the current branch:

Run `gh pr view --json number,url,state 2>/dev/null`. If a PR exists and is open:
- Gate first:
  - **Gate — describe-pr**: A PR exists for this ticket. I'm about to invoke `describe-pr` to generate a structured PR description and advance the ticket to "In Review". Proceed?
  - Options: *Yes, run describe-pr*, *Continue implement-plan instead (plan not fully done)*, *Pause QRSPI*, *Stop*
- If yes: Invoke the `describe-pr` skill. When it returns, re-fetch Linear status. If status is "In Review", update the state file and end the turn.
- If continue implement-plan: Invoke `implement-plan` to pick up remaining phases (same gate as "In Plan" above).

If no PR exists yet:
- Gate first:
  - **Gate — implement-plan (continuing)**: No PR found yet. I'm about to invoke `implement-plan` to continue or resume plan implementation. Proceed?
  - Options: *Yes, continue implement-plan*, *Pause QRSPI*, *Stop*
- On confirmation: Invoke `implement-plan` as above.

### In Review → `babysit-pr`

Gate first:
- **Gate — babysit-pr**: I'm about to invoke `babysit-pr` for the PR associated with `[TICKET-ID]`. This hands off to babysit-pr's own autonomous loop — it will schedule a cron, watch CI, address review comments, and shepherd the PR to merge. Proceed?
- Options: *Yes, hand off to babysit-pr*, *I'll handle review manually*, *Pause QRSPI*, *Stop*

On confirmation: Obtain the PR number from `gh pr view --json number`. Invoke the `babysit-pr` skill, passing the PR number. `babysit-pr` manages its own `/loop` via CronCreate and handles merge completion. After handing off, set `halt: terminal` in the state file (babysit-pr takes ownership from here) and surface: "QRSPI has handed off to babysit-pr. The PR loop is now autonomous. QRSPI is complete for [TICKET-ID]."

### Done → terminal

If the current Linear status is "Done", set `halt: terminal` in the state file and stop:
```
Ticket [TICKET-ID] is Done. QRSPI lifecycle complete.
State file: thoughts/shared/qrspi/[TICKET-ID].md
```

## State File Management

The state file lives at `thoughts/shared/qrspi/<ticket>.md`. Read it before each run; write it after each stage completes. Do not create the directory — it is created at runtime.

**Format:**
```yaml
---
ticket: ENG-123
last_status: "Ready for Research"
last_stage: research-codebase
attempt_count: 1
halt: null
updated: 2026-05-30
---
```

**Fields:**
- `ticket`: The Linear ticket ID.
- `last_status`: The Linear status at the end of the last run (re-fetched after stage completes).
- `last_stage`: The stage skill dispatched last run (e.g. `research-codebase`, `tech-spec`, `create-plan`).
- `attempt_count`: Consecutive times the same stage has been dispatched without Linear status advancing. Reset to `0` when status advances.
- `halt`: `null` | `needs-user` | `blocked` | `terminal`. Any non-null value stops the loop.
- `updated`: ISO date of last write (`YYYY-MM-DD`).

After a stage completes successfully: re-fetch Linear status, write the state file with updated fields, and end the turn cleanly.

## Stop-State / Anti-Loop Guard

The `/loop` mechanism re-invokes this skill automatically and has no built-in tripwires. This stop-state is the only thing preventing an infinite loop.

**Check these conditions in order, before dispatching any stage:**

1. **Halt flag set**: If `halt` is non-null in the state file, surface the halt reason to the user and stop. Do not run any stage.

2. **Anti-loop guard**: If `last_stage == <stage you are about to dispatch>` AND the Linear status has not changed from `last_status` → increment `attempt_count`. If `attempt_count >= 2`, set `halt: blocked`, write the state file, and surface: "Stage `[stage]` has been dispatched twice without the ticket advancing from `[status]` — halting to avoid a loop. Inspect the stage's output or the state file, then reset `halt: null` to resume." Stop.

3. **Terminal status**: If the current Linear status is "Done", set `halt: terminal`, write the state file, surface the completion message, and stop.

4. **Stage returned blocked**: If a stage skill returns a blocked/partial result, set `halt: needs-user`, write a brief note in the state file, surface the blocker to the user, and stop.

**On clean stage completion**: Update all state file fields, end the turn with a one-line summary. The `/loop` re-invocation picks up the next stage automatically.

## Troubleshooting

**Reset the halt flag**: Edit `thoughts/shared/qrspi/<ticket>.md` directly and set `halt: null`. Then re-invoke `/qrspi [TICKET-ID]`.

**Jump to a specific stage**: Edit the state file — set `last_status` to the Linear status that maps to the desired stage (per the state machine table), set `last_stage` to a different value (so the anti-loop guard doesn't fire immediately), set `halt: null`. Re-invoke.

**Linear status is stale**: The MCP tools fetch live. If data looks stale, check the workspace MCP connection. You can also manually set `last_status` in the state file to match the true current Linear status and re-invoke.

**Stage skill not found**: Verify the skill directory exists under `skills/`. If a skill was renamed, update the dispatch call. The state file preserves progress — you won't lose work.

**`/loop` stopped re-invoking**: Check whether `halt` is non-null, or whether `/loop` itself exited. Re-invoke `/qrspi [TICKET-ID]` manually to restart. All progress is preserved in the state file.

**Multiple plan files for the same ticket**: If `plans/` contains more than one file referencing the ticket ID, ask the user which plan to use via `AskUserQuestion` before dispatching `implement-plan`.
