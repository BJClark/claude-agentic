# Issue Enrichment Checklist

A Definition-of-Ready checklist split in two tiers: **Core** items are always considered; **Contextual** items fire only when the ticket's type/signals call for them (see Ticket-Type Triage below).

## Ticket-Type Triage (run first)

Before asking any clarification questions, classify the ticket from its title, body, labels, and any linked work. Pick the closest type — this gates which contextual DoR items apply.

| Type | Signals | Contextual items that fire |
|---|---|---|
| **Feature (user-facing)** | New UI / screen / flow; persona in title; product labels | Design link, A11y + i18n, NFRs, Observability |
| **Feature (backend)** | New API / endpoint / worker; no UI | NFRs, Rollout/Flag, Observability, Data impact |
| **Bug** | Labels `bug` / `defect` / `regression`; mentions broken behavior | Reproduction steps, Observability (was there a missed alert?), Rollout |
| **Chore / refactor** | Labels `chore` / `refactor` / `tech-debt`; no visible user impact | Rollout/Flag only if risky |
| **Migration / data** | Touches schema, backfill, import/export, PII | Data impact, PII/Compliance, Rollout, Observability |
| **Spike / research** | Labels `spike` / `research`; time-boxed investigation | Deliverable shape (report? prototype? decision?), Time-box |

If the type is ambiguous, ask the user directly via `AskUserQuestion` with these options. Record the chosen type — later clarification passes reference it.

## Quality Assessment Criteria — Core (always check)

| Criterion | What to look for |
|-----------|-----------------|
| **Problem to solve** | Clear description of what problem this addresses and why it matters |
| **Actors / users** | Who is affected? Who will use this? |
| **Acceptance criteria** | How do we know when this is done? What does success look like? (Testable, not vague.) |
| **Out of scope** | What is explicitly NOT in this ticket? Prevents mid-sprint scope creep. |
| **Dependencies / blockers** | Upstream tickets, other teams, external systems that must land first. |
| **Size (INVEST "Small")** | Does this fit a single sprint? If "L/XL" or > ~5 points, suggest splitting before planning. |
| **Edge cases / error paths** | Enumerated, not solved. What happens on failure, empty state, bad input, partial write, timeout? |
| **Observability / success metric** | How will we know in production that it actually worked? Metric, log, event, dashboard. |
| **Context & references** | Links to relevant docs, designs, or prior discussions |
| **No ambiguities** | No open questions that would block an engineer from planning |

## Quality Assessment Criteria — Contextual (fire per ticket type)

Only ask when the triage table says they apply. Skipping them when they don't apply keeps the skill lean.

| Criterion | Applies when | What to look for |
|---|---|---|
| **Design / mockup link** | User-facing feature | Figma link, screenshots, or flow diagram attached |
| **Accessibility + i18n** | UI work | Keyboard nav, screen-reader labels, translation keys; WCAG target level if relevant |
| **NFRs** | New endpoint / backend feature | Latency target (p50 / p99), auth requirement, rate-limit policy, throughput expectation |
| **Rollout / feature flag** | Production-impacting (backend, data, risky bug fix) | Flag name, cohort, dark-launch vs phased, rollback plan |
| **Data impact** | Migration, schema change, new table, backfill | Row counts, migration shape, backwards compat, backfill strategy |
| **PII / compliance** | Data handling, user data, logs with user info | PII fields enumerated, retention, GDPR/SOC2/HIPAA flags |
| **Reproduction steps** | Bug | Exact steps, expected vs actual, environment, version, user id / record id |
| **Deliverable shape** | Spike / research | Is the output a report, a prototype, a decision, a recommendation? What's the time-box? |

## Interactive Clarification Patterns

### If problem statement is missing or vague
Get clarification using AskUserQuestion:
- **Problem**: What problem does this solve from a user perspective?
- Offer inferred interpretations based on what you found, plus a "neither" option

### If acceptance criteria are missing
Get them using AskUserQuestion with multiSelect:
- **Done criteria**: What does "done" look like for this ticket?
- Suggest criteria based on what was learned from the ticket and artifacts

### For each ambiguity
Get clarification using AskUserQuestion:
- **Clarification**: [The specific clarifying question about this ambiguity]
- Offer options that reflect the realistic choices, with implementation implications

### If out-of-scope is missing
Get exclusions using AskUserQuestion (multiSelect):
- **Out of scope**: What is explicitly NOT part of this ticket?
- Suggest exclusions based on adjacent concerns the ticket could reasonably grow into — offer 3–5 candidate exclusions plus a "none of these" option.

### If dependencies aren't called out
Get dependencies using AskUserQuestion:
- **Dependencies**: Does this depend on other work landing first?
- Options: *none I know of*, *depends on a specific ticket* (user names it), *depends on another team* (user names who), *depends on external system* (user names it).

### If the ticket looks too large (Size / INVEST-Small)
If the body describes multiple user flows, multiple systems, or ambiguous scope that could easily become > 5 points, flag it via AskUserQuestion:
- **Size**: This ticket looks like it might be larger than one sprint. How to proceed?
- Options: *split it* (propose 2–3 splits based on the ticket), *keep whole and mark as epic*, *it's actually smaller than it reads — proceed*.

### If edge cases aren't enumerated
Get edge cases using AskUserQuestion (multiSelect):
- **Edge cases**: Which failure modes should be handled?
- Suggest cases based on ticket type (empty state, bad input, timeout, partial write, duplicate submit, concurrent edit, permission denied, rate-limit hit). User can multi-select the ones that apply.

### If observability / success metric isn't specified
Get the metric using AskUserQuestion:
- **Success metric**: How will we know in production this actually worked?
- Options: propose 2–3 concrete metrics from the ticket context (e.g. *"conversion on checkout page > X%"*, *"API p99 < 200ms"*, *"zero `AuthFailed` errors in the target cohort for 24h"*), plus *"I'll write the metric myself"*.

### Contextual clarifications (only if the triage type calls for them)

Use the contextual criteria table above to pick which of these to ask. Do NOT ask them when the ticket type doesn't call for them.

- **Design link** (user-facing features only) — "Paste the Figma / mockup link" (short prompt, not multi-option).
- **A11y + i18n** (UI work) — AskUserQuestion: keyboard-nav required, screen-reader labels, WCAG-AA, translation keys, none-of-these.
- **NFRs** (new endpoint / backend) — AskUserQuestion for latency target (p99 < 100ms / 500ms / 1s / no target), auth (public / authed / admin-only), rate-limit needed Y/N.
- **Rollout / flag** (production-impacting) — AskUserQuestion: flag-gated / dark-launched / phased-cohort / big-bang + "what's the rollback plan".
- **Data impact** (migration / schema) — AskUserQuestion: row count (< 10k / 10k–1M / > 1M), backwards-compat required Y/N, backfill strategy.
- **PII / compliance** (data handling) — AskUserQuestion: fields handled (email / name / payment / health / none), retention, compliance regime (GDPR / HIPAA / SOC2 / none).
- **Reproduction steps** (bug) — plain prompt: "Paste exact repro — steps, expected, actual, environment, affected user/record id."
- **Deliverable shape** (spike) — AskUserQuestion: report / prototype / decision-doc / recommendation; plus a time-box (1d / 3d / 1wk).

### When all gaps are addressed
Check using AskUserQuestion:
- **Anything else?**: Are there any other details an engineer would need to start planning?
- Options should cover: no looks complete, yes I want to add more context

If the user selects "Other" for any question, they'll provide free-text input — incorporate their response into the enrichment.

## Artifact Search

Spawn an `artifacts-locator` agent to find relevant prior artifacts across `research/`, `plans/`, and `.jeff/`:
```
Find artifacts related to: [ticket topic, keywords from title and description]
```

If relevant documents are found, spawn an `artifacts-analyzer` agent to extract insights:
```
Extract insights relevant to [ticket topic] from these documents: [list of found docs]
Focus on: decisions made, constraints identified, technical context, and anything that answers the gaps identified in the quality assessment.
```

## Preview & Confirm Template

Present the proposed additions as a preview — show exactly what will be appended:

```
## Proposed Additions to Ticket

The following sections will be **appended** to the existing description:

---

## Clarifications

[Content from user Q&A — answers to ambiguities, refined problem statement, etc.]

## Context from Artifacts

[Relevant findings from thoughts/docs, with links to source documents]

## Acceptance Criteria

[Clear, testable criteria — only if this section was missing]

## Out of Scope

[Explicit exclusions — what this ticket is NOT doing]

## Dependencies

[Upstream tickets / teams / systems that must land first]

## Edge Cases

[Enumerated failure modes and non-happy paths — what must be handled, not how]

## Success Metric

[How we'll know in production it actually worked — metric, log, event, dashboard]

## Non-Functional Requirements

[Latency, auth, rate limits, accessibility, i18n — only items that were answered]

## Rollout Plan

[Flag strategy, dark-launch vs phased, rollback plan — only if production-impacting]

## Data & Compliance

[Row counts, backwards compat, PII fields, compliance regime — only if data-touching]

---
```

**Only include sections that have content.** Omit any section where the criterion was N/A or already well-specified in the original ticket. The template above is a menu, not a mandatory list. A small bug fix might only get `Clarifications` + `Reproduction` + `Acceptance Criteria`; a data migration gets the full set.

## Update Procedures

**For Linear:**
1. Fetch the current description using `mcp__linear__get_issue`
2. Append the new sections to the existing description
3. Update using `mcp__linear__update_issue` with the combined description
4. Add a brief comment: "Enriched ticket description with clarifications and context from existing artifacts."
5. If any artifacts were referenced, add them as links using the `links` parameter

**For GitHub:**
1. Get current body: `gh issue view <number> --json body --jq .body`
2. Append the new sections to the existing body
3. Update: `gh issue edit <number> --body "<combined body>"`
4. Add a comment: `gh issue comment <number> --body "Enriched ticket description with clarifications and context from existing artifacts."`

**Important**: Never overwrite the original description. Always append.
