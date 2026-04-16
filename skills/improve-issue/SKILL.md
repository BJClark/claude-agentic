---
name: improve-issue
description: "Enrich a Linear or GitHub ticket with acceptance criteria and technical context so an engineer can start planning. Use when a ticket is vague or missing context. Triggers on 'improve this ticket', 'clarify ENG-1234', 'add acceptance criteria to #123'."
model: sonnet
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

See [references/enrichment-checklist.md](references/enrichment-checklist.md) for the detailed quality assessment criteria, clarification patterns, preview template, and update procedures.

Follow the checklist to:
1. Assess current ticket quality against the criteria table
2. Search existing artifacts for relevant context
3. Work through gaps interactively using AskUserQuestion
4. Preview proposed additions and get confirmation
5. Update the ticket (append only, never overwrite)

### Step 4: Summary

```
Ticket [ID] has been enriched with:
- [List of sections added]
- [Number of clarifications resolved]
- [Number of artifacts referenced]

The ticket should now have enough detail for an engineer to start creating an implementation plan.
```

## Guidelines

1. **Don't rewrite**: Append sections, never replace the original description
2. **Don't deep-dive into code**: Only check existing documentation artifacts
3. **Don't advance workflow state**: This skill only enriches content
4. **Be concise**: Added sections should be scannable, not walls of text
5. **Suggest, don't assume**: Use AskUserQuestion to validate interpretations rather than guessing
6. **Link sources**: When referencing artifacts, include links to the source documents
7. **Know when to stop**: If the ticket is already well-specified, say so and don't add noise
8. **Technical focus**: The clarifications you add are typically technical — constraints, edge cases, integration points — not business strategy
9. **No meta-questions**: Never ask "should I ask questions?" — just ask the actual clarifying questions directly using AskUserQuestion. Never print questions as plain text.
