---
date: 2026-04-12
researcher: BJCLark
git_commit: ede3ea0
branch: main
repository: scidept/claude-agentic
topic: "write-artifact sub-skill design"
tags: [research, skills, skill-builder, token-optimization, fork]
status: draft
last_updated: 2026-04-12
---

# Skill Research: write-artifact

A reusable sub-skill that other skills call to serialize structured output to disk. Runs in a forked context so template boilerplate, frontmatter conventions, and path/git-metadata wiring don't burn tokens in the caller's main context.

## Use Cases

1. **Caller has assembled full markdown and needs it on disk with proper frontmatter**
   Example: `research-codebase` has a 5000-token research doc ready. Instead of inlining the template + YAML frontmatter rules in its own SKILL.md, it invokes `write-artifact` with `path`, `body`, and a few custom frontmatter fields. The fork injects `date`, `git_commit`, `branch`, `repository`, creates parent dirs, and writes.
2. **Caller has per-section data and wants a known template assembled**
   Example: `ddd-discover` has event, command, and actor tables as separate chunks. It invokes `write-artifact` with `template=ddd-02-event-catalog` and section payloads. The fork knows the template layout (ordering, headers, frontmatter schema) and emits the final artifact.
3. **Anti-pattern to avoid**: in-place section edits of existing artifacts (`iterate-plan`, `improve-issue`). Those are append/merge operations with different semantics — keep them out of v1.
4. **Anti-pattern to avoid**: external posters (Linear comments, `gh pr edit`). `linear-ticket-status-sync` already owns that flow. This skill is disk-only.

## Category

Workflow Automation (non-interactive, deterministic I/O helper). Runs fully in a fork — no `AskUserQuestion`, no user-facing output beyond a one-line return.

## Requirements

- **Trigger**: Invoked via the `Skill` tool by another skill. Not normally called directly by a user.
- **Input** (passed as `args` string, parsed by the fork):
  - `path:` target output path (may contain `{{date}}` placeholder)
  - `template:` optional template name (e.g. `plan`, `research`, `ddd-01-alignment`, `pm-build-plan`, `pr-description`)
  - `frontmatter:` key/value block of custom fields merged with auto-injected fields
  - `---BODY---` delimiter followed by either the complete markdown body (generic mode) or section payloads keyed by section name (template mode)
- **Output**: Writes file to disk. Returns a one-line status: `Wrote N bytes to <path>`.
- **Tools**: `Read` (to load templates), `Write` (to emit artifact), `Bash(git *)` (commit hash, branch), `Bash(mkdir *)` (ensure parent dir exists). No `AskUserQuestion`, no `Task` — fork stays lean.
- **Interactions**: None. Fork is non-interactive by design; this is what justifies `context: fork`.

## Similar Skills

- **create-plan**, **research-codebase**, **pm-synthesize**, **describe-pr**: pattern to borrow — each has a `templates/` directory with an explicit template file. `write-artifact` consolidates that pattern so the callers can drop their inline template-handling prose.
- **ddd-align**..**ddd-define**: pattern to borrow — all six DDD skills write to `research/ddd/NN-*.md` with a fixed frontmatter schema that includes `ddd_step`, `ddd_step_name`, `domain`, `source`. The fork should understand this family so callers just pass domain + body.
- **linear-ticket-status-sync**: differentiate from — it writes comments to external systems, not files on disk. Out of scope.
- **iterate-plan**, **improve-issue**: differentiate from — in-place edits / appends. Not a new-file write. Out of scope for v1.

## Existing Artifact Inventory (from survey)

| Skill | Artifact path | Template file today |
|---|---|---|
| create-plan | `thoughts/shared/plans/YYYY-MM-DD-*.md` | yes |
| iterate-plan | same, in-place edit | n/a (out of scope) |
| research-codebase | `research/YYYY-MM-DD-[topic].md` | yes |
| pm-synthesize | `research/pm/build-plan.md` | yes |
| describe-pr | `prs/{number}_description.md` | yes (repo template or default) |
| ddd-align | `research/ddd/01-alignment.md` | no (inline) |
| ddd-discover | `research/ddd/02-event-catalog.md` | no (inline) |
| ddd-decompose | `research/ddd/03-sub-domains.md` | no (inline) |
| ddd-strategize | `research/ddd/04-strategy.md` | no (inline) |
| ddd-connect | `research/ddd/05-context-map.md` | no (inline) |
| ddd-define | `research/ddd/06-canvases.md` | no (inline) |
| ddd-plan | `plans/YYYY-MM-DD-ddd-[context].md` | reuses create-plan |

## Token Savings Estimate

Per invocation, a caller replaces ~30–50 lines of template/frontmatter instructions with one `Skill` call. Rough savings:

- Template prose (sections, header ordering, table columns): ~300 tokens
- Frontmatter schema + date/commit/branch wiring instructions: ~150 tokens
- Directory-creation / path-formatting prose: ~100 tokens
- Post-write validation / reporting prose: ~100 tokens

Total: **~650 tokens per invocation**, lifted out of ~12 caller skills. Cross-invocation amortization: callers get shorter SKILL.md files that load faster on every trigger.

The savings are real **in the caller's main context**, because fork context is separate. This is the core motivation.

## Conventions to Follow

- **Frontmatter**: `---` delimiters on their own lines; `name`, `description`, `model`, `allowed-tools`, `argument-hint` — keep `allowed-tools` minimal (`Read`, `Write`, `Bash(git *)`, `Bash(mkdir *)`).
- **`context: fork`**: required for the token-savings premise. Compatible because the skill does not need `AskUserQuestion` (memory note at `MEMORY.md:4-5`).
- **Model**: `sonnet` is enough — this is deterministic text munging. Opus is overkill.
- **Templates directory**: `skills/write-artifact/templates/` with one file per known artifact family.
- **References directory**: `skills/write-artifact/references/api.md` documents the `args` schema so callers (and humans adding new templates) have a single place to look.
- **Sync path**: edits to `skills/` must be followed by `scripts/install.sh` — do NOT create `.claude/` symlinks (memory note at `MEMORY.md:4-6`).
- **Date/git metadata**: auto-gathered via `Bash(git *)` — callers never compute it. `{{date}}` placeholder in `path:` is replaced with `YYYY-MM-DD`.

## Open Design Questions for Plan Phase

- **V1 template breadth**: ship all ~10 known templates, or start with 2–3 (generic, plan, research) and migrate callers over time? Migrating every skill in one PR is risky.
- **Args parsing robustness**: define a strict minimal grammar (keys on their own lines, `---BODY---` delimiter) and reject ambiguous input rather than get clever. Fork should fail loudly if input is malformed.
- **Failure modes to handle**: target path outside repo root, parent dir creation race, git commands fail (detached HEAD, no commits yet, no git repo). Fork returns a clear error string, not a partial write.
