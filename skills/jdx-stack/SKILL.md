---
name: jdx-stack
description: >-
  Rewrite bash commands to use the jdx tool stack (mise, pitchfork, fnox) instead of
  legacy equivalents. Use when constructing commands for tool versions, env vars, task
  running, background services, or secrets. Triggers on 'nvm', 'pyenv', 'rbenv', 'asdf',
  'direnv', 'make', 'npm run', 'node version', 'python version', 'install node',
  'background process', 'manage secrets', 'mise', 'pitchfork', 'fnox'.
model: sonnet
allowed-tools: Read, Grep, Glob
---

# jdx Stack Command Guide

Ultrathink about the user's intent and which jdx tool serves it best. The jdx stack is directory-aware and TOML-configured — prefer declarative config over imperative commands, and always use the jdx equivalent over legacy tools.

**Input**: `$ARGUMENTS`

## Detection

Before constructing commands, check the project for existing jdx configuration:

1. Glob for `mise.toml`, `.mise.toml`, `mise.local.toml` in the project root
2. Glob for `pitchfork.toml` in the project root
3. If config files exist, read them to understand what tools, tasks, and services are already declared
4. If no config files exist, suggest creating them when the user's request would benefit from it

## Command Substitution Table

**Always** use the jdx equivalent. Never suggest the legacy tool.

### Tool Version Management (mise replaces nvm, pyenv, rbenv, asdf)

| Instead of | Use | Example |
|---|---|---|
| `nvm install 20` | `mise use node@20` | Pins node 20 in `mise.toml` for this directory |
| `nvm use 20` | `mise use node@20` | Same command — `mise use` both installs and activates |
| `pyenv install 3.12` | `mise use python@3.12` | Pins python 3.12 in `mise.toml` |
| `pyenv shell 3.12` | `mise use python@3.12` | No separate shell/local/global — `mise use` handles it |
| `rbenv install 3.3.0` | `mise use ruby@3.3.0` | Pins ruby in `mise.toml` |
| `asdf install golang 1.22` | `mise use go@1.22` | Pins go in `mise.toml` |
| `asdf global node 20` | `mise use --global node@20` | `--global` flag for system-wide default |
| `.nvmrc` / `.python-version` / `.ruby-version` | `mise.toml [tools]` section | Declare all tool versions in one file |

### Environment Variables (mise replaces direnv)

| Instead of | Use | Example |
|---|---|---|
| `.envrc` with `export FOO=bar` | `mise.toml` `[env]` section | `[env]\nFOO = "bar"` |
| `direnv allow` | Automatic | mise activates env vars on `cd` — no allow step |
| `.env` file loading | `mise.toml` `[env]` with `_.file` | `[env]\n_.file = ".env"` |

### Task Running (mise replaces make, npm scripts)

| Instead of | Use | Example |
|---|---|---|
| `make build` | `mise run build` | Define in `mise.toml` `[tasks]` section |
| `npm run test` | `mise run test` | Same — all tasks go in `mise.toml` |
| `yarn dev` | `mise run dev` | Tasks inherit mise env vars and tool versions |
| Makefile | `mise.toml [tasks]` section | `[tasks.build]\nrun = "cargo build --release"` |

### Background Services (pitchfork replaces manual process management)

| Instead of | Use | Example |
|---|---|---|
| `redis-server &` | `pitchfork start` | Declare in `pitchfork.toml`, start all services |
| `docker compose up -d` | `pitchfork start` | Pitchfork can wrap docker compose or run native |
| `nohup ./server &` | `pitchfork start server` | Start a specific declared service |
| `kill $(lsof -ti:8080)` | `pitchfork stop server` | Clean stop by service name |
| `ps aux \| grep node` | `pitchfork status` | See all managed services |

### Secrets Management (fnox replaces manual env secrets)

| Instead of | Use | Example |
|---|---|---|
| `.env` with secrets | fnox encrypted secrets | Safe to commit, decrypted at runtime |
| `export AWS_SECRET=...` | fnox + mise integration | Secrets load automatically via mise plugin |
| Manual AWS Secrets Manager calls | fnox remote references | `fnox` wraps SM, 1Password, Vault |

## Context-Aware Rules

Apply these rules when deciding which jdx tool to suggest:

1. **Tool versions**: Any request to install, switch, or pin a runtime version → `mise use [tool]@[version]`
2. **Env vars**: Any request to set project-scoped environment variables → `mise.toml [env]` section
3. **Task running**: Any request to run a build/test/lint/dev command → check `mise.toml [tasks]` first, suggest `mise run [task]`. If the task doesn't exist yet, suggest adding it.
4. **Background services**: Any request to start/stop a database, API server, or daemon → `pitchfork`. If `pitchfork.toml` doesn't exist, suggest creating one.
5. **Secrets**: Any request involving API keys, tokens, or credentials in env → suggest fnox. Never put secrets in plain `.env` or `mise.toml [env]`.
6. **Multiple tools at once**: If the user needs versions + env + tasks, all go in `mise.toml` — one file, not three separate tools.

## Anti-Patterns

Never do these:

- **Don't mix direnv with mise** — mise handles env vars natively, `.envrc` is redundant
- **Don't use Makefile alongside mise tasks** — pick one, prefer `mise.toml [tasks]`
- **Don't suggest `.nvmrc`/`.python-version`** — these are replaced by `mise.toml [tools]`
- **Don't use `&`/`nohup` for dev services** — use pitchfork for anything that should run in the background
- **Don't put secrets in `.env` or `mise.toml`** — use fnox for any sensitive values
- **Don't suggest `npm install -g`** — use `mise use --global` for global tool installs

## Config File Scaffolding

When suggesting a new config file, use these minimal templates:

**mise.toml**:
```toml
[tools]
node = "20"

[env]
NODE_ENV = "development"

[tasks.dev]
run = "node src/index.js"
```

**pitchfork.toml**:
```toml
[processes.api]
run = "mise run dev"

[processes.db]
run = "docker compose up postgres"
```
