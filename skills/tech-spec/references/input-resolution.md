# Input resolution — Linear ticket / PR / research doc

Referenced from `SKILL.md` Step 1. The skill accepts four input shapes; this reference gives the exact recipe for each.

## Detection order

Apply these regexes against `$ARGUMENTS` (first match wins):

1. **PR number** — `^#?(\d+)$` where the number refers to a PR in the current repo
2. **PR URL** — `github\.com/[^/]+/[^/]+/pull/(\d+)`
3. **Linear ticket ID** — `(?i)(ENG|PLAT|OPS|STELLAR|MEERKAT|KICKPLAN|AURA)-\d+`
4. **Research doc path** — matches `*.md`, exists on disk
5. **Free-form topic** — anything else (quoted or unquoted prose)

## PR input

```bash
gh pr view <n> --json number,title,body,url,state,headRefName,baseRefName,author,files,additions,deletions,commits,labels
```

From the payload, extract:

- **Title + body** → feeds the Scoping Brief draft (Step 2).
- **`headRefName`** → try `(?i)(ENG|PLAT|OPS|STELLAR|MEERKAT|KICKPLAN|AURA)-\d+` to recover a Linear ticket; if found, **also** fetch the ticket (see below) and merge.
- **`files[]`, `additions`, `deletions`** → signal of scope and blast radius; used by the candidate-generation subagents to target searches.
- **`commits[]`** → first commit message often hints at the problem statement.
- **`labels`** → filter for scope hints (`type:migration`, `scope:data-model`, etc.).

**If `state == MERGED` or `CLOSED`**: the PR is a retrospective reference, not the target. Warn the user; still proceed if they confirm.

**If PR branch matches an existing research doc** (`research/*-<ticket-id>*.md`): read the research doc fully and treat it as the prior-art source.

## Linear ticket input

Use the Linear MCP tools. See [../../linear/references/ids.md](../../linear/references/ids.md) for workspace / team IDs.

Fetch:

```
mcp__linear__get_issue(id: "<TICKET>")
```

From the payload, extract:

- **Title + description** → Scoping Brief draft.
- **Labels + priority + state** → triage signal for the framing questions (e.g. `priority: urgent` flags timeline A8; `label: security` flags failure mode A7).
- **Assignee** → used in "Open questions" ownership defaults.
- **Linked PRs / branches** → if any, fetch each via `gh pr view` per above.
- **Sub-issues** → read titles only; they inform scope boundary.
- **Comments** → read the last 5–10 to pick up constraints added after the ticket was written.

**If the ticket has `type: bug`**: the tech spec is usually overkill — suggest the user consider `/debug-issue` first. Don't block; offer.

## Research doc input

```bash
test -f "<path>" && cat "<path>"  # via Read tool, no limit/offset
```

- Frontmatter → metadata (date, topic, linked ticket).
- If frontmatter references a ticket, fetch the ticket too.
- If the research doc itself has a "Proposed approaches" section, treat those as seed candidates (Step 4 should still generate the full set but can reference them).

## Free-form topic

No fetch needed. Warn the user once:

> Heads up — without a ticket or PR, I'm working from your prose alone. Tech specs grounded in a ticket or PR tend to be materially better because they inherit scope, acceptance criteria, and prior discussion. If a ticket exists, paste it in.

Then proceed.

## Merge rule (multiple inputs resolve)

When PR and Linear ticket both resolve (PR branch contains ticket ID, or Linear ticket links a PR):

1. Use the **Linear ticket** as the authoritative problem statement.
2. Use the **PR** as evidence of current progress / scope, especially if `state == OPEN`.
3. Flag to the user if ticket description and PR diff disagree in scope.

## Output shape (for Step 2 consumption)

The input-resolver subagent returns a compact bundle:

```
{
  "source": "linear" | "pr" | "research-doc" | "free-form" | "linear+pr",
  "ticket_id": "<ID or null>",
  "pr_number": <n or null>,
  "problem_text": "<concatenated title + description/body>",
  "scope_signals": {
    "files_touched": [...],           // from PR, if any
    "labels": [...],
    "priority": "<linear priority>",
    "size_hint": "S|M|L|XL"           // from PR size or ticket estimate
  },
  "prior_art": {
    "research_docs": ["<path>", ...],
    "prior_tech_specs": ["<path>", ...],
    "linked_prs": [<n>, ...]
  },
  "warnings": ["..."]                 // e.g. "PR is merged", "scope disagrees with ticket"
}
```
