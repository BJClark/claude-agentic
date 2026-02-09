---
name: improve-issue
description: "Enrich a ticket with clarifications and context so an engineer can start planning"
model: opus
context: fork
allowed-tools: Read, Grep, Glob, Task, AskUserQuestion, Bash
argument-hint: [ENG-1234 or #123 or github-url]
---

# Improve Issue

Ultrathink about what an engineer would need to know to create an implementation plan for this ticket. Consider the problem statement, actors, acceptance criteria, technical context, and any ambiguities.

Enrich a Linear or GitHub issue so it's ready for an engineer to start planning. Read the ticket, check existing project artifacts for relevant context, ask the user clarifying questions, and append enriched content back into the ticket description.

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
- **Ambiguous**: If auto-detection fails:

<invoke name="AskUserQuestion">
  questions: [{
    "question": "Is this a Linear or GitHub issue?",
    "header": "Platform",
    "multiSelect": false,
    "options": [
      {
        "label": "Linear",
        "description": "e.g., ENG-1234"
      },
      {
        "label": "GitHub",
        "description": "e.g., #123 or github.com URL"
      }
    ]
  }]
</invoke>

### Step 2: Fetch Ticket Content

**For Linear:**
1. Use `linear` CLI to fetch the ticket into `thoughts/shared/tickets/ENG-xxxx.md`
2. Read the ticket file and all comments
3. Note any existing links or referenced documents

**For GitHub:**
1. Run: `gh issue view <number> --json title,body,comments,labels,assignees`
2. Parse the JSON response
3. Note any existing links or referenced documents

### Step 3: Assess Current Ticket Quality

Evaluate the ticket against this completeness checklist:

| Criterion | What to look for |
|-----------|-----------------|
| **Problem to solve** | Clear description of what problem this addresses and why it matters |
| **Actors/users** | Who is affected? Who will use this? |
| **Acceptance criteria** | How do we know when this is done? What does success look like? |
| **Context & references** | Links to relevant docs, designs, or prior discussions |
| **No ambiguities** | No open questions that would block an engineer from planning |

Present the assessment to the user:

```
## Ticket Quality Assessment

**Ticket**: [ID] — [Title]

**Current state**:
- Problem to solve: [present/missing/vague]
- Actors/users: [present/missing/vague]
- Acceptance criteria: [present/missing/vague]
- Context & references: [present/missing/vague]
- Ambiguities: [list any open questions]

**Gaps to fill**: [summary of what's missing]
```

If the ticket meets all criteria, present your assessment and then ask:

<invoke name="AskUserQuestion">
  questions: [{
    "question": "This ticket looks well-specified. Should I look for implementation-specific details that could still help an engineer plan?",
    "header": "Continue?",
    "multiSelect": false,
    "options": [
      {
        "label": "Yes, keep going",
        "description": "Most tickets benefit from implementation specifics (API contracts, error handling, edge cases, dependencies)"
      },
      {
        "label": "No, it's ready",
        "description": "Stop here — the ticket has enough detail"
      }
    ]
  }]
</invoke>

If the user says to keep going, proceed to Step 4. If they say it's ready, stop.

### Step 4: Search Existing Artifacts

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

Present findings:
```
## Artifacts Found

[List of relevant documents with key insights extracted]

**Gaps still remaining**: [what couldn't be answered from existing artifacts]
```

If no artifacts are found, note that and move to clarification.

### Step 5: Interactive Clarification

Work through gaps one at a time. For each gap, use the invoke patterns below — fill in the bracket placeholders dynamically based on what you learned from the ticket and artifacts.

**5a. If problem statement is missing or vague:**

<invoke name="AskUserQuestion">
  questions: [{
    "question": "What problem does this solve from a user perspective?",
    "header": "Problem",
    "multiSelect": false,
    "options": [
      {
        "label": "[Inferred problem 1]",
        "description": "[Why this interpretation makes sense]"
      },
      {
        "label": "[Inferred problem 2]",
        "description": "[Why this interpretation makes sense]"
      },
      {
        "label": "Neither — I'll describe it",
        "description": "These interpretations are wrong, let me explain"
      }
    ]
  }]
</invoke>

**5b. If acceptance criteria are missing:**

<invoke name="AskUserQuestion">
  questions: [{
    "question": "What does 'done' look like for this ticket?",
    "header": "Done criteria",
    "multiSelect": true,
    "options": [
      {
        "label": "[Suggested criterion 1]",
        "description": "[What this criterion validates]"
      },
      {
        "label": "[Suggested criterion 2]",
        "description": "[What this criterion validates]"
      },
      {
        "label": "[Suggested criterion 3]",
        "description": "[What this criterion validates]"
      }
    ]
  }]
</invoke>

**5c. For each ambiguity:**

<invoke name="AskUserQuestion">
  questions: [{
    "question": "[The specific clarifying question about this ambiguity]",
    "header": "Clarification",
    "multiSelect": false,
    "options": [
      {
        "label": "[Option 1]",
        "description": "[What this means for implementation]"
      },
      {
        "label": "[Option 2]",
        "description": "[What this means for implementation]"
      },
      {
        "label": "[Option 3]",
        "description": "[What this means for implementation]"
      }
    ]
  }]
</invoke>

**5d. When all gaps are addressed:**

<invoke name="AskUserQuestion">
  questions: [{
    "question": "Are there any other details an engineer would need to start planning?",
    "header": "Anything else?",
    "multiSelect": false,
    "options": [
      {
        "label": "No, looks complete",
        "description": "All gaps have been addressed"
      },
      {
        "label": "Yes, I want to add more context",
        "description": "I have additional details to share"
      }
    ]
  }]
</invoke>

If the user selects "Other" for any question, they'll provide free-text input — incorporate their response into the enrichment.

### Step 6: Preview & Confirm

Present the proposed additions as a preview — show exactly what will be appended to the ticket:

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

<invoke name="AskUserQuestion">
  questions: [{
    "question": "Ready to update the ticket with these additions?",
    "header": "Confirm",
    "multiSelect": false,
    "options": [
      {
        "label": "Update ticket",
        "description": "Append these sections to the ticket description"
      },
      {
        "label": "Needs changes",
        "description": "I want to adjust the proposed additions first"
      },
      {
        "label": "Cancel",
        "description": "Don't update the ticket"
      }
    ]
  }]
</invoke>

- If "Needs changes": ask what to change, update the preview, and re-confirm
- If "Cancel": stop without modifying the ticket
- If "Update ticket": proceed to Step 7

### Step 7: Update Ticket

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

### Step 8: Summary

```
Ticket [ID] has been enriched with:
- [List of sections added]
- [Number of clarifications resolved]
- [Number of artifacts referenced]

The ticket should now have enough detail for an engineer to start creating an implementation plan.
```

## Guidelines

1. **Don't rewrite**: Append sections, never replace the original description
2. **Don't deep-dive into code**: Only check existing documentation artifacts — codebase research is what `/ralph_research` does
3. **Don't advance workflow state**: This skill only enriches content
4. **Be concise**: Added sections should be scannable, not walls of text
5. **Suggest, don't assume**: Use AskUserQuestion to validate interpretations rather than guessing
6. **Link sources**: When referencing artifacts, include links to the source documents
7. **Know when to stop**: If the ticket is already well-specified, say so and don't add noise
8. **Technical focus**: The clarifications you add are typically technical — constraints, edge cases, integration points — not business strategy
9. **No meta-questions**: Never ask "should I ask questions?" or "do you want me to clarify X?" — just ask the actual clarifying questions directly using AskUserQuestion. Never print questions as plain text.
