---
name: ddd-strategize
description: "DDD Step 4: Strategize — classify sub-domains and make investment decisions"
model: opus
context: fork
allowed-tools: Read, Grep, Glob, Write, Edit, AskUserQuestion
argument-hint: [domain-name]
---

# DDD Step 4: Strategize

Ultrathink about business differentiation and model complexity. Consider which contexts provide competitive advantage, which contain irreducible complexity, and where investment will generate the most value.

Classify each sub-domain on the Core Domain Chart and make strategic investment decisions.

**Input**: $ARGUMENTS

## Current Context

- **Branch**: !`git branch --show-current`
- **Last Commit**: !`git log -1 --oneline`

## Prerequisites

- `research/ddd/03-sub-domains.md` must exist (run `/ddd_decompose` first)
- `research/ddd/01-alignment.md` for business context

## Process Steps

### Step 1: Read Prerequisites

1. Read `research/ddd/03-sub-domains.md` completely
2. Read `research/ddd/01-alignment.md` for value propositions

### Step 2: Present Classification Framework

Explain the two axes (Business Differentiation x Model Complexity) and quadrants:
- **High diff + High complexity** -> Core Domain (invest heavily)
- **High diff + Low complexity** -> Core Domain, simpler
- **Low diff + High complexity** -> Supporting (consider buying)
- **Low diff + Low complexity** -> Generic (off the shelf)

### Step 3: Classify Each Sub-domain Interactively

For each context, present the context description and ask:

<invoke name="AskUserQuestion">
  questions: [
    {
      "question": "How would you rate [Context Name]'s business differentiation?",
      "header": "Differentiation",
      "multiSelect": false,
      "options": [
        {
          "label": "High",
          "description": "This is a competitive advantage — unique to our business"
        },
        {
          "label": "Medium",
          "description": "Somewhat differentiating but not a core advantage"
        },
        {
          "label": "Low",
          "description": "Commodity capability — most competitors have this"
        }
      ]
    },
    {
      "question": "How would you rate [Context Name]'s model complexity?",
      "header": "Complexity",
      "multiSelect": false,
      "options": [
        {
          "label": "High",
          "description": "Complex business rules, many invariants, rich state transitions"
        },
        {
          "label": "Medium",
          "description": "Moderate complexity, some business rules"
        },
        {
          "label": "Low",
          "description": "Simple CRUD-like operations, few business rules"
        }
      ]
    }
  ]
</invoke>

Wait for input on each context before proceeding to the next.

### Step 4: Determine Architecture Strategy

| Classification | Architecture |
|---------------|-------------|
| Core (high+high) | CQRS/ES with full DDD tactical patterns |
| Core (high+low) | Rich domain model, standard persistence |
| Supporting (low+high) | Consider buying/adapting |
| Generic (low+low) | CRUD or third-party |

### Step 5: Build Core Domain Chart

Create Mermaid quadrantChart showing all contexts plotted.

### Step 6: Present Strategy Summary

Show classification table with architecture, investment level, and implementation order.

After presenting the strategy summary table:

<invoke name="AskUserQuestion">
  questions: [{
    "question": "Does this strategic classification and architecture mapping look correct?",
    "header": "Strategy",
    "multiSelect": false,
    "options": [
      {
        "label": "Looks correct",
        "description": "Classifications and architecture choices are appropriate"
      },
      {
        "label": "Reclassify some",
        "description": "Some contexts need different differentiation or complexity ratings"
      },
      {
        "label": "Architecture concerns",
        "description": "I disagree with some architecture recommendations"
      }
    ]
  }]
</invoke>

### Step 7: Write Strategy Artifact

Create `research/ddd/04-strategy.md` with Core Domain Chart, classifications, architecture decisions, and implementation priority.

### Step 8: Prompt Next Step

```
Strategy artifact written to `research/ddd/04-strategy.md`.

Next step: Run `/ddd_connect` to map relationships between bounded contexts.
```

## Guidelines

1. **User decides classification**: Present framework, let user rate
2. **Core domains are rare**: Most systems have 1-2 core domains
3. **Architecture follows strategy**: CQRS/ES only where justified
4. **Don't over-invest in generic**: Use existing solutions
5. **Implementation order matters**: Core first, then supporting, then generic
6. **Preserve building block IDs**: Continue referencing E1, C1 from catalog
