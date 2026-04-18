---
name: critique
description: "Critique code or a planned approach against a 25-principle checklist covering convention, domain language, DDD, structure, events vs callbacks, and performance. Writes findings to a structured artifact for handoff to a planning skill — never modifies source, never prescribes a fix. Use when reviewing a PR, file, or branch, or when deciding how to structure code before writing it. Triggers on 'critique this', 'review this approach', 'is this idiomatic', 'check my structure', 'critique this PR'."
model: opus
allowed-tools: Read, Grep, Glob, Bash(git *:*), Bash(gh *:*), Bash(mkdir *:*), Task, Write
argument-hint: "[file-path | PR-url | #PR-num | \"approach description\"]"
---

# Critique

Apply a principles checklist to code, a diff, or a proposed approach. Emit a structured findings artifact that a separate planning skill can consume.

**Input**: `$ARGUMENTS`

## Current Context

- **Branch**: !`git branch --show-current`
- **Last Commit**: !`git log -1 --oneline`
- **Modified Files**: !`git status --short`

## Non-negotiable rules

These are structural guarantees of this skill. Do not violate them even if asked.

1. **Never modify source, config, or tests.** The only writable location is `thoughts/critique/` (fallback `.claude/critique/`).
2. **Never emit patches or code diffs in findings.** The `desired shape` field describes the outcome in prose — not code to apply.
3. **Never produce a fix plan.** Fix planning is a separate downstream skill (e.g. `/create-plan`). This skill surfaces findings; someone else decides the response.
4. **Always write the artifact**, even when there are zero findings (the artifact is the handoff contract).

## Steps

### 1. Detect mode

Classify `$ARGUMENTS`:

| Input shape | Mode |
|---|---|
| Existing path on disk | `advise-on-file` |
| `#<num>` or a GitHub PR URL | `review-pr` |
| Empty / whitespace only | `review-branch` |
| Anything else | `advise-on-approach` |

Resolve ambiguity by checking existence on disk first (`ls` / `Glob`). Only fall back to prose mode if the argument is not a path and not a PR reference.

### 2. Gather evidence

Mode-specific:

- **advise-on-file**: `Read` the target file. `Glob` for 1–2 sibling files in the same directory and `Read` one as idiom context. If the target imports or is imported by something obviously relevant, `Grep` for the symbol.
- **review-pr**: `Bash` → `gh pr diff <n>` for the diff; `gh pr view <n> --json title,body,headRefName` for context. Use the raw diff as the unit of review — do not re-read every changed file unless a finding needs pinpoint line context.
- **review-branch**: `Bash` → determine base (`git rev-parse --verify main` else `master`), then `git diff <base>...HEAD`. Same "diff is the unit" rule.
- **advise-on-approach**: no gather. The prose is the input.

### 3. Load principles

`Read` [references/principles.md](references/principles.md) in full. Note each principle's `stack:` tag.

### 4. Filter for stack relevance

Identify the stack from the evidence (language, framework, file extensions, manifest files).

- Keep principles tagged `general`.
- Keep `web` principles if any web layer is involved.
- Keep `rails` principles only if Rails is present (Gemfile lists `rails`, `app/` layout, `.rb` files).
- Keep `rails-runtime` principles only if Puma/Sidekiq configuration is actually in the change.

Do not force-fit. Skipping a principle is a valid outcome.

### 5. Walk the checklist

For each applicable principle, ask its `review prompt` against the evidence. Emit **zero or more** findings. Each finding is one object with these fields (matches the artifact schema):

- `id`: the stable principle id + a short slug (e.g. `P03-fat-model-thin-controller`).
- `location`: `file:line` when available; otherwise `<diff-hunk-header>` or `<approach paragraph #>`.
- `violation`: 1–2 sentences describing what in the evidence trips the principle.
- `desired shape`: 1–2 sentences describing what "good" looks like — in prose, not code.
- `severity`: `must-fix` | `should-fix` | `consider` (see rubric below).

**Severity rubric**:
- `must-fix`: correctness, safety, or data-integrity risk (N+1 on a hot path, reach-through past an aggregate root, missing FK/NOT NULL/unique on a column the app assumes).
- `should-fix`: idiom / convention miss with material maintainability cost (service object where a concern fits, verb-shaped controller action, boolean flag where a record belongs).
- `consider`: stylistic or longer-term (callback chain that *could* be an event, primitive that *could* be a value object).

Be sparing. A critique with 40 `consider` items is noise. Collapse related findings under the most apt principle.

### 6. Write the artifact

Always, regardless of finding count.

1. **Pick location**:
   - If `thoughts/` exists at the repo root → `thoughts/critique/`.
   - Else → `.claude/critique/`.
   - Create the directory if missing: `Bash` → `mkdir -p <dir>`.
2. **Pick filename**: `<YYYY-MM-DD-HHMM>-<slug>.md` where `<slug>` is:
   - `advise-on-file`: filename stem.
   - `review-pr`: `pr-<num>`.
   - `review-branch`: current branch name, sanitized.
   - `advise-on-approach`: first 4 words of the prose, lowercased and hyphenated.
3. **Fill** [templates/critique-template.md](templates/critique-template.md) with the findings, frontmatter `counts`, and summary.
4. **Write** via the `Write` tool.

### 7. Print handoff summary

Five lines, no more:

```
Critique saved: <path>
Target: <target>
Findings: <N must-fix, M should-fix, K consider>
Top issue: <one-liner on the single most material finding, or "no material findings" if empty>
Next: run /create-plan or /implement-plan against <path>
```

That last line is the explicit handoff. Downstream skills consume the artifact, not the chat output.

## Invocation patterns

- **Direct**: `/critique <arg>` from the main session.
- **From a main-session skill**: that skill can call `Task(subagent_type: "general-purpose", prompt: "/critique <arg>")` and then read the artifact path from stdout.
- **From a subagent that can't invoke skills** (e.g. `plan-implementer`): the subagent should `Read` `~/.claude/skills/critique/references/principles.md` directly and apply the checklist itself before writing files. The reference file is designed to be self-contained for this case — it includes the rule, stack tag, and review prompt for each principle.

## Guidelines

1. **Be specific.** A finding without a `location` is not a finding. If you can't point at evidence, drop it.
2. **Cite the principle by id.** Stable ids let downstream tools reference findings without re-reading the principles file.
3. **Include strengths.** The artifact has a `Strengths` section — use it. A reviewer that only lists faults gets ignored.
4. **No "you should".** Findings describe the code or the approach, not the author. `violation` names what the evidence does; `desired shape` names what good looks like.
5. **Stop at the boundary.** When the critique is tempting to become a fix plan, that is the signal to stop writing and hand off.
