---
date: 2026-02-07T18:00:00-08:00
researcher: Claude
git_commit: 5ce7243
branch: main
repository: claude-agentic
topic: "How do the DDD prompts handle plan mode and interactive Q&A? Why don't they activate these?"
tags: [research, codebase, ddd, skills, interactivity, plan-mode, AskUserQuestion]
status: complete
last_updated: 2026-02-07
last_updated_by: Claude
---

# Research: How the DDD Skills Handle Interactivity and Plan Mode

**Date**: 2026-02-07
**Git Commit**: 5ce7243
**Branch**: main
**Repository**: claude-agentic

## Research Question

The DDD family of prompts don't seem to activate Claude Code's plan mode and aren't using the interactive question-and-answer mode. How do they actually work?

## Summary

The DDD skills use `context: fork` in their YAML frontmatter, which runs them in a **forked context** (a sub-agent) rather than in the main conversation thread. This is why they do not activate Claude Code's plan mode -- plan mode is a feature of the main conversation loop, not of forked skill contexts. The skills do list `AskUserQuestion` in their `allowed-tools`, and their prompt text describes an interactive Q&A pattern (present findings, ask for validation, iterate). However, the interactivity is defined purely through prose instructions in the skill markdown -- it relies on the LLM following the prompt's instructions to pause and ask questions, rather than using any built-in Claude Code mechanism that enforces plan mode or structured Q&A gating.

## Detailed Findings

### How Skills Are Invoked

All 8 DDD skills are defined in `/Users/willclark/Developer/scidept/claude-agentic/skills/` as subdirectories, each containing a `SKILL.md` file. They are symlinked into `.claude/skills` via `.claude/skills -> ../skills`. When a user types `/ddd_align`, Claude Code loads the corresponding `SKILL.md` and executes it.

Every DDD skill has this frontmatter pattern:

```yaml
---
name: ddd-[step]
description: "DDD Step N: ..."
model: opus
context: fork
allowed-tools: Read, Grep, Glob, Write, Edit, AskUserQuestion [, Task] [, Skill]
argument-hint: [prd-file-path]
---
```

### What `context: fork` Does

The `context: fork` setting is the key mechanism. It means the skill runs in a **forked sub-agent context**, not in the user's main conversation thread. This has several implications:

1. **Separate conversation context**: The skill gets a fresh context with the skill's markdown as its system prompt, plus any `$ARGUMENTS` passed in. It does not see the user's prior conversation history.

2. **No plan mode**: Claude Code's plan mode (where the model outlines what it will do before executing) is a feature of the main conversation loop. Forked contexts do not participate in plan mode. The skill simply executes its instructions directly.

3. **Sub-agent execution model**: The forked context runs to completion (or until it needs user input via `AskUserQuestion`), then returns its results to the parent context.

### How Interactivity Is Designed (Prose-Based)

The DDD skills describe interactivity through their prompt text. Each skill follows a pattern like:

**`ddd-align` (Step 1)** -- `/Users/willclark/Developer/scidept/claude-agentic/skills/ddd-align/SKILL.md`:
- Step 2: "Present findings in this format and ask for corrections"
- Step 3: "If the user corrects or adds information, update the summary"
- Step 3: "Continue until the user confirms the summary is accurate"

**`ddd-discover` (Step 2)** -- `/Users/willclark/Developer/scidept/claude-agentic/skills/ddd-discover/SKILL.md`:
- Step 3: "For each flow, ask about triggers, failure paths, and alternatives"
- Step 4: "For each gap: present clearly, ask user to fill or confirm out of scope"

**`ddd-strategize` (Step 4)** -- `/Users/willclark/Developer/scidept/claude-agentic/skills/ddd-strategize/SKILL.md`:
- Step 3: "For each context, ask user to rate differentiation and complexity. Wait for input before proceeding."

**`ddd-connect` (Step 5)** -- `/Users/willclark/Developer/scidept/claude-agentic/skills/ddd-connect/SKILL.md`:
- Step 4: "ask which pattern fits. Wait for user input on each."

**`ddd-define` (Step 7)** -- `/Users/willclark/Developer/scidept/claude-agentic/skills/ddd-define/SKILL.md`:
- Step 3: "Wait for confirmation on each canvas before proceeding."

**`ddd-full` (Orchestrator)** -- `/Users/willclark/Developer/scidept/claude-agentic/skills/ddd-full/SKILL.md`:
- "Confirmation gates are mandatory" (Guideline 1)
- After each step: "Wait for confirmation."

This interactivity is entirely **instruction-based** -- the prompt tells the LLM to pause and ask questions. There is no programmatic enforcement (no state machine, no gating middleware). Whether the LLM actually pauses depends on how well it follows the instructions.

### The `AskUserQuestion` Tool

All 8 DDD skills list `AskUserQuestion` in their `allowed-tools`. However, only `ddd-full` actually includes an `AskUserQuestion` invocation example in its prompt body -- and that is for the "Agent Team Mode" decision, not for the step-by-step Q&A:

```
<invoke name="AskUserQuestion">
  questions: [{
    "question": "This is a complex DDD workflow. Use an agent team for parallel exploration?",
    "header": "Team Mode",
    ...
  }]
</invoke>
```

(`/Users/willclark/Developer/scidept/claude-agentic/skills/ddd-full/SKILL.md`, lines 103-119)

The individual DDD skills (align, discover, decompose, strategize, connect, define, plan) do not include any `AskUserQuestion` invocation examples in their prompt text. Their interactivity relies on the LLM deciding to use `AskUserQuestion` based on the prose instructions like "ask the user" and "wait for confirmation."

### Comparison with Other Skills That Use `AskUserQuestion`

For contrast, other skills in the repository include explicit `AskUserQuestion` invocation XML in their prompts:

- **`create-plan`** (`/Users/willclark/Developer/scidept/claude-agentic/skills/create-plan/SKILL.md`, line 61): "Get structured decisions using AskUserQuestion" with specific guidance on what to ask
- **`implement-plan`** (`/Users/willclark/Developer/scidept/claude-agentic/skills/implement-plan/SKILL.md`, lines 72-86): Explicit `AskUserQuestion` invocation XML for phase gating
- **`debug-issue`** (`/Users/willclark/Developer/scidept/claude-agentic/skills/debug-issue/SKILL.md`, line 131): Explicit `AskUserQuestion` invocation XML
- **`local-review`** (`/Users/willclark/Developer/scidept/claude-agentic/skills/local-review/SKILL.md`, line 43): Explicit `AskUserQuestion` invocation XML

These skills provide the LLM with a concrete tool invocation example, making it far more likely to actually call `AskUserQuestion` with structured options rather than just printing a question as plain text.

### The `ddd-full` Orchestrator's Delegation Model

The `/ddd_full` skill (`/Users/willclark/Developer/scidept/claude-agentic/skills/ddd-full/SKILL.md`) chains all 7 individual DDD skills using the `Skill` tool in its `allowed-tools`. Its workflow instructions say:

```
### Step 1: Align & Understand
1. Call `/ddd_align` with any provided parameters
2. After artifact is written, confirm with user
Wait for confirmation.
```

This means `ddd-full` calls each individual skill as a nested forked context. The individual skill runs, produces its artifact, and returns. Then `ddd-full` is supposed to present a confirmation gate before calling the next skill. The confirmation gate is also prose-based -- `ddd-full` does not include `AskUserQuestion` invocations for the step gates.

### Hook: Artifact Verification

The `ddd-full` skill has one programmatic enforcement mechanism -- a `TaskCompleted` hook:

```yaml
hooks:
  TaskCompleted:
    - hooks:
        - type: command
          command: "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/verify-artifact-exists.sh"
          timeout: 10
          statusMessage: "Verifying DDD artifact..."
```

(`/Users/willclark/Developer/scidept/claude-agentic/skills/ddd-full/SKILL.md`, lines 8-14)

This hook (`/Users/willclark/Developer/scidept/claude-agentic/.claude/hooks/verify-artifact-exists.sh`) checks whether a task's expected output file actually exists on disk before allowing the task to be marked complete. If the file does not exist, the hook exits with code 2, blocking completion. This ensures artifacts are actually written but does not enforce interactive Q&A.

### The Three DDD Agents

Three DDD agents exist in `/Users/willclark/Developer/scidept/claude-agentic/agents/`:

| Agent | File | Used By | Model | Tools |
|-------|------|---------|-------|-------|
| `ddd-event-discoverer` | `agents/ddd-event-discoverer.md` | `ddd-discover` | sonnet | Read, Grep, Glob, LS |
| `ddd-context-analyzer` | `agents/ddd-context-analyzer.md` | `ddd-decompose` | sonnet | Read, Grep, Glob, LS |
| `ddd-canvas-builder` | `agents/ddd-canvas-builder.md` | `ddd-define` | sonnet | Read, Grep, Glob, LS |

These agents are read-only (no Write, Edit, or AskUserQuestion) and run on the smaller `sonnet` model. They perform analysis and return results to the parent skill, which then handles user interaction. The agents themselves have no interactive capability.

### Why Plan Mode Does Not Activate

To summarize why the DDD skills do not activate plan mode:

1. **`context: fork`**: All DDD skills run in forked sub-agent contexts. Plan mode is a main-conversation-loop feature that does not apply to forked contexts.

2. **No plan mode configuration**: There is no `plan_mode`, `planMode`, or similar setting anywhere in the repository's configuration files. The `.claude/settings.local.json` file contains only permission allowlists.

3. **Skills are execution-oriented**: The skill system is designed for the LLM to execute instructions directly, not to enter a planning phase first. The "Ultrathink" instruction at the top of each skill serves a similar purpose (encouraging the model to reason before acting) but is a prompt technique, not a plan mode activation.

## Architecture Documentation

### How a DDD Skill Invocation Flows

```
User types: /ddd_align path/to/prd.md
  |
  v
Claude Code loads skills/ddd-align/SKILL.md
  |
  v
context: fork  -->  Spawns forked sub-agent context
  |                 (separate from main conversation)
  |                 (no plan mode)
  |
  v
Sub-agent receives:
  - SKILL.md content as system prompt
  - $ARGUMENTS = "path/to/prd.md"
  - allowed-tools: Read, Grep, Glob, Write, Edit, AskUserQuestion
  |
  v
Sub-agent executes prompt instructions:
  1. Reads the PRD file
  2. Analyzes business context
  3. [SHOULD] Present summary and ask for corrections via AskUserQuestion
  4. [SHOULD] Iterate based on feedback
  5. Writes research/ddd/01-alignment.md
  6. Presents "next step" prompt
  |
  v
Returns to parent context (or main conversation)
```

### Interactivity Mechanism Comparison Across Skills

| Skill | Has AskUserQuestion in allowed-tools | Has explicit AskUserQuestion XML in prompt | Interactive Q&A described in prose |
|-------|--------------------------------------|-------------------------------------------|------------------------------------|
| ddd-align | Yes | No | Yes |
| ddd-discover | Yes | No | Yes |
| ddd-decompose | Yes | No | Yes |
| ddd-strategize | Yes | No | Yes |
| ddd-connect | Yes | No | Yes |
| ddd-define | Yes | No | Yes |
| ddd-plan | Yes | No | Yes |
| ddd-full | Yes | Yes (team mode only) | Yes |
| create-plan | Yes | Yes (decisions) | Yes |
| implement-plan | Yes | Yes (phase gates) | Yes |
| debug-issue | Yes | Yes (triage) | Yes |

The DDD skills rely on prose-described interactivity without explicit `AskUserQuestion` invocation examples, while other skills in the repository (create-plan, implement-plan, debug-issue) include concrete `AskUserQuestion` XML examples in their prompts.

## Code References

- `/Users/willclark/Developer/scidept/claude-agentic/skills/ddd-align/SKILL.md` -- Step 1 skill, prose-based interactivity
- `/Users/willclark/Developer/scidept/claude-agentic/skills/ddd-discover/SKILL.md` -- Step 2 skill, spawns ddd-event-discoverer agent
- `/Users/willclark/Developer/scidept/claude-agentic/skills/ddd-decompose/SKILL.md` -- Step 3 skill, spawns ddd-context-analyzer agent
- `/Users/willclark/Developer/scidept/claude-agentic/skills/ddd-strategize/SKILL.md` -- Step 4 skill, prose-based interactivity
- `/Users/willclark/Developer/scidept/claude-agentic/skills/ddd-connect/SKILL.md` -- Step 5 skill, prose-based interactivity
- `/Users/willclark/Developer/scidept/claude-agentic/skills/ddd-define/SKILL.md` -- Step 7 skill, spawns ddd-canvas-builder agent
- `/Users/willclark/Developer/scidept/claude-agentic/skills/ddd-plan/SKILL.md` -- Step 8 skill, bridges to /implement_plan
- `/Users/willclark/Developer/scidept/claude-agentic/skills/ddd-full/SKILL.md` -- Orchestrator, chains all steps
- `/Users/willclark/Developer/scidept/claude-agentic/agents/ddd-event-discoverer.md` -- Read-only agent (sonnet)
- `/Users/willclark/Developer/scidept/claude-agentic/agents/ddd-context-analyzer.md` -- Read-only agent (sonnet)
- `/Users/willclark/Developer/scidept/claude-agentic/agents/ddd-canvas-builder.md` -- Read-only agent (sonnet)
- `/Users/willclark/Developer/scidept/claude-agentic/.claude/hooks/verify-artifact-exists.sh` -- TaskCompleted hook for artifact verification
- `/Users/willclark/Developer/scidept/claude-agentic/.claude/settings.local.json` -- Local settings (permissions only)
- `/Users/willclark/Developer/scidept/claude-agentic/skills/create-plan/SKILL.md` -- Comparison: uses explicit AskUserQuestion XML
- `/Users/willclark/Developer/scidept/claude-agentic/skills/implement-plan/SKILL.md` -- Comparison: uses explicit AskUserQuestion XML for phase gates

## Open Questions

1. When a `context: fork` skill calls `AskUserQuestion`, does Claude Code surface this to the user as a structured prompt (with selectable options), or does it appear as plain text in the forked context's output? The behavior may differ from `AskUserQuestion` in the main conversation thread.

2. Whether `context: fork` skills can effectively multi-turn with the user (ask a question, get an answer, ask another) or whether the fork runs to completion in a single turn. If the latter, the prose-described iterative Q&A pattern in the DDD skills would not work as designed.

3. Whether adding explicit `<invoke name="AskUserQuestion">` XML examples to the DDD skill prompts (as done in create-plan and implement-plan) would increase the likelihood of the model actually using the tool for structured interaction.
