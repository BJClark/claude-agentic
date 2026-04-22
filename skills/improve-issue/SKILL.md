---
name: improve-issue
description: "Enrich a Linear or GitHub ticket with acceptance criteria and technical context and advance Linear status to Ready for Research. Use as the first command on a new ticket. Triggers on 'improve this ticket', 'clarify ENG-1234', 'start working on ENG-1234', 'kick off #123', 'get me ready for ENG-1234'."
model: sonnet
allowed-tools: Read, Grep, Glob, Task, AskUserQuestion, Skill, ToolSearch, Bash, mcp__mise-tools__linear_stellar_get_issue, mcp__mise-tools__linear_stellar_save_issue, mcp__mise-tools__linear_stellar_list_issue_statuses, mcp__mise-tools__linear_kickplan_get_issue, mcp__mise-tools__linear_kickplan_save_issue, mcp__mise-tools__linear_kickplan_list_issue_statuses, mcp__mise-tools__linear_meerkat_get_issue, mcp__mise-tools__linear_meerkat_save_issue, mcp__mise-tools__linear_meerkat_list_issue_statuses
argument-hint: [ENG-1234 or #123 or github-url]
---

# Improve Issue

Ultrathink about what an engineer would need to know to create an implementation plan for this ticket. Consider the problem statement, actors, acceptance criteria, technical context, and any ambiguities.

Enrich a Linear or GitHub issue so it's ready for an engineer to start planning and advance its Linear status to "Ready for Research". Read the ticket, check existing project artifacts for relevant context, ask the user clarifying questions, append enriched content back into the ticket description, and advance status (Linear only).

**Input**: $ARGUMENTS

## Current Context

- **Branch**: !`git branch --show-current`
- **Last Commit**: !`git log -1 --oneline`

## Initial Response

1. **If a ticket identifier is provided**: Parse it and begin the workflow
2. **If no parameters**:
```
I'll help you improve an issue so it's ready for an engineer to plan against.

Please provide a ticket identifier:
- Linear: ENG-1234
- GitHub: #123 or a GitHub issue URL
```
Then wait for user input.

## Process Steps

### Step 1: Parse Input & Detect Platform

Determine the platform from the input:

- **Linear**: Input matches `ENG-\d+` (case-insensitive)
- **GitHub**: Input matches `#\d+`, or contains `github.com/.*/issues/\d+`
- **Ambiguous**: If auto-detection fails, get platform using AskUserQuestion:
  - **Platform**: Is this a Linear or GitHub issue?
  - Options: Linear, GitHub

### Step 2: Fetch Ticket Content

**For Linear:**
1. Use `linear` CLI to fetch the ticket into `thoughts/shared/tickets/ENG-xxxx.md`
2. Read the ticket file and all comments
3. Note any existing links or referenced documents

**For GitHub:**
1. Run: `gh issue view <number> --json title,body,comments,labels,assignees`
2. Parse the JSON response
3. Note any existing links or referenced documents

### Step 3: Assess, Clarify, and Update

See [references/enrichment-checklist.md](references/enrichment-checklist.md) for the full Definition-of-Ready checklist (Core + Contextual), ticket-type triage, clarification patterns, preview template, and update procedures.

Follow the checklist to:
1. **Triage ticket type** — classify as feature (user-facing / backend) / bug / chore / migration / spike using the table in the reference. This gates which contextual DoR items apply. If the type is ambiguous, ask directly.
2. **Assess current ticket quality** against the Core criteria table (problem, actors, acceptance, out-of-scope, dependencies, size, edge cases, observability, context, ambiguities). These are always checked.
3. **Pick contextual criteria** that apply given the ticket type — design link, a11y/i18n, NFRs, rollout/flag, data impact, PII/compliance, repro steps, deliverable shape. Skip the ones that don't apply; don't pad the skill with irrelevant questions.
4. **Size check (INVEST-Small)** — if the ticket looks larger than one sprint, flag it via AskUserQuestion *before* drilling into clarifications. An oversized ticket should be split before enrichment, not enriched whole.
5. **Search existing artifacts** for relevant context (via `artifacts-locator` / `artifacts-analyzer` agents).
6. **Work through gaps** interactively using AskUserQuestion. Apply the Brief-then-Ask pattern — every question carries enough context that the user can answer without scrolling back: brief in prose first, then AskUserQuestion with options whose descriptions restate the substance.
7. **Preview proposed additions** and get confirmation.
8. **Update the ticket** (append only, never overwrite).

### Step 4: Advance Linear Status to "Ready for Research"

**Skip this step entirely for GitHub issues.**

For Linear tickets only:

1. Determine the workspace from the ticket prefix (e.g. `ENG-` → Stellar). If ambiguous, get workspace using AskUserQuestion:
   - **Workspace**: Which Linear workspace is this ticket in?
   - Options: Stellar, Kickplan, Meerkat

2. Load the workspace MCP tools with ToolSearch if they aren't already loaded: `select:mcp__mise-tools__linear_{workspace}_get_issue,mcp__mise-tools__linear_{workspace}_save_issue,mcp__mise-tools__linear_{workspace}_list_issue_statuses`.

3. Fetch the ticket's current status via `get_issue` (you may already have this from Step 2). Determine the status progression position:

   ```
   Backlog -> Todo -> Ready for Research -> In Research -> Ready for Plan -> In Plan -> In Progress -> In Review -> Done
   ```

   - If the ticket is **before** "Ready for Research" (e.g. Backlog, Todo): advance it.
   - If the ticket is **at or past** "Ready for Research": leave it alone and note this in the summary. **Forward-only — never move backward.**

4. To advance, look up the "Ready for Research" state ID for the ticket's team using `list_issue_statuses`, then call `save_issue` with that `stateId`.

5. See [../linear-ticket-status-sync/SKILL.md](../linear-ticket-status-sync/SKILL.md) Step 5 for the same pattern — follow its forward-only rule.

### Step 5: Summary

```
Ticket [ID] is ready to work on:
- Enriched with: [List of sections added]
- Clarifications resolved: [Number]
- Artifacts referenced: [Number]
- Status: [previous] -> Ready for Research (or "unchanged — already at [status]")

Next: run `/research-codebase` or `/create-plan`.
```

## Guidelines

1. **Don't rewrite**: Append sections, never replace the original description
2. **Don't deep-dive into code**: Only check existing documentation artifacts
3. **Be concise**: Added sections should be scannable, not walls of text
4. **Suggest, don't assume**: Use AskUserQuestion to validate interpretations rather than guessing
5. **Link sources**: When referencing artifacts, include links to the source documents
6. **Know when to stop**: If the ticket is already well-specified, say so and don't add noise. Skip contextual DoR items that don't apply to the triaged ticket type — padding with N/A sections is a smell.
7. **Technical focus**: The clarifications you add are typically technical — constraints, edge cases, integration points — not business strategy
8. **No meta-questions**: Never ask "should I ask questions?" — just ask the actual clarifying questions directly using AskUserQuestion. Never print questions as plain text.
9. **Forward-only status**: Only advance Linear status forward. Never move a ticket backward from a later state to "Ready for Research".
10. **GitHub skips status advance**: The status workflow lives in Linear. For GitHub issues, perform enrichment only.
11. **Brief-then-Ask for every question**: Every `AskUserQuestion` is preceded by a short prose brief naming the options with substance. Option descriptions carry the choice, not just a label.
12. **Splitting beats enriching oversized tickets**: If Step 3's size check flags the ticket as > 1 sprint, get the split done before enriching — don't polish a ticket that's about to be carved up.
