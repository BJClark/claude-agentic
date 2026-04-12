# Issue Enrichment Checklist

## Quality Assessment Criteria

| Criterion | What to look for |
|-----------|-----------------|
| **Problem to solve** | Clear description of what problem this addresses and why it matters |
| **Actors/users** | Who is affected? Who will use this? |
| **Acceptance criteria** | How do we know when this is done? What does success look like? |
| **Context & references** | Links to relevant docs, designs, or prior discussions |
| **No ambiguities** | No open questions that would block an engineer from planning |

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

### When all gaps are addressed
Check using AskUserQuestion:
- **Anything else?**: Are there any other details an engineer would need to start planning?
- Options should cover: no looks complete, yes I want to add more context

If the user selects "Other" for any question, they'll provide free-text input — incorporate their response into the enrichment.

## Artifact Search

Spawn a `thoughts-locator` agent to find relevant documents in the thoughts/ directory:
```
Search thoughts/ for documents related to: [ticket topic, keywords from title and description]
```

If relevant documents are found, spawn a `thoughts-analyzer` agent to extract insights:
```
Extract insights relevant to [ticket topic] from these documents: [list of found docs]
Focus on: decisions made, constraints identified, technical context, and anything that answers the gaps identified in the quality assessment.
```

Also check for any `docs/` directory content related to the ticket topic using Grep.

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

---
```

Only include sections that have content. If artifacts found nothing useful, omit "Context from Artifacts". If acceptance criteria already existed, omit that section.

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
