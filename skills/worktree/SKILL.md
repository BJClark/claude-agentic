---
name: worktree
description: "Create a new git worktree for a Rails feature branch — placed inside the project root at `.worktrees/<slug>/` so Claude Code's permission sandbox still covers it — using the jdx stack (mise/pitchfork/fnox) with shared Docker services namespaced by per-worktree Postgres DB name and Redis DB index. Use when the user wants a fresh isolated workspace for a feature, spike, or PR review without spinning up duplicate Postgres/Redis containers. Triggers on 'new worktree', 'spin up a worktree', 'create a worktree for feature X', 'worktree:new'."
model: sonnet
allowed-tools: Read, Grep, Glob, Write, Bash, AskUserQuestion, TodoWrite
argument-hint: [feature-slug]
---

# Worktree Bootstrap (jdx stack)

Ultrathink about the workspace the user needs: a new git worktree for a Rails project that shares a single Postgres container (port 5488) and a single Redis container (port 6388) across all worktrees, isolated by a unique database name and a unique Redis DB index. The only per-worktree state is `mise.local.toml` (gitignored) — everything else flows from the shared jdx stack.

**Location rule (important):** worktrees must live *inside* the main checkout at `<repo-root>/.worktrees/<slug>/`. Not `~/wt/<repo>/<slug>`, not a sibling directory. Reason: Claude Code's permission sandbox is rooted at the session's launch CWD. A worktree at `~/wt/...` is outside that root, so every `Bash`, `Read`, `Edit`, etc. prompts the user for permission — which defeats the purpose of the worktree. A worktree at `<repo-root>/.worktrees/<slug>/` inherits the project's permission scope.

**Input**: `$ARGUMENTS`

## Current Context

- **Branch**: !`git branch --show-current`
- **Repo root**: !`git rev-parse --show-toplevel 2>/dev/null`
- **Repo name**: !`basename "$(git rev-parse --show-toplevel 2>/dev/null)"`
- **Existing worktrees**: !`git worktree list 2>/dev/null`
- **mise tasks**: !`mise tasks 2>/dev/null | head -20`

## Stack Model (read before acting)

Consult [references/stack.md](references/stack.md) for the full namespacing model. The short version:

- **One** Postgres (`localhost:5488`) and **one** Redis (`localhost:6388`) — do not start new containers.
- Each worktree gets a unique Postgres DB name: `<repo>_<slug>_development` + `<repo>_<slug>_test`.
- Each worktree gets a unique Redis DB index in the range `0..15`. Index `0` is reserved for the main checkout.
- Rails Puma is replaced by **pitchfork**; foreman is replaced by **fnox**.
- Rails' port auto-scans from `3088` upward, so port assignment is automatic — do not set `PORT`.
- Per-worktree config lives in `mise.local.toml` (gitignored). Everything else is committed.

If the user's request contradicts the stack model (e.g. "spin up a new Postgres on 5433"), stop and flag the conflict before acting.

## Initial Response

1. **If a feature slug is provided**: Begin the bootstrap flow at step 1.
2. **If no slug**: Ask for one using AskUserQuestion — options:
   - a feature slug like `feature-x`
   - a ticket id like `eng-1696`
   - cancel

The slug must be lowercase, alphanumeric + hyphens only. If the user provides something else, normalize it (e.g. `ENG-1696 New Billing` → `eng-1696-new-billing`) and confirm before proceeding.

## Process

### 1. Prefer the bundled mise task

Before doing anything manual, check for a `worktree:new` task:

```bash
mise tasks | grep -E '^worktree:new'
```

If it exists, delegate to it — it encodes the canonical bootstrap sequence (worktree add, DB name allocation, Redis index allocation, `mise.local.toml` write, `db:create db:migrate`, pitchfork warm-up):

```bash
mise run worktree:new -- <slug>
```

**Verify** that the task places the worktree at `<repo-root>/.worktrees/<slug>`. If the task still points to `$HOME/wt/...`, stop and flag it — the task needs to be updated in the committed `mise.toml` before use (see `references/stack.md` for the correct shape). Running a stale task recreates the permission-prompt problem the location rule exists to prevent.

If the task exists and is correctly located, skip to step 6 (hand-off). Only fall through to steps 2–5 if the task is missing or fails.

### 2. Ensure `.worktrees/` is gitignored

From the main checkout:

```bash
ROOT=$(git rev-parse --show-toplevel)
grep -qxF '.worktrees/' "$ROOT/.gitignore" 2>/dev/null || echo '.worktrees/' >> "$ROOT/.gitignore"
```

Commit this gitignore change separately from any feature work, or let the user decide when to commit it — but do not leave `.worktrees/` untracked and ungitignored, or `git status` in the main checkout will show every worktree's files as untracked.

### 3. Allocate a Redis DB index

Scan sibling worktrees inside `.worktrees/` for used indexes so the new one doesn't collide:

```bash
ROOT=$(git rev-parse --show-toplevel)
rg -N '^REDIS_URL' "$ROOT/.worktrees/" 2>/dev/null
```

Parse the `/<n>` suffix from each URL (e.g. `redis://localhost:6388/3` → `3`). The main checkout always uses `0`. Pick the smallest unused index in `1..15`. If all 16 are taken, stop and ask the user which worktree to retire — do not overload an index.

### 4. Create the worktree

```bash
ROOT=$(git rev-parse --show-toplevel)
SLUG=<slug>
WT="$ROOT/.worktrees/$SLUG"
git worktree add -b "$SLUG" "$WT"
```

If the branch already exists on a remote, use `git worktree add "$WT" "origin/$SLUG"` instead.

**Do not** use `$HOME/wt/...`, a sibling directory, or any path outside `$ROOT`. See the location rule at the top of this file.

### 5. Write `mise.local.toml`

Use [templates/mise.local.toml](templates/mise.local.toml) as a scaffold. The file is gitignored. Fill in:

- `DB_NAME = "<repo>_<slug_underscored>_development"` (hyphens in the slug become underscores because Postgres dislikes them)
- `TEST_DB_NAME = "<repo>_<slug_underscored>_test"`
- `REDIS_URL = "redis://localhost:6388/<index>"`

Then run inside the new worktree:

```bash
cd "$WT"
mise install
mise run db:create db:migrate   # or whatever the repo's setup task is
```

### 6. Hand-off

Print the next-step commands for the user:

```
cd .worktrees/<slug>
pitchfork start   # boots Rails (pitchfork) + fnox-managed procs
```

Rails will land on the next free port starting at 3088 — tail `log/development.log` or check `pitchfork status` to see which one.

Because the worktree lives inside the project root, a running Claude session in the main checkout can operate on it without new permission prompts.

## Guidelines

1. **Worktrees live inside the project root** at `<repo-root>/.worktrees/<slug>/`. Never `$HOME/wt/...`, never a sibling directory. Reason: Claude Code's permission sandbox is rooted at the session's launch CWD — a worktree outside that root prompts for permission on every tool call. Worktrees created under the old `~/wt/<repo>/<slug>` layout continue to function, but new ones must use the new path.
2. **`.worktrees/` must be gitignored** in the main checkout — otherwise `git status` lists every worktree's files as untracked. Ensure this before (or at the same time as) creating the first worktree.
3. **Never start a new Postgres or Redis container.** If one isn't running, start the shared ones via `pitchfork start postgres redis` in the main checkout — not per-worktree.
4. **Never commit `mise.local.toml`.** Verify it's in `.gitignore` before writing.
5. **Slug underscoring matters.** Git branches and directories use hyphens; Postgres DB names use underscores. Keep them in sync so the slug is recoverable from either.
6. **Prefer `mise run worktree:new`** over manual steps — but verify it targets `.worktrees/` first. An outdated task pointing to `~/wt/` must be fixed (see `references/stack.md`) before use.
7. **Defer to jdx-stack skill** for any command substitution (`foreman → fnox`, `puma → pitchfork`, `npm run → mise run`). Don't duplicate that logic here.
8. **Redis index 0 is reserved.** Don't allocate it even if it appears free in a scan.
9. **Surface conflicts early.** If the slug already exists as a branch, worktree, or DB name, stop and ask.

## Troubleshooting

- **`fatal: '<slug>' is already checked out`** — `git worktree list` to find where; either reuse it or pick a different slug.
- **`PG::ConnectionBad` on port 5488** — shared Postgres container isn't running. From the main checkout: `pitchfork start postgres`.
- **`Redis::CannotConnectError` on 6388** — same fix with `redis` in place of `postgres`.
- **Rails bound to 3000 instead of 3088+** — someone set `PORT` explicitly. Unset it; the repo's config auto-scans.
- **All 16 Redis indexes taken** — `git worktree list` and retire stale ones with `git worktree remove`, then rerun.
- **Claude keeps prompting for permissions inside the worktree** — the worktree is at `$HOME/wt/...` (old path) instead of `<repo-root>/.worktrees/<slug>`. Either recreate it at the new location, or restart Claude with `--add-dir` pointing at the worktree. New invocations of this skill always target the new path.
- **`git status` in the main checkout shows `.worktrees/` files as untracked** — `.worktrees/` is not in `.gitignore`. Run `echo '.worktrees/' >> .gitignore && git add .gitignore` in the main checkout.
