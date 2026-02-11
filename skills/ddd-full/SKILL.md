---
name: ddd-full
description: "Complete DDD discovery-to-implementation workflow — all 7 steps with confirmation gates"
model: opus
context: fork
allowed-tools: Read, Grep, Glob, Write, Edit, AskUserQuestion, Task, Skill
argument-hint: [prd-file-path]
hooks:
  TaskCompleted:
    - hooks:
        - type: command
          command: "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/verify-artifact-exists.sh"
          timeout: 10
          statusMessage: "Verifying DDD artifact..."
---

# DDD Full Workflow

Ultrathink about the end-to-end domain discovery process. Consider how each step builds on the previous, where the most important decisions will be made, and how to maintain coherence across the entire artifact chain.

Run the complete Domain-Driven Design discovery-to-implementation workflow.

**Input**: $ARGUMENTS

## Current Context

- **Branch**: !`git branch --show-current`
- **Last Commit**: !`git log -1 --oneline`

## Artifact Chain

```
PRD / conversation
  -> research/ddd/01-alignment.md      (Step 1: Align)
    -> research/ddd/02-event-catalog.md (Step 2: Discover)
      -> research/ddd/03-sub-domains.md (Step 3: Decompose)
        -> research/ddd/04-strategy.md  (Step 4: Strategize)
          -> research/ddd/05-context-map.md (Step 5: Connect)
            -> research/ddd/06-canvases.md  (Step 7: Define)
              -> plans/YYYY-MM-DD-ddd-*.md  (Step 8: Plan)
```

## Workflow

### Step 1: Align & Understand
1. Call `/ddd_align` with any provided parameters
2. After artifact is written, confirm with user:
```
Step 1 complete: Alignment artifact written to research/ddd/01-alignment.md
Ready to proceed to Step 2 (EventStorming Discovery)?
```
Wait for confirmation.

### Step 2: Discover (EventStorming)
1. Call `/ddd_discover`
2. Confirm: "Step 2 complete. Ready for Step 3 (Decompose)?"

### Step 3: Decompose
1. Call `/ddd_decompose`
2. Confirm: "Step 3 complete. Ready for Step 4 (Strategize)?"

### Step 4: Strategize
1. Call `/ddd_strategize`
2. Confirm: "Step 4 complete. Ready for Step 5 (Context Mapping)?"

### Step 5: Connect
1. Call `/ddd_connect`
2. Confirm: "Step 5 complete. Ready for Step 6 (Define Canvases)?"

### Step 6: Define
1. Call `/ddd_define`
2. Confirm: "Step 6 complete. Ready for Step 7 (Generate Plans)?"

### Step 7: Plan
1. Call `/ddd_plan`
2. Present final summary.

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

### Next Steps:
Start implementation with:
`/implement_plan plans/YYYY-MM-DD-ddd-[first-context].md`
```

## Agent Team Mode (Experimental)

For large PRDs, agent teams can parallelize the early exploration phases. Ask the user before spawning:

Get team mode preference using AskUserQuestion:
- **Team mode**: Should we use agent teams for parallel exploration?
- Options should include: Agent Team with note about ~3x speed for large PRDs (Recommended), Single Session with note about simpler/lower cost

Tailor the recommendation based on the PRD complexity.

**If team mode selected**, create a team with this structure:

```
Lead: DDD Coordinator (you)
├─ Teammate 1: Event Discovery — runs /ddd_align then /ddd_discover
├─ Teammate 2: Domain Decomposition — runs /ddd_decompose then /ddd_strategize
└─ Teammate 3: Context Mapping — runs /ddd_connect then /ddd_define
```

**Coordination rules:**
- Teammate 1 starts immediately with the PRD
- Teammate 2 waits for Teammate 1's alignment artifact (01-alignment.md) before starting decomposition
- Teammate 3 waits for Teammate 2's sub-domains artifact (03-sub-domains.md) before starting context mapping
- Use task dependencies to enforce this ordering
- After all teammates finish, the lead runs Step 7 (/ddd_plan) to synthesize

**Task setup:**
1. Create tasks for each teammate with appropriate blockedBy dependencies
2. Spawn 3 teammates, each assigned their DDD steps
3. Give each teammate the PRD path and the artifact chain they produce
4. Monitor progress and synthesize findings when all complete

**After team completes**, proceed to Step 7 (Plan) yourself and present the final summary.

Requires: `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` in settings or environment.

## Guidelines

1. **Confirmation gates are mandatory**: Always pause between steps (single mode) or between team phases (team mode)
2. **Each step is interactive**: Individual commands handle their own interactivity
3. **Artifacts chain forward**: Each step reads the previous output
4. **User can stop at any step**: Note where they are for resumption
5. **Individual commands can be re-run**: Re-run just that command if revision needed
6. **Team mode is optional**: Only use when explicitly enabled and user agrees
