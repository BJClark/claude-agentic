---
description: "DDD Step 1: Align & understand the business domain from a PRD or description"
model: opus
---

# DDD Step 1: Align & Understand

Ultrathink about the business domain before starting. Consider the core business entities, domain boundaries, ubiquitous language, and business invariants.

Establish shared understanding of the business domain before any technical discovery. Extract business context, actors, value propositions, and constraints from a PRD or conversational description.

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
   - **Actors/Roles**: Who interacts with the system? (users, admins, external systems)
   - **Value propositions**: What makes this valuable? What's the competitive advantage?
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
1. [Workflow 1 — e.g., "Customer discovers and purchases products"]
2. [Workflow 2 — e.g., "Seller lists and manages inventory"]
3. [Workflow 3]

**Constraints & Rules**:
- [Business constraint]
- [Regulatory requirement]
- [Technical constraint]

**Revenue Model**: [How this makes/saves money]

---

Does this accurately capture the business domain?
- Are any actors missing?
- Are the value propositions prioritized correctly?
- Are there constraints I haven't captured?
- Are there workflows I've missed?
```

### Step 3: Iterate Based on Feedback

- If the user corrects or adds information, update the summary
- Ask targeted follow-up questions for gaps:
  - "Who are the secondary users of this system?"
  - "What happens when [workflow] fails?"
  - "Are there regulatory requirements I should know about?"
  - "What are the non-negotiable business rules?"
- Continue until the user confirms the summary is accurate

### Step 4: Write Alignment Artifact

Create `research/ddd/01-alignment.md`:

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

### Purpose
[What this system does and why it matters]

### Target Users & Actors
| Actor | Role | Primary Need |
|-------|------|-------------|
| [Actor] | [Role description] | [What they need] |

### Value Propositions
1. **[Primary]**: [Description — this is the competitive advantage]
2. **[Secondary]**: [Description]
3. **[Tertiary]**: [Description]

## Core Workflows
1. **[Workflow Name]**: [Description of the end-to-end flow]
2. **[Workflow Name]**: [Description]

## Constraints & Business Rules
- [Constraint with rationale]
- [Business rule]
- [Regulatory requirement]

## Revenue Model
[How this generates or saves money]

## Assumptions
- [Assumption made during alignment]

## Open Questions
- [Questions that couldn't be answered from the PRD alone]
```

### Step 5: Prompt Next Step

```
Alignment artifact written to `research/ddd/01-alignment.md`.

Next step: Run `/ddd_discover` to perform EventStorming — extracting domain events, commands, actors, and policies from your requirements.

Or run `/ddd_full` for the complete end-to-end DDD workflow.
```

## Important Guidelines

1. **Business language only**: No technical terms, no architecture decisions. This is about understanding the domain
2. **Be skeptical**: Question vague requirements. "The system should be fast" is not a constraint — ask for specifics
3. **Prioritize value props**: The ordering matters for later strategic classification
4. **Capture what's NOT in scope**: Explicit exclusions prevent scope creep in later steps
5. **Create research/ddd/ directory**: If it doesn't exist, create it before writing the artifact
