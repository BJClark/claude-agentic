---
description: "Complete DDD discovery-to-implementation workflow — all 7 steps with confirmation gates"
model: opus
---

# DDD Full Workflow

Ultrathink about the end-to-end domain discovery process. Consider how each step builds on the previous, where the most important decisions will be made, and how to maintain coherence across the entire artifact chain.

Run the complete Domain-Driven Design discovery-to-implementation workflow. Chains all 7 steps with confirmation gates between each, producing a full artifact chain from PRD to implementable plans.

## Artifact Chain

```
PRD / conversation
  → research/ddd/01-alignment.md      (Step 1: Align)
    → research/ddd/02-event-catalog.md (Step 2: Discover)
      → research/ddd/03-sub-domains.md (Step 3: Decompose)
        → research/ddd/04-strategy.md  (Step 4: Strategize)
          → research/ddd/05-context-map.md (Step 5: Connect)
            → research/ddd/06-canvases.md  (Step 7: Define)
              → plans/YYYY-MM-DD-ddd-*.md  (Step 8: Plan)
```

## Workflow

### Step 1: Align & Understand
1. Use SlashCommand() to call `/ddd_align` with any provided parameters
2. After artifact is written, confirm with user:
```
Step 1 complete: Alignment artifact written to research/ddd/01-alignment.md

Ready to proceed to Step 2 (EventStorming Discovery)?
```
Wait for confirmation before continuing.

### Step 2: Discover (EventStorming)
1. Use SlashCommand() to call `/ddd_discover`
2. After artifact is written, confirm:
```
Step 2 complete: Event catalog written to research/ddd/02-event-catalog.md

Ready to proceed to Step 3 (Decompose into Sub-domains)?
```

### Step 3: Decompose
1. Use SlashCommand() to call `/ddd_decompose`
2. After artifact is written, confirm:
```
Step 3 complete: Sub-domain map written to research/ddd/03-sub-domains.md

Ready to proceed to Step 4 (Strategic Classification)?
```

### Step 4: Strategize
1. Use SlashCommand() to call `/ddd_strategize`
2. After artifact is written, confirm:
```
Step 4 complete: Strategy artifact written to research/ddd/04-strategy.md

Ready to proceed to Step 5 (Context Mapping)?
```

### Step 5: Connect
1. Use SlashCommand() to call `/ddd_connect`
2. After artifact is written, confirm:
```
Step 5 complete: Context map written to research/ddd/05-context-map.md

Ready to proceed to Step 6 (Define Canvases)?
```

### Step 6: Define
1. Use SlashCommand() to call `/ddd_define`
2. After artifact is written, confirm:
```
Step 6 complete: Canvases written to research/ddd/06-canvases.md

Ready to proceed to Step 7 (Generate Implementation Plans)?
```

### Step 7: Plan
1. Use SlashCommand() to call `/ddd_plan`
2. After plans are written, present final summary.

### Final Summary

```
## DDD Discovery Complete

### Artifacts Created:
| Step | Artifact | Status |
|------|----------|--------|
| 1. Align | research/ddd/01-alignment.md | Complete |
| 2. Discover | research/ddd/02-event-catalog.md | Complete |
| 3. Decompose | research/ddd/03-sub-domains.md | Complete |
| 4. Strategize | research/ddd/04-strategy.md | Complete |
| 5. Connect | research/ddd/05-context-map.md | Complete |
| 6. Define | research/ddd/06-canvases.md | Complete |
| 7. Plan | plans/YYYY-MM-DD-ddd-*.md | Complete |

### Domain Summary:
- **Domain**: [name]
- **Bounded Contexts**: [N] ([N] core, [N] supporting, [N] generic)
- **Aggregates**: [N] total across all contexts
- **Implementation Plans**: [N] plans ready for /implement_plan

### Next Steps:
Start implementation with:
`/implement_plan plans/YYYY-MM-DD-ddd-[first-context].md`
```

## Important Guidelines

1. **Confirmation gates are mandatory**: Always pause between steps for user confirmation
2. **Each step is interactive**: The individual commands handle their own interactivity — don't skip it
3. **Artifacts chain forward**: Each step reads the previous step's output
4. **User can stop at any step**: If they want to pause, note where they are for resumption
5. **Individual commands can be re-run**: If a step needs revision, re-run just that command
