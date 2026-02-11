---
name: ddd-align
description: "DDD Step 1: Align & understand the business domain from a PRD or description"
model: opus
context: fork
allowed-tools: Read, Grep, Glob, Write, Edit, AskUserQuestion
argument-hint: [prd-file-path]
---

# DDD Step 1: Align & Understand

Ultrathink about the business domain before starting. Consider the core business entities, domain boundaries, ubiquitous language, and business invariants.

Establish shared understanding of the business domain before any technical discovery. Extract business context, actors, value propositions, and constraints from a PRD or conversational description.

**Input**: $ARGUMENTS

## Current Context

- **Branch**: !`git branch --show-current 2>/dev/null || echo "N/A"`
- **Last Commit**: !`git log -1 --oneline 2>/dev/null || echo "N/A"`

## Initial Response

When invoked:

1. **If a file path is provided**: Read the file completely, then begin analysis
2. **If no parameters**:
```
I'll help you start the DDD discovery process by aligning on the business domain.

Please provide:
1. A PRD file path (e.g., `/ddd_align path/to/prd.md`)
2. Or describe the system/product you want to model

I'll extract the business context, actors, value propositions, and constraints — then we'll validate together before moving to domain discovery.
```

Then wait for user input.

## Process Steps

### Step 1: Read and Analyze Source Material

1. **Read provided files completely** — no limit/offset
2. If the PRD references other documents, read those too
3. Extract:
   - **Business purpose**: What problem does this solve? For whom?
   - **Actors/Roles**: Who interacts with the system?
   - **Value propositions**: What makes this valuable?
   - **Core workflows**: What are the main things users do?
   - **Constraints**: Regulatory, technical, business rules, SLAs
   - **Revenue model**: How does this generate or save money?

### Step 2: Present Business Model Summary

Present findings in this format and ask for corrections:

```
## Business Domain Summary

**Purpose**: [One sentence describing what this system does and why]

**Target Users**:
- [Actor 1] — [what they need from the system]
- [Actor 2] — [what they need from the system]

**Value Propositions**:
1. [Primary value — the competitive advantage]
2. [Secondary value]
3. [Tertiary value]

**Core Workflows** (high level):
1. [Workflow 1]
2. [Workflow 2]

**Constraints & Rules**:
- [Business constraint]
- [Regulatory requirement]

**Revenue Model**: [How this makes/saves money]

---

Does this accurately capture the business domain?
```

### Step 3: Validate with User

Get user validation using AskUserQuestion:
- **Alignment check**: Does the Business Domain Summary accurately capture the domain?
- Options should include: looks accurate, needs corrections, has major gaps

Tailor options based on what you found. If corrections needed, ask targeted follow-up questions, update summary, and re-validate. Continue iterating until the user confirms accuracy.

### Step 4: Write Alignment Artifact

Create `research/ddd/01-alignment.md` with YAML frontmatter:

```markdown
---
ddd_step: 1
ddd_step_name: Align & Understand
domain: "[Domain Name]"
date: YYYY-MM-DD
status: complete
source: "[path to PRD or 'conversational']"
---

# DDD Alignment: [Domain Name]

## Business Context
[Purpose, Target Users, Value Propositions, Core Workflows, Constraints, Revenue Model]

## Assumptions
- [Assumptions made during alignment]

## Open Questions
- [Questions that couldn't be answered]
```

Create `research/ddd/` directory if it doesn't exist.

### Step 5: Prompt Next Step

```
Alignment artifact written to `research/ddd/01-alignment.md`.

Next step: Run `/ddd_discover` to perform EventStorming.
Or run `/ddd_full` for the complete end-to-end DDD workflow.
```

## Guidelines

1. **Business language only**: No technical terms, no architecture decisions
2. **Be skeptical**: Question vague requirements
3. **Prioritize value props**: Ordering matters for strategic classification
4. **Capture what's NOT in scope**: Prevent scope creep
