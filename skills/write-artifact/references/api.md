# write-artifact API Reference

Caller contract for invoking the `write-artifact` skill via the `Skill` tool.

## Invocation

```
Skill(name="write-artifact", args=<args-block>)
```

The `args` field is a single string following the shape below.

## Args Shape

```
path: <relative/path/to/output.md>
template: <template-name>
frontmatter:
  <key>: <value>
  <key>: <value>
---BODY---
<full markdown body of the artifact>
```

### Required fields

- `path:` — path relative to repository root. `{{date}}` in the path is substituted with today's date (YYYY-MM-DD).
- Body — markdown content after `---BODY---`. Must not be empty.

### Optional fields

- `template:` — name of a template in `templates/`. Defaults to `generic`. See [Known Templates](#known-templates) below.
- `frontmatter:` — YAML-shaped block of custom metadata. Values are substituted into `{{placeholder}}` tokens in the template, or appended as extra frontmatter lines if no matching placeholder exists.

### Auto-injected fields (never pass these yourself)

The fork injects these; they're available as `{{placeholder}}` in every template:

- `{{date}}` — today, YYYY-MM-DD
- `{{last_updated}}` — same as `date`
- `{{git_commit}}` — full SHA of HEAD (or `unknown`)
- `{{branch}}` — current git branch (or `unknown`)
- `{{repository}}` — basename of repository root

## Return Value

A single line of text returned to the caller:

- Success: `Wrote 4821 bytes to thoughts/shared/plans/2026-04-12-auth-refactor.md`
- Failure: `Error: <reason>`

Callers should check for the `Error:` prefix before proceeding.

## Examples

### Generic artifact (no template)

Caller has a full markdown body ready and just needs minimal frontmatter.

```
path: research/{{date}}-billing-model-notes.md
frontmatter:
  topic: "Billing domain model"
  status: draft
---BODY---
# Billing Domain Notes

## Summary
...
```

### Plan artifact

```
path: thoughts/shared/plans/{{date}}-auth-refactor.md
template: plan
frontmatter:
  title: "Auth Refactor"
  ticket: ENG-1234
  status: draft
---BODY---
## Overview
...

## Current State
...

## Phases
...
```

### DDD alignment artifact

```
path: research/ddd/01-alignment.md
template: ddd-01-alignment
frontmatter:
  domain: Billing
  status: complete
  source: "thoughts/shared/tickets/billing-prd.md"
---BODY---
## Business Context
...

## Assumptions
- ...

## Open Questions
- ...
```

## Known Templates

| Template | Used by | Output path pattern |
|---|---|---|
| `generic` | any | caller-defined |
| `plan` | create-plan, ddd-plan, iterate-plan | `thoughts/shared/plans/{{date}}-*.md` or `plans/{{date}}-*.md` |
| `research` | research-codebase | `research/{{date}}-*.md` or `thoughts/shared/research/{{date}}-*.md` |
| `pr-description` | describe-pr | `prs/{pr-number}_description.md` |
| `pm-build-plan` | pm-synthesize | `research/pm/build-plan.md` |
| `ddd-01-alignment` | ddd-align | `research/ddd/01-alignment.md` |
| `ddd-02-event-catalog` | ddd-discover | `research/ddd/02-event-catalog.md` |
| `ddd-03-sub-domains` | ddd-decompose | `research/ddd/03-sub-domains.md` |
| `ddd-04-strategy` | ddd-strategize | `research/ddd/04-strategy.md` |
| `ddd-05-context-map` | ddd-connect | `research/ddd/05-context-map.md` |
| `ddd-06-canvases` | ddd-define | `research/ddd/06-canvases.md` |

## Template Author Contract

When adding a new template file in `templates/`:

1. Include a YAML frontmatter block delimited by `---` on its own lines.
2. Include placeholders for `{{date}}`, `{{git_commit}}`, `{{branch}}` in the frontmatter (these are auto-injected).
3. Use `{{<field>}}` for any caller-provided fields. The caller passes them in the `frontmatter:` block of the args.
4. Include exactly one `{{body}}` placeholder where the caller's markdown body should appear.
5. Use `TBD` in the template wherever a required value might be absent — the fork substitutes literal `TBD` for unprovided placeholders.
6. Fixed values (e.g. `ddd_step: 1`) go directly in the frontmatter without placeholders.

## Failure Modes

The fork returns an `Error: ...` line (and writes nothing) when:

- `path:` is missing
- Body (after `---BODY---`) is empty
- `template:` names a file that does not exist in `templates/`

The fork tolerates (substitutes `unknown`):

- Not in a git repo
- Detached HEAD
- No commits yet
- `git` binary unavailable

## Design Notes

- Why a fork? — template boilerplate and frontmatter schemas don't need to live in every caller's main context. By running in a fork, those instructions load only when this skill is invoked.
- Why no `AskUserQuestion`? — it's unavailable in subagents ([Claude Code docs](https://code.claude.com/docs/en/agent-sdk/user-input#limitations)). Writes are deterministic, so no interactivity is needed.
- Why return a single line? — callers' main context should not absorb the full artifact content or a long status report. One line is enough to confirm success and surface the path.
