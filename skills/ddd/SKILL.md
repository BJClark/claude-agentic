---
name: ddd
description: Start or resume the full DDD domain discovery workflow. Sequences all 7 DDD step-skills inline with confirmation gates between each step.
model: sonnet
allowed-tools: Read, Grep, Glob, Write, AskUserQuestion, Skill, TodoWrite
argument-hint: [prd-file-path]
---

**Architecture note**: This skill runs inline (not forked) because it uses `AskUserQuestion` gates between each DDD step. Forked skills cannot use `AskUserQuestion` — any gate call in a forked context silently degrades to a skipped question, meaning steps run without user confirmation. This is the root cause of the gate bug that existed when `/ddd` spawned `ddd-architect` as a Task subagent: that agent declared `AskUserQuestion` in its frontmatter but those gates were never reachable from within the subagent context.

<!--
Gate bug note (Phase 3a): The former commands/ddd.md spawned ddd-architect as a Task subagent.
ddd-architect declared AskUserQuestion in its allowed-tools, but AskUserQuestion does not
exist in any subagent (forked skill or Task agent). As a result, all "confirmation gates
between steps" silently degraded — steps ran without user confirmation. This skill fixes that
by running inline with real AskUserQuestion gates.
-->

# DDD Full Workflow

**Input**: $ARGUMENTS (optional: path to PRD or product spec)

## Initial State Check

Check for existing DDD artifacts at `research/ddd/0*.md` using Glob.

**If artifacts exist**, show the user what's already done:

```
Found existing DDD artifacts:
- research/ddd/01-alignment.md ✓
- research/ddd/02-event-catalog.md ✓
- (etc.)

Next incomplete step: Step N ([step name])
```

Then use AskUserQuestion: "Resume from Step N, or start fresh? (resume / fresh)"

**If no artifacts**, proceed from Step 1 with the provided PRD path.

## DDD Step Sequence

Run each step in order. After each step completes, gate before proceeding.

### Step 1: Align
Invoke `Skill(ddd-align)` with:
- The PRD file path (from $ARGUMENTS or ask user)
- If resuming, indicate which step

After completion, use AskUserQuestion:
"Step 1 (Align) complete. Review `research/ddd/01-alignment.md` and confirm. Proceed to Step 2 (Discover)? (yes / stop)"

If user says stop, exit with a summary of what was completed.

### Step 2: Discover
Invoke `Skill(ddd-discover)`.

After completion, use AskUserQuestion:
"Step 2 (Discover) complete. Review `research/ddd/02-event-catalog.md`. Proceed to Step 3 (Decompose)? (yes / stop / redo)"

If redo: re-invoke ddd-discover with user's feedback, then gate again.
If stop: exit with summary.

### Step 3: Decompose
Invoke `Skill(ddd-decompose)`.

After completion, use AskUserQuestion:
"Step 3 (Decompose) complete. Review `research/ddd/03-sub-domains.md`. Proceed to Step 4 (Strategize)? (yes / stop / redo)"

### Step 4: Strategize
Invoke `Skill(ddd-strategize)`.

After completion, use AskUserQuestion:
"Step 4 (Strategize) complete. Review `research/ddd/04-strategy.md`. Proceed to Step 5 (Connect)? (yes / stop / redo)"

### Step 5: Connect
Invoke `Skill(ddd-connect)`.

After completion, use AskUserQuestion:
"Step 5 (Connect) complete. Review `research/ddd/05-context-map.md`. Proceed to Step 6 (Define)? (yes / stop / redo)"

### Step 6: Define
Invoke `Skill(ddd-define)`.

After completion, use AskUserQuestion:
"Step 6 (Define) complete. Review `research/ddd/06-canvases.md`. Proceed to Step 7 (Plan)? (yes / stop / redo)"

### Step 7: Plan
Invoke `Skill(ddd-plan)`.

After completion, present the final summary:

```
DDD Discovery Workflow Complete!

Artifacts produced:
- research/ddd/01-alignment.md
- research/ddd/02-event-catalog.md
- research/ddd/03-sub-domains.md
- research/ddd/04-strategy.md
- research/ddd/05-context-map.md
- research/ddd/06-canvases.md
- plans/[date]-ddd-*.md

Next step: /implement-plan plans/[date]-ddd-*.md
```

## Architecture Notes

The Architect-family specialists (`ddd-event-discoverer`, `ddd-context-analyzer`, `ddd-canvas-builder`) are Opus workers that the step-skills call internally. This orchestrator calls the step-skills in sequence; the step-skills handle agent delegation.

Step-skill sequence: `ddd-align` → `ddd-discover` → `ddd-decompose` → `ddd-strategize` → `ddd-connect` → `ddd-define` → `ddd-plan`
