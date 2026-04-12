---
date: 2026-02-18T12:00:00-08:00
researcher: Claude
git_commit: 86c8677
branch: main
repository: claude-agentic
topic: "AskUserQuestion permission audit: skills and agents that ask clarifying questions"
tags: [research, permissions, askuserquestion, skills, agents]
status: complete
last_updated: 2026-02-18
last_updated_by: Claude
---

# Research: AskUserQuestion Permission Audit

**Date**: 2026-02-18
**Researcher**: Claude
**Git Commit**: 86c8677
**Branch**: main
**Repository**: claude-agentic

## Research Question

Do any skills or agents that are supposed to ask clarifying questions lack the `AskUserQuestion` permission in their `allowed-tools`?

## Summary

There are 20 skills and 15 agents in the repository. Of the 20 skills, 17 include `AskUserQuestion` in their `allowed-tools` frontmatter and 3 do not. Of the 15 agents, 2 define `allowed-tools` (both include `AskUserQuestion`) and 13 have no `allowed-tools` field at all.

One skill -- `describe-pr` -- instructs the agent to "Ask user which PR to describe" in its step 2 (line 33) but does not include `AskUserQuestion` in its `allowed-tools`. Two agents without `allowed-tools` -- `github-project-manager` and `veteran-qa-engineer` -- contain language about asking questions, but agents are invoked via the Task tool from parent skills/agents where tool access is governed differently than skills with `context: fork`.

Key discoveries:
- The `describe-pr` skill explicitly instructs asking the user (line 33) but lacks `AskUserQuestion` in its tool list
- Agents invoked via Task do not use `allowed-tools` frontmatter the same way skills do; they inherit the parent's tool access
- All other skills that instruct asking questions do include `AskUserQuestion`

## Detailed Findings

### Skills With AskUserQuestion

The following 17 skills include `AskUserQuestion` in their `allowed-tools`:

| Skill | allowed-tools (AskUserQuestion present) |
|-------|----------------------------------------|
| `create-plan` | Read, Grep, Glob, Write, Edit, Task, AskUserQuestion, TodoWrite |
| `iterate-plan` | Read, Grep, Glob, Write, Edit, Task, AskUserQuestion, TodoWrite |
| `implement-plan` | Read, Edit, Write, Grep, Glob, Bash, TodoWrite, AskUserQuestion |
| `research-codebase` | Read, Grep, Glob, Bash(git *), Task, AskUserQuestion, TodoWrite |
| `improve-issue` | Read, Grep, Glob, Task, AskUserQuestion, Bash |
| `debug-issue` | Read, Grep, Glob, Bash, Task, AskUserQuestion |
| `linear` | Read, Grep, Glob, Task, AskUserQuestion, TodoWrite |
| `linear-pm` | Read, Grep, Glob, Task, AskUserQuestion, TodoWrite |
| `local-review` | Read, Grep, Glob, Bash, Write, Edit, AskUserQuestion, Task |
| `skill-builder` | Read, Grep, Glob, Write, Edit, Task, AskUserQuestion, TodoWrite, Bash(git *) |
| `qa` | Read, Grep, Glob, Bash, Task, AskUserQuestion, TodoWrite, mcp__claude-in-chrome__* |
| `pm-synthesize` | Read, Grep, Glob, Write, Edit, AskUserQuestion, Task |
| `ddd-align` | Read, Grep, Glob, Write, Edit, AskUserQuestion |
| `ddd-discover` | Read, Grep, Glob, Write, Edit, AskUserQuestion, Task |
| `ddd-decompose` | Read, Grep, Glob, Write, Edit, AskUserQuestion, Task |
| `ddd-strategize` | Read, Grep, Glob, Write, Edit, AskUserQuestion |
| `ddd-connect` | Read, Grep, Glob, Write, Edit, AskUserQuestion |
| `ddd-define` | Read, Grep, Glob, Write, Edit, AskUserQuestion, Task |
| `ddd-plan` | Read, Grep, Glob, Write, Edit, AskUserQuestion |

### Skills Without AskUserQuestion

**`describe-pr`** (`skills/describe-pr/SKILL.md:5`)

```
allowed-tools: Read, Grep, Glob, Bash(gh *), Bash(git *), Write, Edit
```

Step 2 (line 33) says: "Ask user which PR to describe". This is the only skill that instructs asking the user a question while lacking the `AskUserQuestion` permission.

### Agents With allowed-tools Defined

Two agents define `allowed-tools`, both include `AskUserQuestion`:

| Agent | allowed-tools |
|-------|--------------|
| `ddd-architect` (`agents/ddd-architect.md:4`) | Read, Grep, Glob, Write, Edit, AskUserQuestion, Task, Skill |
| `pm-architect` (`agents/pm-architect.md:4`) | Read, Grep, Glob, Write, Edit, AskUserQuestion, Task, Skill |

### Agents Without allowed-tools (Question-Asking Language)

**`github-project-manager`** (`agents/github-project-manager.md:51`)

Line 51: "When you encounter situations where you're unsure about project conventions or which issue/PR to update, ask for clarification rather than guessing."

This agent has `model: haiku` and no `allowed-tools` field. It is invoked via the Task tool.

**`veteran-qa-engineer`** (`agents/veteran-qa-engineer.md:47`)

Line 47: "You ask probing questions and don't accept 'it should work' as an answer."

This agent has `model: sonnet` and no `allowed-tools` field. It is invoked via the Task tool.

### Agents Without allowed-tools (No Question-Asking Language)

The remaining 11 agents have no `allowed-tools` and do not contain instructions to ask clarifying questions:

- `codebase-locator`
- `codebase-analyzer`
- `codebase-pattern-finder`
- `thoughts-locator`
- `thoughts-analyzer`
- `web-search-researcher`
- `ddd-event-discoverer`
- `ddd-context-analyzer`
- `ddd-canvas-builder`
- `devenv-docker-bash`
- `sitrep`

## Code References

- `skills/describe-pr/SKILL.md:5` - Missing AskUserQuestion in allowed-tools
- `skills/describe-pr/SKILL.md:33` - Instructs "Ask user which PR to describe"
- `agents/github-project-manager.md:51` - "ask for clarification rather than guessing"
- `agents/veteran-qa-engineer.md:47` - "You ask probing questions"
- `agents/ddd-architect.md:4` - Has AskUserQuestion in allowed-tools
- `agents/pm-architect.md:4` - Has AskUserQuestion in allowed-tools
- `skills/skill-builder/references/conventions.md:63` - Convention: "Always use AskUserQuestion for decisions"
- `skills/skill-builder/references/conventions.md:105` - Anti-pattern: "Plain text questions instead of AskUserQuestion"

## Architecture Documentation

### How Tool Permissions Work

**Skills** (`context: fork`) define their tool access via the `allowed-tools` frontmatter field. When a skill runs in a forked context, only the listed tools are available. If `AskUserQuestion` is not in the list, the skill cannot present interactive question prompts to the user.

**Agents** (no `context` field) are invoked via the Task tool from a parent skill or session. Agents without `allowed-tools` inherit tool access from their parent context. The `allowed-tools` field in agent frontmatter is used by the two orchestrator agents (`ddd-architect`, `pm-architect`) which run as top-level agents with their own tool permissions.

### Relevant Convention

From `skills/skill-builder/references/conventions.md:61-63`:
> Always use AskUserQuestion for decisions. Never print questions as plain text.

From `skills/skill-builder/references/conventions.md:105`:
> Anti-pattern: Plain text questions instead of AskUserQuestion

## Open Questions

1. **How does `describe-pr` currently handle step 2?**: Without `AskUserQuestion`, when step 2 says "Ask user which PR to describe," the skill either falls back to plain-text questions (which is listed as an anti-pattern in conventions) or skips asking altogether.
2. **Agent tool inheritance**: The exact mechanism by which agents invoked via Task inherit or receive tool permissions is governed by Claude Code internals, not by repository configuration.

## Correction (2026-04-10)

This audit's central premise — that listing `AskUserQuestion` in `allowed-tools` for a `context: fork` skill would grant access — is incorrect. Per the Claude Code docs (https://code.claude.com/docs/en/agent-sdk/user-input#limitations), `AskUserQuestion` is **unavailable in subagents**, and `context: fork` runs a skill in a subagent. All 17 skills listed above as "having AskUserQuestion" were dead-configured: the line in `allowed-tools` had no effect at runtime.

The real classification at the time of this audit was: 0 skills with a working `AskUserQuestion` and 20 skills where the frontmatter promised it but the runtime couldn't deliver.

**Fix applied on 2026-04-10**: `context: fork` removed from all 22 skills so they run inline, where the tool actually works. The `allowed-tools` lists are otherwise unchanged. Added a warning to `skills/skill-builder/references/conventions.md` so future skill authors don't re-introduce the pairing.
