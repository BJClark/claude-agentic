# DDD Skills AskUserQuestion Improvements

## Overview
Add explicit `AskUserQuestion` XML invocation examples to all 7 individual DDD skills so the LLM actually pauses for user input at interactive gate points, rather than relying on prose instructions that get skipped.

## Current State Analysis
All 7 DDD skills describe interactivity in prose ("ask the user", "wait for confirmation") but none include explicit `AskUserQuestion` XML examples. The comparison skills (`implement-plan`, `debug-issue`) that DO include XML examples successfully gate on user input. Research doc: `research/2026-02-07-ddd-plan-mode-interactivity.md`.

## What We're NOT Doing
- Modifying `ddd-full` (orchestrator) — its step gates stay as prose per user decision
- Changing `context: fork` to something else
- Adding plan mode support
- Restructuring the skills or changing their step flow
- Modifying the 3 DDD agents (read-only, no user interaction)

## Implementation Approach
For each skill, replace the prose-based "ask the user" instructions with explicit `AskUserQuestion` XML invocation examples at every natural interactive gate point. The XML examples should use context-specific options that reflect the actual decisions being made.

---

## Phase 1: ddd-align (2 gates)

### File: `skills/ddd-align/SKILL.md`

#### Gate 1: Business Domain Summary Validation (after Step 2, line ~85)
Replace the plain "Does this accurately capture the business domain?" with an AskUserQuestion invocation.

**After the summary template block (line 86), replace the existing Step 3 (lines 88-92) with:**

```markdown
### Step 3: Validate with User

<invoke name="AskUserQuestion">
  questions: [{
    "question": "Does this Business Domain Summary accurately capture your domain?",
    "header": "Alignment",
    "multiSelect": false,
    "options": [
      {
        "label": "Looks accurate",
        "description": "Summary captures the business domain correctly, proceed to write artifact"
      },
      {
        "label": "Needs corrections",
        "description": "Some details are wrong or missing — I'll provide corrections"
      },
      {
        "label": "Major gaps",
        "description": "Significant parts of the domain are missing or misunderstood"
      }
    ]
  }]
</invoke>

- If "Needs corrections" or "Major gaps": ask targeted follow-up questions, update summary, and re-validate
- Continue iterating until the user confirms accuracy
```

### Success Criteria:
- [x] `AskUserQuestion` XML present after Step 2 summary
- [x] Options reflect the actual decision (accurate / corrections / gaps)
- [x] Iteration loop preserved for corrections

---

## Phase 2: ddd-discover (3 gates)

### File: `skills/ddd-discover/SKILL.md`

#### Gate 1: Event Timeline Review (Step 3, line ~60)
Replace "Does this accurately represent how the process begins?" with:

```markdown
<invoke name="AskUserQuestion">
  questions: [{
    "question": "Does this event timeline accurately represent the domain process?",
    "header": "Timeline",
    "multiSelect": false,
    "options": [
      {
        "label": "Timeline is accurate",
        "description": "Events and their ordering look correct"
      },
      {
        "label": "Events missing",
        "description": "There are events or flows not captured here"
      },
      {
        "label": "Order is wrong",
        "description": "Some events are in the wrong sequence or have wrong triggers"
      },
      {
        "label": "Needs discussion",
        "description": "I want to walk through specific flows in more detail"
      }
    ]
  }]
</invoke>
```

#### Gate 2: Per-Flow Validation (Step 3, line ~63)
After presenting each flow, add:

```markdown
For each flow, present the trigger->command->event chain and ask:

<invoke name="AskUserQuestion">
  questions: [{
    "question": "For this flow, are the triggers, failure paths, and alternatives correct?",
    "header": "Flow Review",
    "multiSelect": false,
    "options": [
      {
        "label": "Flow is correct",
        "description": "Triggers, happy path, and failure paths are accurate"
      },
      {
        "label": "Missing failure paths",
        "description": "There are error scenarios not captured"
      },
      {
        "label": "Wrong triggers",
        "description": "The triggers or actors for this flow are incorrect"
      }
    ]
  }]
</invoke>
```

#### Gate 3: Gap Resolution (Step 4, line ~67)
Replace "present clearly, ask user to fill or confirm out of scope" with:

```markdown
For each gap found, present it clearly and ask:

<invoke name="AskUserQuestion">
  questions: [{
    "question": "[Gap description] — how should we handle this?",
    "header": "Gap",
    "multiSelect": false,
    "options": [
      {
        "label": "I'll fill this in",
        "description": "I have the domain knowledge to resolve this gap"
      },
      {
        "label": "Out of scope",
        "description": "This is outside the current domain boundary"
      },
      {
        "label": "Needs research",
        "description": "We need to investigate this further before deciding"
      }
    ]
  }]
</invoke>
```

### Success Criteria:
- [x] Timeline review gate with 4 options
- [x] Per-flow validation gate with 3 options
- [x] Per-gap resolution gate with 3 options

---

## Phase 3: ddd-decompose (3 gates)

### File: `skills/ddd-decompose/SKILL.md`

#### Gate 1: Per-Boundary Validation (Step 3, line ~53)
Replace "Does this grouping make sense?" with:

```markdown
After presenting each proposed boundary, ask:

<invoke name="AskUserQuestion">
  questions: [{
    "question": "Does the [Context Name] boundary grouping make sense?",
    "header": "Boundary",
    "multiSelect": false,
    "options": [
      {
        "label": "Grouping is correct",
        "description": "These building blocks belong together in this context"
      },
      {
        "label": "Blocks misplaced",
        "description": "Some building blocks should be in a different context"
      },
      {
        "label": "Should be split",
        "description": "This context is too large and should be divided"
      },
      {
        "label": "Should be merged",
        "description": "This context should be combined with another"
      }
    ]
  }]
</invoke>
```

#### Gate 2: Pivotal Event Validation (Step 4, line ~60)
Add after presenting pivotal events:

```markdown
After presenting pivotal events as boundary markers:

<invoke name="AskUserQuestion">
  questions: [{
    "question": "Do these pivotal events correctly mark the boundaries between contexts?",
    "header": "Pivotal Events",
    "multiSelect": false,
    "options": [
      {
        "label": "Events are correct",
        "description": "These events accurately mark phase transitions between contexts"
      },
      {
        "label": "Missing pivotal events",
        "description": "There are boundary-marking events not identified here"
      },
      {
        "label": "Wrong boundaries",
        "description": "Some of these events don't actually mark context transitions"
      }
    ]
  }]
</invoke>
```

#### Gate 3: Ambiguous Block Resolution (Step 5, line ~64)
Replace "present trade-offs, ask user to decide" with:

```markdown
For each ambiguous building block, present trade-offs and ask:

<invoke name="AskUserQuestion">
  questions: [{
    "question": "[Block ID] could belong to [Context A] or [Context B]. Where should it go?",
    "header": "Placement",
    "multiSelect": false,
    "options": [
      {
        "label": "[Context A]",
        "description": "[Rationale for placing in Context A]"
      },
      {
        "label": "[Context B]",
        "description": "[Rationale for placing in Context B]"
      },
      {
        "label": "Duplicate in both",
        "description": "This concept exists in both contexts with different meanings"
      }
    ]
  }]
</invoke>

Document the user's rationale for each decision.
```

### Success Criteria:
- [x] Per-boundary validation gate with 4 options
- [x] Pivotal event validation gate with 3 options
- [x] Ambiguous block resolution gate with context-specific options

---

## Phase 4: ddd-strategize (2 gates)

### File: `skills/ddd-strategize/SKILL.md`

#### Gate 1: Per-Context Classification (Step 3, line ~45)
Replace "ask user to rate differentiation and complexity" with:

```markdown
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
```

#### Gate 2: Strategy Summary Confirmation (Step 6, line ~62)
After presenting the classification table, add:

```markdown
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
```

### Success Criteria:
- [x] Multi-question AskUserQuestion for differentiation + complexity (2 questions in one invocation)
- [x] Strategy summary confirmation gate

---

## Phase 5: ddd-connect (2 gates)

### File: `skills/ddd-connect/SKILL.md`

#### Gate 1: Per-Pair Pattern Selection (Step 4, line ~46)
Replace "ask which pattern fits" with:

```markdown
For each context pair, present shared events and direction, then ask:

<invoke name="AskUserQuestion">
  questions: [{
    "question": "What integration pattern fits between [Context A] (upstream) and [Context B] (downstream)?",
    "header": "Pattern",
    "multiSelect": false,
    "options": [
      {
        "label": "Customer-Supplier",
        "description": "Upstream accommodates downstream needs, downstream has influence"
      },
      {
        "label": "Conformist",
        "description": "Downstream conforms to upstream model, no negotiation"
      },
      {
        "label": "ACL (Anti-Corruption Layer)",
        "description": "Downstream translates upstream model to protect its own domain"
      },
      {
        "label": "Partnership",
        "description": "Both contexts evolve together with mutual dependency"
      }
    ]
  }]
</invoke>

If the user selects "Other", present the remaining patterns: OHS, Published Language, Shared Kernel, Separate Ways.
```

#### Gate 2: Context Map Review (after Step 6, before Step 7)
Add after building the diagram:

```markdown
After presenting the complete context map diagram:

<invoke name="AskUserQuestion">
  questions: [{
    "question": "Does this context map accurately represent all relationships?",
    "header": "Map Review",
    "multiSelect": false,
    "options": [
      {
        "label": "Map is correct",
        "description": "All relationships and patterns are accurately captured"
      },
      {
        "label": "Missing relationships",
        "description": "There are context interactions not shown on the map"
      },
      {
        "label": "Wrong patterns",
        "description": "Some relationship patterns need to be changed"
      }
    ]
  }]
</invoke>
```

### Success Criteria:
- [x] Per-pair pattern selection with top 4 patterns as options
- [x] "Other" instruction for remaining patterns
- [x] Context map review gate

---

## Phase 6: ddd-define (3 gates)

### File: `skills/ddd-define/SKILL.md`

#### Gate 1: Canvas Scope Confirmation (Step 2, line ~45)
Replace "Present the plan and ask if ready to begin" with:

```markdown
Present the canvas scope plan, then:

<invoke name="AskUserQuestion">
  questions: [{
    "question": "Here's the canvas plan based on strategic classification. Ready to begin?",
    "header": "Scope",
    "multiSelect": false,
    "options": [
      {
        "label": "Ready to begin",
        "description": "Canvas scope looks right, start with core contexts"
      },
      {
        "label": "Adjust scope",
        "description": "I want to change which contexts get full vs abbreviated canvases"
      },
      {
        "label": "Focus on specific context",
        "description": "I only want canvases for specific contexts right now"
      }
    ]
  }]
</invoke>
```

#### Gate 2: BC Canvas Review (Step 3B, line ~53)
Replace "Ask for review" with:

```markdown
After presenting the Bounded Context Canvas:

<invoke name="AskUserQuestion">
  questions: [{
    "question": "Does this Bounded Context Canvas for [Context Name] look correct?",
    "header": "BC Canvas",
    "multiSelect": false,
    "options": [
      {
        "label": "Canvas is correct",
        "description": "All fields are accurate, proceed to Aggregate Canvas"
      },
      {
        "label": "Needs corrections",
        "description": "Some fields need updating — I'll specify which"
      },
      {
        "label": "Missing information",
        "description": "There are gaps marked [INSUFFICIENT DATA] I can fill"
      }
    ]
  }]
</invoke>
```

#### Gate 3: Aggregate Canvas Review (Step 3C, line ~55-57)
Replace "Ask for review. Wait for confirmation on each canvas before proceeding." with:

```markdown
After presenting the Aggregate Design Canvas:

<invoke name="AskUserQuestion">
  questions: [{
    "question": "Does this Aggregate Design Canvas for [Aggregate Name] look correct?",
    "header": "Aggregate",
    "multiSelect": false,
    "options": [
      {
        "label": "Canvas is correct",
        "description": "Invariants, commands, events, and state lifecycle are accurate"
      },
      {
        "label": "Wrong invariants",
        "description": "The enforced invariants need correction"
      },
      {
        "label": "State lifecycle issues",
        "description": "The state transitions don't match the real domain behavior"
      },
      {
        "label": "Missing information",
        "description": "There are gaps I can fill in"
      }
    ]
  }]
</invoke>

Wait for confirmation on each canvas before proceeding to the next context.
```

### Success Criteria:
- [x] Canvas scope confirmation gate
- [x] Per-BC canvas review gate
- [x] Per-aggregate canvas review gate with domain-specific options

---

## Phase 7: ddd-plan (3 gates)

### File: `skills/ddd-plan/SKILL.md`

#### Gate 1: Implementation Sequence Confirmation (Step 2, line ~46)
Replace "Present sequence table and confirm with user" with:

```markdown
Present the implementation sequence table, then:

<invoke name="AskUserQuestion">
  questions: [{
    "question": "Does this implementation sequence make sense?",
    "header": "Sequence",
    "multiSelect": false,
    "options": [
      {
        "label": "Sequence is correct",
        "description": "Core first, then supporting, then generic — order looks right"
      },
      {
        "label": "Reorder contexts",
        "description": "I want to change which contexts are implemented first"
      },
      {
        "label": "Skip some contexts",
        "description": "Not all contexts need implementation plans right now"
      }
    ]
  }]
</invoke>
```

#### Gate 2: Per-Context Phase Strategy (Step 4, line ~62)
Replace "propose phases...Wait for confirmation" with:

```markdown
For each context, present the proposed phases, then:

<invoke name="AskUserQuestion">
  questions: [{
    "question": "Does this phase strategy for [Context Name] look right?",
    "header": "Phases",
    "multiSelect": false,
    "options": [
      {
        "label": "Phases look good",
        "description": "Domain Model → Application → Infrastructure → Integration → Testing"
      },
      {
        "label": "Adjust phases",
        "description": "I want to reorder, combine, or split phases"
      },
      {
        "label": "Simplify",
        "description": "This context doesn't need all 5 phases"
      }
    ]
  }]
</invoke>
```

#### Gate 3: Final Plans Review (after Step 5, before Step 6)
Add before presenting the summary:

```markdown
After writing all plans, present them for final review:

<invoke name="AskUserQuestion">
  questions: [{
    "question": "I've written implementation plans for all contexts. Ready to finalize?",
    "header": "Final Review",
    "multiSelect": false,
    "options": [
      {
        "label": "Plans look good",
        "description": "Ready to see the summary and start implementing"
      },
      {
        "label": "Revise specific plan",
        "description": "I want to adjust a specific context's plan"
      },
      {
        "label": "Review all plans first",
        "description": "Let me read through each plan before finalizing"
      }
    ]
  }]
</invoke>
```

### Success Criteria:
- [x] Implementation sequence confirmation gate
- [x] Per-context phase strategy gate
- [x] Final plans review gate

---

## Testing Strategy

### Manual Testing:
1. Run each `/ddd_*` skill and verify AskUserQuestion actually fires at each gate point
2. Verify the structured options appear (not just plain text questions)
3. Verify the iteration loop works when user selects correction options
4. Verify "Other" free-text input is handled gracefully

## References
- Research: `research/2026-02-07-ddd-plan-mode-interactivity.md`
- Pattern to follow: `skills/implement-plan/SKILL.md:86-106` (AskUserQuestion XML example)
- DDD skills: `skills/ddd-*/SKILL.md`
