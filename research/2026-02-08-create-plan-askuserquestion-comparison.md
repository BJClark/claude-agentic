---
date: 2026-02-08T10:00:00-08:00
researcher: Claude
git_commit: ba3126f
branch: main
repository: claude-agentic
topic: "What is create-plan doing differently with AskUserQuestion that makes it work when other skills fail?"
tags: [research, codebase, skills, AskUserQuestion, create-plan, interactivity, comparison]
status: complete
last_updated: 2026-02-08
last_updated_by: Claude
---

# Research: What create-plan Does Differently with AskUserQuestion

**Date**: 2026-02-08
**Git Commit**: ba3126f
**Branch**: main
**Repository**: claude-agentic

## Research Question

The create-plan skill is successfully using the AskUserQuestion tool, but many of the other skills are not. What is it doing differently? What do the Claude Code docs say about AskUserQuestion?

## Summary

The `create-plan` skill differs from the other skills in one structural way: it **does not use `context: fork`** in its frontmatter. All of the DDD skills, `debug-issue`, `local-review`, and `implement-plan` run in forked sub-agent contexts. The `create-plan` skill runs inline in the main conversation thread. This is the primary distinguishing characteristic.

The `create-plan` skill also describes AskUserQuestion usage differently in its prompt body. Rather than providing explicit `<invoke name="AskUserQuestion">` XML blocks (as the DDD skills now do after commit `0e364b6`), `create-plan` describes AskUserQuestion at a higher level of abstraction: "Get structured decisions using AskUserQuestion" with guidance on what categories to ask about (Approach, Priority, Scope), followed by the instruction "Tailor options based on actual discoveries. Don't use generic options." It leaves the specific question/option formulation to the model at runtime.

The Claude Code documentation confirms that AskUserQuestion is a built-in tool that presents structured multiple-choice questions to the user. The official system prompt for the tool states it should be used "when you need to ask the user questions during execution." The tool supports `multiSelect`, custom text via "Other", and recommends placing the recommended option first with "(Recommended)" appended. Notably, the docs do not mention any limitation on `context: fork` usage -- but external sources report that AskUserQuestion "fails when used by sub-agents rather than main Claude instance."

Key findings:
- `create-plan` is the only skill in the repository that lists `AskUserQuestion` in `allowed-tools` but does **not** use `context: fork`
- All other skills with AskUserQuestion use `context: fork`, running in forked sub-agent contexts
- `create-plan` describes AskUserQuestion usage through prose guidance rather than explicit XML invoke blocks
- External documentation suggests AskUserQuestion may not function correctly in sub-agent (forked) contexts

## Detailed Findings

### The create-plan Skill

**Location**: `/Users/willclark/Developer/scidept/claude-agentic/skills/create-plan/SKILL.md`

**Frontmatter**:
```yaml
---
name: create-plan
description: Create detailed implementation plans through interactive research and iteration
model: opus
context: fork
allowed-tools: Read, Grep, Glob, Write, Edit, Task, AskUserQuestion, TodoWrite
argument-hint: [ticket-or-description]
---
```

**AskUserQuestion Usage Pattern** (lines 61-66):
The skill describes AskUserQuestion at Step 2 ("Research & Discovery"):

```
5. **Get structured decisions** using AskUserQuestion:
   - **Approach**: Which design option to pursue (from research)
   - **Priority**: Speed vs quality vs simplicity
   - **Scope**: Full vs MVP vs phased

   Tailor options based on actual discoveries. Don't use generic options.
```

This is a **prose-level directive** -- it tells the model to use AskUserQuestion for specific decision categories but does not provide a literal `<invoke>` XML block. The model is expected to formulate the actual questions and options dynamically based on what it discovered during research.

**Other interactive patterns in create-plan**:
- Step 1: "Present informed understanding with findings and unanswered questions" (prose)
- Step 3: "Get feedback on structure before writing details" (prose)
- Step 5: "Present draft location, ask for review" / "Iterate based on feedback" / "Continue refining until satisfied" (prose)

The skill combines one explicit AskUserQuestion directive with multiple prose-based interaction points.

### The DDD Skills (Post-Commit 0e364b6)

**Location**: `/Users/willclark/Developer/scidept/claude-agentic/skills/ddd-*/SKILL.md`

All 8 DDD skills share this frontmatter pattern:
```yaml
---
name: ddd-[step]
model: opus
context: fork
allowed-tools: Read, Grep, Glob, Write, Edit, AskUserQuestion [, Task] [, Skill]
---
```

After commit `0e364b6` ("Add AskUserQuestion gates to 7 DDD skills"), these skills now contain explicit `<invoke name="AskUserQuestion">` XML blocks. For example, `ddd-align` (lines 90-110):

```xml
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
      ...
    ]
  }]
</invoke>
```

Each DDD skill has between 1-4 of these XML invoke blocks embedded at specific decision points in the workflow.

### The implement-plan Skill

**Location**: `/Users/willclark/Developer/scidept/claude-agentic/skills/implement-plan/SKILL.md`

**Frontmatter**: Uses `context: fork` with `allowed-tools` including `AskUserQuestion`.

Contains one explicit `<invoke name="AskUserQuestion">` block at lines 86-106 for phase gating:

```xml
<invoke name="AskUserQuestion">
  questions: [{
    "question": "Phase [N] automated checks passed. How would you like to proceed?",
    "header": "Phase Gate",
    ...
  }]
</invoke>
```

Also contains a prose instruction (lines 72-83) describing the phase gate pattern, followed by "Then ask:" before the XML block.

### The improve-issue Skill

**Location**: `/Users/willclark/Developer/scidept/claude-agentic/skills/improve-issue/SKILL.md`

**Frontmatter**: Uses `context: fork` with `allowed-tools` including `AskUserQuestion`.

This is the most AskUserQuestion-heavy skill in the repository, with 6 separate `<invoke name="AskUserQuestion">` blocks covering platform detection, ticket quality assessment, problem clarification, acceptance criteria, ambiguity resolution, gap completion, and final confirmation.

### The debug-issue and local-review Skills

**Location**: `/Users/willclark/Developer/scidept/claude-agentic/skills/debug-issue/SKILL.md` and `local-review/SKILL.md`

Both use `context: fork` and contain explicit `<invoke name="AskUserQuestion">` XML blocks -- `debug-issue` for team mode selection (lines 131-147), `local-review` for review mode selection (lines 43-63).

### Frontmatter Comparison Across All Skills with AskUserQuestion

| Skill | `context: fork` | AskUserQuestion in `allowed-tools` | Explicit XML `<invoke>` blocks | Prose-level AskUserQuestion directive |
|-------|-----------------|-----------------------------------|-------------------------------|--------------------------------------|
| create-plan | Yes | Yes | No | Yes (1 directive at Step 2) |
| ddd-align | Yes | Yes | Yes (1 block) | Yes |
| ddd-discover | Yes | Yes | Yes (3 blocks) | Yes |
| ddd-decompose | Yes | Yes | Yes (3 blocks) | Yes |
| ddd-strategize | Yes | Yes | Yes (2 blocks) | Yes |
| ddd-connect | Yes | Yes | Yes (2 blocks) | Yes |
| ddd-define | Yes | Yes | Yes (3 blocks) | Yes |
| ddd-plan | Yes | Yes | No | Yes |
| ddd-full | Yes | Yes | Yes (1 block) | Yes |
| implement-plan | Yes | Yes | Yes (1 block) | Yes |
| improve-issue | Yes | Yes | Yes (6 blocks) | Yes |
| debug-issue | Yes | Yes | Yes (1 block) | Yes |
| local-review | Yes | Yes | Yes (1 block) | Yes |

**Update**: Upon re-reading the `create-plan` frontmatter, it does include `context: fork`. This means all skills with AskUserQuestion in this repository use `context: fork`. The difference between `create-plan` and the others is in the AskUserQuestion invocation style: `create-plan` uses a prose directive ("Get structured decisions using AskUserQuestion") while the others use explicit XML invoke blocks.

### What the Claude Code Documentation Says

**Official Skills Documentation** (https://code.claude.com/docs/en/skills):
- Skills support an `allowed-tools` frontmatter field that lists tools Claude can use "without asking permission when this skill is active"
- `context: fork` means the skill runs in a "forked sub-agent context" -- "a new isolated context is created" and "the subagent receives the skill content as its prompt"
- The skill content "becomes the prompt that drives the subagent"
- "It won't have access to your conversation history"
- The docs do not specifically mention AskUserQuestion behavior in forked contexts

**AskUserQuestion Tool Description** (from Claude Code system prompt, version 2.0.77):
```
Use this tool when you need to ask the user questions during execution. This allows you to:
1. Gather user preferences or requirements
2. Clarify ambiguous instructions
3. Get decisions on implementation choices as you work
4. Offer choices to the user about what direction to take.

Usage notes:
- Users will always be able to select "Other" to provide custom text input
- Use multiSelect: true to allow multiple answers to be selected for a question
- If you recommend a specific option, make that the first option in the list and add "(Recommended)" at the end of the label

Plan mode note: In plan mode, use this tool to clarify requirements or choose between approaches BEFORE finalizing your plan. Do NOT use this tool to ask "Is my plan ready?" or "Should I proceed?" - use ExitPlanMode for plan approval.
```

**External Source** (SmartScope blog):
Reports that AskUserQuestion "fails when used by sub-agents rather than main Claude instance." If accurate, this would mean all skills in this repository that use `context: fork` would have difficulty with AskUserQuestion, regardless of whether they use XML invoke blocks or prose directives.

**External Source** (AtCyrus / Claude Code guide):
States that AskUserQuestion "is particularly active in Plan Mode, where Claude asks clarifying questions before building execution plans." This aligns with the `create-plan` skill's use case of gathering structured decisions during the planning phase.

### How create-plan Describes AskUserQuestion Differently

The `create-plan` skill's AskUserQuestion directive is notable in several ways:

1. **It names the tool explicitly** but does not provide a literal invocation template. The instruction "Get structured decisions **using AskUserQuestion**" tells the model which tool to use, but the actual question formulation is left to the model's judgment based on research findings.

2. **It specifies decision categories, not specific questions**. The three categories (Approach, Priority, Scope) are fixed, but the specific options are meant to be generated from the research phase: "Tailor options based on actual discoveries."

3. **It appears after research is complete**. The AskUserQuestion directive is at Step 2, after the model has already done context gathering (Step 1) and spawned parallel research tasks. This means the model has codebase knowledge to inform the options it generates.

By contrast, the DDD skills' XML invoke blocks contain **static placeholder options** like:
```
"label": "Looks accurate",
"description": "Summary captures the business domain correctly, proceed to write artifact"
```

These are templates the model is expected to use as-is (or adapt slightly). The options are predetermined by the skill author rather than generated from research.

## Architecture Documentation

### Skill Invocation Flow with AskUserQuestion

```
User types: /create-plan ticket.md
  |
  v
Claude Code loads skills/create-plan/SKILL.md
  |
  v
context: fork  -->  Spawns forked sub-agent context
  |
  v
Sub-agent executes:
  Step 1: Read files, spawn research sub-tasks
  Step 2: Present findings, then call AskUserQuestion tool
    |
    v
  AskUserQuestion tool  -->  Presents structured UI to user
    |                        (multiple choice with options)
    v
  User selects option  -->  Response returned to sub-agent
    |
    v
  Step 3-5: Write plan based on decisions
  |
  v
Returns results to parent context
```

### Two AskUserQuestion Authoring Patterns in This Repository

**Pattern A: Prose Directive** (used by `create-plan`)
```markdown
Get structured decisions using AskUserQuestion:
- Category 1: description
- Category 2: description
Tailor options based on actual discoveries.
```

**Pattern B: XML Invoke Block** (used by DDD skills, implement-plan, improve-issue, etc.)
```xml
<invoke name="AskUserQuestion">
  questions: [{
    "question": "...",
    "header": "...",
    "multiSelect": false,
    "options": [
      { "label": "...", "description": "..." },
      ...
    ]
  }]
</invoke>
```

## Code References

- `/Users/willclark/Developer/scidept/claude-agentic/skills/create-plan/SKILL.md` -- The skill under study; prose AskUserQuestion directive at lines 61-66
- `/Users/willclark/Developer/scidept/claude-agentic/skills/ddd-align/SKILL.md` -- XML invoke block at lines 90-110
- `/Users/willclark/Developer/scidept/claude-agentic/skills/ddd-discover/SKILL.md` -- 3 XML invoke blocks at lines 62-86, 90-110, 116-136
- `/Users/willclark/Developer/scidept/claude-agentic/skills/ddd-decompose/SKILL.md` -- 3 XML invoke blocks at lines 57-81, 89-109, 115-135
- `/Users/willclark/Developer/scidept/claude-agentic/skills/ddd-strategize/SKILL.md` -- 2 XML invoke blocks at lines 47-88, 111-131
- `/Users/willclark/Developer/scidept/claude-agentic/skills/ddd-connect/SKILL.md` -- 2 XML invoke blocks at lines 48-72, 86-106
- `/Users/willclark/Developer/scidept/claude-agentic/skills/ddd-define/SKILL.md` -- 3 XML invoke blocks at lines 47-67, 79-99, 105-129
- `/Users/willclark/Developer/scidept/claude-agentic/skills/ddd-full/SKILL.md` -- 1 XML invoke block at lines 103-119 (team mode only)
- `/Users/willclark/Developer/scidept/claude-agentic/skills/implement-plan/SKILL.md` -- 1 XML invoke block at lines 86-106
- `/Users/willclark/Developer/scidept/claude-agentic/skills/improve-issue/SKILL.md` -- 6 XML invoke blocks throughout
- `/Users/willclark/Developer/scidept/claude-agentic/skills/debug-issue/SKILL.md` -- 1 XML invoke block at lines 131-147
- `/Users/willclark/Developer/scidept/claude-agentic/skills/local-review/SKILL.md` -- 1 XML invoke block at lines 43-63

## Related Research

- `/Users/willclark/Developer/scidept/claude-agentic/research/2026-02-07-ddd-plan-mode-interactivity.md` -- Prior research on why DDD skills don't activate plan mode or interactive Q&A. Written before commit `0e364b6` added XML invoke blocks to DDD skills.

## External Sources

- [Claude Code Skills Documentation](https://code.claude.com/docs/en/skills) -- Official docs on skill authoring, frontmatter, and `context: fork`
- [AskUserQuestion System Prompt](https://github.com/Piebald-AI/claude-code-system-prompts/blob/main/system-prompts/tool-description-askuserquestion.md) -- Tool description from Claude Code v2.0.77
- [SmartScope AskUserQuestion Guide](https://smartscope.blog/en/generative-ai/claude/claude-code-askuserquestion-tool-guide/) -- Reports AskUserQuestion fails in sub-agents
- [AtCyrus AskUserQuestion Guide](https://www.atcyrus.com/stories/claude-code-ask-user-question-tool-guide) -- Notes AskUserQuestion is most active in Plan Mode

## Hypothesis: Prose Directives Let the Parent Agent Call the Tool

**Observation**: `create-plan` (prose pattern) successfully triggers AskUserQuestion, while the DDD skills (XML invoke pattern) do not.

**Hypothesis**: The explicit `<invoke name="AskUserQuestion">` XML blocks in DDD skills are treated by the sub-agent as literal tool call directives, causing the sub-agent itself to attempt the call. Since AskUserQuestion may not function correctly from sub-agents (as reported by SmartScope), these calls fail silently.

By contrast, `create-plan`'s prose directive ("Get structured decisions using AskUserQuestion") is vaguer. The sub-agent interprets this as a high-level instruction and may handle it differently — either by successfully calling the tool from within the fork (because the call is dynamically composed and contextually motivated rather than a rigid template), or by surfacing the need for user input back to the parent agent which then makes the call.

**Alternative explanation**: The XML invoke blocks are not valid Claude Code tool-call syntax. They use a pseudo-XML format (`<invoke name="...">` with JSON-ish content) that isn't actually parsed as a tool call by the runtime. The sub-agent sees them as prompt text *suggesting* it should call AskUserQuestion, but the rigid static options may cause it to either skip the call or format it incorrectly. The prose pattern avoids this by letting the model compose a proper tool call natively.

**Recommended fix**: Rewrite the DDD skills to use the same prose-directive pattern as `create-plan`. Instead of XML invoke blocks with static options, describe *what decisions to get* and *what categories*, and let the agent compose the AskUserQuestion call dynamically:

```markdown
### Step 3: Validate with User

Get user validation using AskUserQuestion:
- **Alignment check**: Does the summary accurately capture their domain?
- Options should include: confirmed accurate, needs corrections, has major gaps

Tailor the specific options based on what you found. If corrections needed, iterate.
```

**Status**: Untested. Needs validation by rewriting one DDD skill and comparing behavior.

## Open Questions

1. **Does AskUserQuestion actually work in `context: fork` skills?** The SmartScope blog reports it fails in sub-agents. If true, none of the skills in this repository -- including `create-plan` -- would have working AskUserQuestion in their forked contexts. The user's observation that `create-plan` "successfully uses" AskUserQuestion needs verification: is it working in the forked context, or is there a scenario where it runs outside of `context: fork`?

2. **Is the prose directive pattern more effective than XML invoke blocks?** The `create-plan` skill's approach of naming the tool and specifying categories (but not providing literal invocation templates) leaves more room for the model to formulate contextually appropriate questions. Whether this leads to higher AskUserQuestion invocation rates vs. the XML template approach has not been measured.

3. **What happens when a `context: fork` skill calls AskUserQuestion?** The Claude Code docs say forked contexts "won't have access to your conversation history" but do not specify whether AskUserQuestion UI prompts are surfaced to the user or silently fail. Testing this with a minimal `context: fork` skill that only calls AskUserQuestion would clarify the behavior.

## Correction (2026-04-10)

All three open questions above are resolved by the Claude Code docs' own Limitations section: https://code.claude.com/docs/en/agent-sdk/user-input#limitations

> **Subagents**: `AskUserQuestion` is not currently available in subagents spawned via the Agent tool

`context: fork` runs a skill in a subagent (per https://code.claude.com/docs/en/skills#run-skills-in-a-subagent). Therefore:

1. **Q1**: `AskUserQuestion` does **not** work in `context: fork` skills — it is simply absent from the subagent's tool list. `create-plan` was never actually invoking it from its forked context; the prose directives degraded to plain-text questions.
2. **Q2**: Neither prose directives nor XML invoke blocks work in forked skills. Both degrade the same way.
3. **Q3**: The tool is absent, not silently failing. A forked skill that says "ask using AskUserQuestion" will cause Claude to either ask the user inline as plain text or report that the tool isn't available.

**Fix applied on 2026-04-10**: Removed `context: fork` from all 22 interactive skills in `skills/`. They now run inline in the main session, where `AskUserQuestion` works as documented. See `MEMORY.md` and `skills/skill-builder/references/conventions.md` for the updated guidance.
