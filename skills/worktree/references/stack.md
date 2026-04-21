# Worktree Stack Model

## Why shared Docker + namespacing

Running a separate Postgres and Redis container per worktree wastes 100–300 MB of RAM per branch and makes it impossible to `psql` across them. The shared-container model keeps one of each and partitions state *inside* the services:

- **Postgres** (`localhost:5488`) — isolation via database name.
- **Redis** (`localhost:6388`) — isolation via DB index (`0..15`).

Only **one** shared container of each runs. It is started once from the main checkout via `pitchfork start postgres redis`.

## Naming scheme

| Thing | Pattern | Example |
|---|---|---|
| Worktree path | `<repo-root>/.worktrees/<slug>` | `~/Developer/ultra/.worktrees/feature-x` |
| Git branch | `<slug>` | `feature-x` |
| Postgres dev DB | `<repo>_<slug_underscored>_development` | `ultra_feature_x_development` |
| Postgres test DB | `<repo>_<slug_underscored>_test` | `ultra_feature_x_test` |
| Redis DB index | next free `1..15` | `3` → `redis://localhost:6388/3` |
| Rails port | auto-scan from `3088` | first worktree gets 3088, next 3089… |

The slug in the branch name uses hyphens (`feature-x`). The slug in the Postgres DB name uses underscores (`feature_x`). Translation is mechanical — replace `-` with `_`.

**Why worktrees live inside the repo root:** Claude Code's permission sandbox is rooted at the session's launch CWD. A worktree at `$HOME/wt/<repo>/<slug>` is *outside* that root, so every `Bash`, `Read`, `Edit` hits a permission prompt — defeating the purpose of running the agent inside the worktree at all. Placing the worktree at `<repo-root>/.worktrees/<slug>` keeps it inside the permission scope, so nothing new prompts. `.worktrees/` must be in `.gitignore`.

## Redis index allocation

Fixed allocations:

- `0` — main checkout (reserved, never hand out).
- `15` — reserved for ad-hoc scripting / REPL sessions.
- `1..14` — worktree pool.

Allocation algorithm:

1. `rg -N '^REDIS_URL' "$(git rev-parse --show-toplevel)/.worktrees/"` across every sibling `mise.local.toml`.
2. Parse the `/<n>` suffix into a set of used indexes.
3. Pick the smallest integer in `1..14` not in that set.
4. If the pool is exhausted, do not overload — ask the user which worktree to retire.

## Per-worktree file: `mise.local.toml`

Gitignored. Lives at the worktree root. Minimal shape:

```toml
[env]
DB_NAME = "ultra_feature_x_development"
TEST_DB_NAME = "ultra_feature_x_test"
REDIS_URL = "redis://localhost:6388/3"
```

The committed `mise.toml` reads these env vars and threads them through `database.yml`, `config/cable.yml`, and `config/initializers/redis.rb`. Do **not** edit those files per worktree — if a new env variable is needed, add it to the committed config once and reference it here.

## jdx stack roles

| Role | Tool | Notes |
|---|---|---|
| Tool versions (ruby, node) | mise | `mise.toml [tools]` |
| Project env vars | mise | `mise.toml [env]` / `mise.local.toml [env]` |
| Task runner | mise | `mise run <task>` — replaces make/rake for dev ergonomics |
| Secrets | fnox | Encrypted, safe to commit. Never put secrets in `mise.local.toml`. |
| Rails web server | pitchfork | Replaces puma. Declared in `pitchfork.toml`. |
| Process manager | fnox | Replaces foreman. Declared in `fnox.toml` (or embedded in mise tasks). |
| Background services (pg, redis) | pitchfork | Wraps `docker compose` under the hood |

## The `worktree:new` mise task

The canonical bootstrap. Defined in the repo's committed `mise.toml` (roughly):

```toml
[tasks."worktree:new"]
usage = '''
  arg "<slug>" help="feature slug (lowercase, hyphens)"
'''
run = '''
  set -euo pipefail
  ROOT=$(git rev-parse --show-toplevel)
  REPO=$(basename "$ROOT")
  SLUG="$usage_slug"
  SLUG_U=$(echo "$SLUG" | tr '-' '_')
  WT="$ROOT/.worktrees/$SLUG"

  # 0. Ensure .worktrees/ is gitignored
  grep -qxF '.worktrees/' "$ROOT/.gitignore" 2>/dev/null || echo '.worktrees/' >> "$ROOT/.gitignore"

  # 1. Allocate redis index
  USED=$(rg -No '/([0-9]+)"' "$ROOT/.worktrees" 2>/dev/null | awk -F/ '{print $2}' | tr -d '"' | sort -u)
  for i in $(seq 1 14); do
    if ! echo "$USED" | grep -qx "$i"; then INDEX=$i; break; fi
  done

  # 2. Create worktree
  git worktree add -b "$SLUG" "$WT"

  # 3. Write mise.local.toml
  cat > "$WT/mise.local.toml" <<EOF
  [env]
  DB_NAME = "${REPO}_${SLUG_U}_development"
  TEST_DB_NAME = "${REPO}_${SLUG_U}_test"
  REDIS_URL = "redis://localhost:6388/${INDEX}"
  EOF

  # 4. Bootstrap app
  cd "$WT"
  mise install
  mise run db:create db:migrate
'''
```

If this task is missing or broken, the SKILL.md workflow reproduces the same steps manually.

## Anti-patterns

- Placing worktrees outside the repo root (`$HOME/wt/<repo>/<slug>`, a sibling directory, `/tmp`, etc.) — outside Claude Code's permission sandbox, so every tool call prompts. Always use `<repo-root>/.worktrees/<slug>`.
- Starting a per-worktree Postgres container (`docker run postgres:15 -p 5489:5432`) — defeats the shared-state model.
- Overloading a Redis index (two worktrees pointed at `/3`) — silent cross-contamination in background jobs and ActionCable.
- Hardcoding `PORT=3000` — breaks the auto-scan and collides with the main checkout.
- Committing `mise.local.toml` — leaks per-developer paths and collides on merge.
- Using foreman/puma directly — bypasses pitchfork's process supervision and fnox's env handling.
