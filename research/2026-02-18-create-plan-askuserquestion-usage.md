---
date: 2026-02-18T14:00:00-08:00
researcher: Claude
git_commit: 363e3ac
branch: main
repository: claude-agentic
topic: "How does /create-plan use AskUserQuestion?"
tags: [research, codebase, skills, AskUserQuestion, create-plan]
status: complete
last_updated: 2026-02-18
last_updated_by: Claude
---

# Research: How Does /create-plan Use AskUserQuestion?

**Date**: 2026-02-18
**Git Commit**: 363e3ac
**Branch**: main
**Repository**: claude-agentic

## Research Question

What does /create-plan do with AskUserQuestion? Does it use it, and if so, how?

## Summary

The `create-plan` skill **does** use AskUserQuestion. It is listed in the skill's `allowed-tools` frontmatter and is referenced four times in the SKILL.md body. The skill uses a **prose directive** pattern rather than explicit XML invoke blocks -- it tells the agent *what decisions to gather* using AskUserQuestion but leaves the specific question formulation and option generation to the agent at runtime.

AskUserQuestion appears at three distinct stages of the create-plan workflow: during research and discovery (Step 2), during technical decisions (Step 3), and during Linear sync (Step 7). Each usage follows the same pattern: a prose instruction naming the tool, a list of decision categories, and guidance to tailor options based on context.

Key discoveries:
- `create-plan` includes `AskUserQuestion` in its `allowed-tools` (line 6)
- The skill references AskUserQuestion in 4 locations across 3 workflow steps
- All references use prose directives (e.g., "Get structured decisions using AskUserQuestion"), not XML invoke blocks
- This prose pattern is documented in the project's MEMORY.md as the preferred approach for skills running in `context: fork`

## Detailed Findings

### Frontmatter Configuration

**Location**: `skills/create-plan/SKILL.md:1-8`

The skill's frontmatter declares AskUserQuestion as an allowed tool:

```yaml
---
name: create-plan
description: Create detailed implementation plans through interactive research and iteration. Optionally syncs plan to Linear tickets with phase sub-issues.
model: opus
context: fork
allowed-tools: Read, Grep, Glob, Write, Edit, Task, AskUserQuestion, TodoWrite
argument-hint: [ticket-or-description]
---
```

The skill runs in a forked sub-agent context (`context: fork`).

### Usage 1: Research & Discovery (Step 2, line 68)

After research sub-tasks complete and findings are presented, the skill instructs the agent to gather design decisions:

```markdown
5. **Get structured decisions** using AskUserQuestion:
   - **Approach**: Which design option to pursue (from research)
   - **Priority**: Speed vs quality vs simplicity
   - **Scope**: Full vs MVP vs phased

   Tailor options based on actual discoveries. Don't use generic options.
```

This directs the agent to ask about three decision categories. The specific options are generated dynamically from what was found during research, not predetermined.

### Usage 2: Technical Decisions (Step 3, line 79)

For each significant technical decision surfaced during research:

```markdown
For each significant technical decision (e.g. library choice, data model design, API pattern, migration strategy), get a decision using AskUserQuestion:
- **[Decision topic]**: Present the trade-offs clearly
- Options should reflect the realistic choices discovered during research, with brief pros/cons for each
- Include an "I need more info" option for decisions the user isn't ready to make
```

This is conditional -- it only fires when research surfaces choices that affect the plan. The skill lists common technical decision categories (architecture, data model, API design, migration, dependencies, testing strategy) as examples but does not prescribe fixed options.

### Usage 3: Linear Sync (Step 7, lines 121 and 129)

Two AskUserQuestion references appear in the Linear sync step:

**Line 121** -- When no Linear ticket was detected:
```markdown
**If no Linear ticket**: Get decision using AskUserQuestion:
- **Linear sync**: Would you like to attach this plan to a Linear ticket?
- Options should cover: yes (provide ticket ID), no thanks, create a new ticket for this
```

**Line 129** -- When determining workspace:
```markdown
1. **Determine the workspace** from the ticket identifier prefix or ask using AskUserQuestion if ambiguous.
```

### Prose Directive Pattern

All four AskUserQuestion references in create-plan follow the same pattern:

1. Name the tool explicitly ("using AskUserQuestion" or "ask using AskUserQuestion")
2. Specify the decision category in bold (e.g., "**Approach**", "**Linear sync**")
3. Describe what the options should cover, without hardcoding specific option labels
4. Include guidance to tailor options to context ("Tailor options based on actual discoveries")

This pattern is documented in the project's `MEMORY.md` as the preferred approach:

> **AskUserQuestion in skills**: Use **prose directives** (like create-plan), NOT `<invoke name="AskUserQuestion">` XML blocks. XML invoke blocks are treated as literal text by sub-agents in `context: fork` and don't trigger actual tool calls.

## Code References

- `skills/create-plan/SKILL.md:6` - AskUserQuestion in allowed-tools
- `skills/create-plan/SKILL.md:68` - Step 2 prose directive for design decisions
- `skills/create-plan/SKILL.md:79` - Step 3 prose directive for technical decisions
- `skills/create-plan/SKILL.md:121` - Step 7 prose directive for Linear sync decision
- `skills/create-plan/SKILL.md:129` - Step 7 prose directive for workspace determination

## Architecture Documentation

### AskUserQuestion Invocation Flow in create-plan

```
User invokes: /create-plan [input]
  |
  v
Claude Code spawns forked sub-agent (context: fork)
  |
  v
Step 1: Context Gathering (parallel research tasks)
  |
  v
Step 2: Present findings --> AskUserQuestion (Approach, Priority, Scope)
  |                           options generated from research findings
  v
Step 3: Technical Decisions --> AskUserQuestion per decision (conditional)
  |                              options from trade-offs found in research
  v
Steps 4-6: Write plan, review, iterate
  |
  v
Step 7: Linear Sync --> AskUserQuestion (attach to ticket? which workspace?)
```

### Pattern: Prose Directive vs XML Invoke

The create-plan skill uses the prose directive pattern exclusively. Other skills in the repository (DDD skills, implement-plan, improve-issue, etc.) use explicit XML `<invoke name="AskUserQuestion">` blocks with predetermined options. The project convention (per MEMORY.md) recommends the prose directive pattern for `context: fork` skills.

## Related Research

- `research/2026-02-08-create-plan-askuserquestion-comparison.md` - Detailed comparison of how create-plan uses AskUserQuestion vs other skills; analysis of prose directive vs XML invoke patterns
- `research/2026-02-18-askuserquestion-permission-audit.md` - Audit of which skills/agents have AskUserQuestion permissions
- `research/2026-02-07-ddd-plan-mode-interactivity.md` - Prior research on DDD skill interactivity

## Open Questions

1. **Runtime behavior in `context: fork`**: Whether the prose directive pattern reliably triggers AskUserQuestion calls within a forked sub-agent context has not been systematically measured. The prior research document (2026-02-08) notes that external sources report AskUserQuestion "fails when used by sub-agents" but this has not been confirmed for this specific codebase.

## Correction (2026-04-10)

Resolved. The Claude Code docs' Limitations section (https://code.claude.com/docs/en/agent-sdk/user-input#limitations) confirms that `AskUserQuestion` is not available in subagents spawned via the Agent tool, and `context: fork` runs a skill in a subagent. The prose directive pattern in `create-plan` did not trigger real AskUserQuestion calls — it degraded to plain-text questions, which is why the user saw Claude reporting "I don't have AskUserQuestion available here" in the sibling skill `improve-issue`.

**Fix applied on 2026-04-10**: Removed `context: fork` from all 22 interactive skills (including `create-plan`). The prose directive pattern itself is still fine — it just needs to run in the main session context, not a forked one. Authors writing new skills that need `AskUserQuestion` must leave `context` unset.
