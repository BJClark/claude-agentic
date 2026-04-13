---
name: write-artifact
description: "Write, save, or serialize a markdown artifact (plan, research doc, PR description, DDD canvas, PM build plan) to disk with auto-injected frontmatter (date, git commit, branch, repository) and optional named templates. Use when another skill needs to emit a structured markdown file — e.g. 'save this plan', 'write the research doc', 'persist the DDD alignment', 'emit a PR description'. Invoked via the Skill tool from other skills to keep template boilerplate out of the caller's main context."
model: sonnet
context: fork
allowed-tools: Read, Write, Bash(git *), Bash(mkdir *), Bash(date *), Bash(basename *)
argument-hint: [args block — see references/api.md]
---

# Write Artifact

Serialize a markdown artifact to disk with auto-injected git metadata and optional named templates. Called by other skills via the `Skill` tool so template boilerplate and frontmatter conventions live here, not in every caller.

**Input**: $ARGUMENTS

## Current Context

- **Branch**: !`git branch --show-current 2>/dev/null || echo unknown`
- **Commit**: !`git rev-parse HEAD 2>/dev/null || echo unknown`
- **Repository root**: !`git rev-parse --show-toplevel 2>/dev/null || echo .`
- **Date**: !`date +%Y-%m-%d`

## Args Format

The `$ARGUMENTS` string MUST match this shape:

```
path: <relative/path/to/output.md>
template: <template-name>        # optional; omit for generic mode
frontmatter:
  <key>: <value>
  <key>: <value>
---BODY---
<markdown body>
```

- `path:` is relative to the repo root. It MAY contain `{{date}}` which is substituted with `YYYY-MM-DD`.
- `template:` must match a file in `templates/` (without `.md`). Known names: `generic`, `plan`, `research`, `pr-description`, `pm-build-plan`, `ddd-01-alignment`, `ddd-02-event-catalog`, `ddd-03-sub-domains`, `ddd-04-strategy`, `ddd-05-context-map`, `ddd-06-canvases`.
- `frontmatter:` is a simple YAML-shaped block (`key: value`, one per line, two-space indent). Values don't need quotes unless they contain `:` or start with a special char.
- `---BODY---` is a literal delimiter on its own line. Everything after it is the markdown body.

See [references/api.md](references/api.md) for concrete examples and the template contract.

## Process

### 1. Parse args

Split `$ARGUMENTS` on the first `\n---BODY---\n`:
- Header block before the delimiter contains `path:`, optional `template:`, and an optional `frontmatter:` block
- Body is everything after (preserve whitespace verbatim)

Extract:
- `path` (required, string)
- `template` (optional, string — default `generic`)
- `frontmatter_fields` (dict — empty if the block is absent)

If `path:` is missing, return `Error: missing required 'path:' field` and stop. If body is empty, return `Error: empty body` and stop.

### 2. Gather auto metadata

These values are already in the `## Current Context` block above — reuse them:
- `date` (today, YYYY-MM-DD)
- `last_updated` (same as `date`)
- `git_commit` (full SHA, or `unknown`)
- `branch` (or `unknown`)
- `repository` (basename of repository root)

### 3. Resolve path

- Replace `{{date}}` in `path` with `date`
- Treat `path` as relative to the repository root
- Compute parent directory; record it for Step 6

### 4. Load template

Read `templates/<template>.md`. If the file does not exist, return `Error: unknown template '<name>'` and stop.

### 5. Assemble content

Substitute placeholders in the template in this exact order:

1. For each `{{<key>}}` in the template **except `{{body}}`**:
   - If `<key>` is one of `date`, `git_commit`, `branch`, `repository`, `last_updated` → use the auto-injected value
   - Else if `<key>` is present in caller `frontmatter_fields` → use that value
   - Else → substitute the literal string `TBD`. Never emit a raw `{{...}}` token.
2. For any caller `frontmatter_fields` keys that did NOT appear as a `{{placeholder}}` in the template, append them as additional YAML lines immediately before the closing `---` of the frontmatter block. This lets callers add ad-hoc metadata without editing templates.
3. Finally, substitute `{{body}}` exactly once with the caller's body verbatim. Do NOT scan the substituted body for further `{{...}}` tokens — if the body contains literal `{{foo}}`, it must be preserved as-is.

### 6. Write file

- If the parent directory doesn't exist, run `mkdir -p <parent>`
- Write the assembled content via the Write tool
- Record the byte count of the content written

### 7. Return result

Return exactly one line to the caller:
- Success: `Wrote <N> bytes to <relative-path>`
- Failure: `Error: <reason>`

Emit no other prose. Callers only need this single line.

## Guidelines

1. **Silent by default**: the fork runs in a subagent — keep commentary minimal. Return the single status line.
2. **Deterministic**: same input produces the same output. Do not reword the caller's body.
3. **Fail loudly and fast**: malformed input returns an error, never a partial write.
4. **Preserve the body verbatim**: template substitution only touches `{{placeholder}}` tokens.
5. **No interactivity**: this skill is non-interactive by design. Fork context does not have `AskUserQuestion`.
6. **Template authors**: every template MUST include a `{{body}}` placeholder and a frontmatter block with at least `date`, `git_commit`, and `branch` placeholders. Add template-fixed fields directly; use `{{placeholder}}` only for caller-provided values. See [references/api.md](references/api.md) for the template contract.
