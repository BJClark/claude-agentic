---
name: pm
description: Start or resume the PM workspace build workflow. Synthesizes story map and DDD artifacts into a Linear build plan via the pm-synthesize inline persona, with confirmation gates.
model: sonnet
allowed-tools: Read, Grep, Glob, Write, AskUserQuestion, Skill, TodoWrite
argument-hint: [story-map-path]
---

**Architecture note**: This skill runs inline (not forked) because it uses `AskUserQuestion` gates between PM workflow stages. Forked skills cannot use `AskUserQuestion` — any gate call in a forked context silently degrades to a skipped question.

<!--
Gate bug note (Phase 3a): The former commands/pm.md spawned pm-architect as a Task subagent.
pm-architect declared AskUserQuestion in its allowed-tools, but AskUserQuestion does not
exist in any subagent context. All "confirmation gates" silently degraded — the PM workflow
ran without user confirmation. This skill fixes that by running inline.

Rationalization of pm-architect vs pm-synthesize: pm-architect was the now-retired
orchestrating agent that drove the PM workflow. pm-synthesize is the single inline PM persona
that does the actual synthesis work. With the orchestration moved inline here, pm-synthesize
is the only PM path. pm-architect is retired (Phase 2).
-->

# PM Workspace Build Workflow

**Input**: $ARGUMENTS (optional: path to story map)

## Initial State Check

Check for existing artifacts using Glob:
- `.jeff/*STORY_MAP*.md` — story map (required)
- `research/pm/build-plan.md` — existing build plan (resume candidate)
- `research/ddd/0*.md` — DDD artifacts (optional enrichment)

**If a build plan exists**, read its YAML frontmatter to check status, then show:

```
Found existing build plan:
- research/pm/build-plan.md (status: {status})
- {n} issues, {m} with Linear IDs

Story map: .jeff/{NAME}_STORY_MAP.md ✓
DDD artifacts: {count} found
```

Use AskUserQuestion: "A build plan already exists. Resume building, re-synthesize from scratch, or review the current plan? (resume / re-synthesize / review)"

**If no build plan but story map exists**, show:

```
Found artifacts:
- Story map: .jeff/{NAME}_STORY_MAP.md ✓
- DDD artifacts: {count} found
- No existing build plan

Ready to synthesize a Linear build plan from these artifacts.
```

Use AskUserQuestion: "Ready to synthesize. Proceed? (yes / stop)"

**If no story map found**:

```
No story map found in .jeff/. Run /jeff-map first to create one.
```

Then stop.

## Synthesis Stage

Invoke `Skill(pm-synthesize)` with:
- Story map path (from $ARGUMENTS or discovered above)
- Whether resuming from an existing build plan
- Any additional arguments the user provided
- DDD artifact paths if found

After pm-synthesize completes, use AskUserQuestion:
"Build plan synthesis complete. Review `research/pm/build-plan.md`. Options: (1) approve and proceed to Linear creation, (2) iterate on the plan, (3) stop here"

**If iterate**: ask user what to change, re-invoke pm-synthesize with feedback, then gate again.

**If approve**: proceed to the next stage (Linear creation if available, otherwise surface the plan for manual use).

## Completion

Present a summary:

```
PM Workspace Build Complete!

Artifacts produced:
- research/pm/build-plan.md

Next steps:
- Review build-plan.md with your team
- Use /linear to bulk-create issues from the plan (if Linear MCP is configured)
- Or export manually to your project management tool
```
