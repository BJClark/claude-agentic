---
name: implement-plan
description: "Implement technical plans phase-by-phase with automated verification and phase gates between phases. Use when you have an approved plan file and are ready to execute it. Triggers on 'implement the plan', 'execute this plan', 'start implementation'."
model: sonnet
allowed-tools: Read, Grep, Glob, Bash(git *), Task, TodoWrite, AskUserQuestion, Skill
argument-hint: [plan-file-path]
---

# Implement Plan

Implement the approved technical plan at: **$ARGUMENTS**

You are an orchestrator. Each phase of the plan is implemented by a `plan-implementer` subagent in an isolated context — your job is to delegate, gate, and sync. Do NOT read implementation files, make edits, or run verification yourself; the subagent does that and returns a compact report.

## Current Context

- **Branch**: !`git branch --show-current`
- **Last Commit**: !`git log -1 --oneline`
- **Modified Files**: !`git status --short`

## Getting Started

When given a plan path:
- Read the plan file once, fully (no limit/offset) — you need its structure, phase list, and current checkbox state
- Identify the first unchecked phase (or the phase the user specified)
- If no plan path was provided, ask for one and wait

## Worktree Preflight (run before the first phase)

Detect the Linear ticket from the plan's frontmatter/title, from the plan's filename, or from the current branch name (`[A-Z]+-\d+`). If a ticket is detected, check whether a worktree exists and whether Claude is running inside it:

```bash
ROOT=$(git rev-parse --show-toplevel)
SLUG=<ticket-id-lowercased>    # e.g. ENG-1234 -> eng-1234
WT="$ROOT/.worktrees/$SLUG"
git worktree list --porcelain | grep -F "worktree $WT" && echo "wt-exists" || echo "wt-missing"
```

Three cases:

- **No worktree exists** → proceed to the per-phase loop.
- **Worktree exists AND current `git rev-parse --show-toplevel` equals `$WT`** → already inside the worktree; proceed.
- **Worktree exists AND we are in the main checkout (or any other tree)** → implementing here will edit/commit on the wrong branch. Ask via `AskUserQuestion`:
  - **Worktree detected**: A worktree for `{TICKET}` exists at `{WT}`. Implementing from the main checkout will touch the wrong branch. How should we proceed?
  - Options:
    - *Stop — I'll restart Claude inside the worktree* (print: `cd .worktrees/<slug> && claude`, then stop — do NOT spawn the plan-implementer)
    - *Continue in the main checkout anyway* (note this in the phase-1 `plan-implementer` prompt so the subagent is explicit about the branch it's committing to; proceed)
    - *Cancel*

This is especially important for implement-plan: the `plan-implementer` subagent commits directly. If it runs in the wrong tree, commits land on the wrong branch and a later worktree swap won't silently reconcile them.

## Per-Phase Loop

For each phase you intend to implement:

### 1. Delegate implementation

Spawn a `plan-implementer` subagent via the `Task` tool:

- `subagent_type`: `"plan-implementer"`
- `description`: short, e.g. `"Implement phase N of <plan>"`
- `prompt`: include
  - Absolute path to the plan file
  - Which phase to implement (number + title)
  - The Linear ticket identifier if one is present in the plan or branch name
  - Any relevant constraint the user has already communicated in this session

The subagent will read the plan and files itself, implement the phase, run verification, update plan checkboxes, and return a structured report. Its tool calls do NOT accumulate in your context.

### 2. Handle the report

If the subagent reports `status: blocked` or `partial`, surface the blockers/divergences to the user and stop. Do not paper over failures by spawning another subagent.

If the subagent reports `status: completed`, proceed to the gate.

### 3. Phase Gate

Use `AskUserQuestion` to gate progression:

- Question: `Phase [N] Complete - Ready for Manual Verification`
- Summarize what the subagent reported (files changed, verification results)
- List the manual verification items the subagent returned
- Options covering: proceed to next phase, fix issues first, review changes, stop here

If the user asked you to execute multiple phases consecutively, skip the gate until the last one. Otherwise assume one phase per invocation.

Do not tick manual-verification checkboxes in the plan yourself — only do so after the user confirms the manual steps passed, by spawning a short `plan-implementer` task to tick them (or ask the user to confirm and then use `Edit` on the plan once, if that's cheaper).

## Resuming Work

If the plan has existing `- [x]` checkmarks:
- Trust that completed work is done
- Ask the subagent to pick up from the first unchecked item in the targeted phase
- Do not re-verify previous phases unless the user asks

## Linear Sync

When the last phase of the plan is complete, if a Linear ticket was detected in the plan or the current branch name, invoke `/linear-ticket-status-sync [TICKET-ID] implement-plan` via the `Skill` tool to sync progress and advance the ticket status.

## What NOT to do here

- Do not `Read` or `Edit` source files the plan references — delegate to the subagent
- Do not run `make check test` or other verification — the subagent does that
- Do not use `Bash` for anything except the context-gathering `git` calls at the top
- Do not expand the plan's scope in response to a blocker — stop and ask the user
