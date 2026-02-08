---
title: Agent Team Coordination Patterns
date: 2026-02-07
type: reference
tags: [agent-teams, coordination, hooks, patterns]
---

# Agent Team Coordination Patterns

Reference documentation for using Claude Code agent teams across skills in this repository.

## Prerequisites

```bash
# Enable agent teams (experimental)
export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1

# Or add to .claude/settings.json:
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

## Skills with Team Support

| Skill | Team Structure | Parallelism | Best For |
|-------|---------------|-------------|----------|
| `/ddd_full` | 3 teammates: discovery, decomposition, mapping | Staged (dependency chain) | Large PRDs |
| `/research_codebase` | 3 teammates: locator, analyzer, pattern-finder | Fully parallel | Complex research |
| `/local_review` | 3 teammates: security, performance, tests | Fully parallel | PR reviews |
| `/debug` | 3 teammates: hypothesis investigators | Fully parallel + adversarial | Complex bugs |

## Coordination Patterns

### Pattern 1: Fully Parallel (research, review, debug)

All teammates start simultaneously on the same input. No dependencies between them.

```
Lead creates tasks:
  Task 1: [perspective-a] — no dependencies
  Task 2: [perspective-b] — no dependencies
  Task 3: [perspective-c] — no dependencies

All teammates claim and start immediately.
Lead synthesizes when all complete.
```

**Best for:** Independent analysis from different angles.

**Example:** Research codebase — locator, analyzer, and pattern-finder all work independently.

### Pattern 2: Staged Pipeline (ddd-full)

Teammates have ordered dependencies. Later stages wait for earlier stages to produce artifacts.

```
Lead creates tasks with dependencies:
  Task 1: Align + Discover → produces 01-alignment.md, 02-event-catalog.md
  Task 2: Decompose + Strategize → blocked by Task 1, produces 03-sub-domains.md, 04-strategy.md
  Task 3: Connect + Define → blocked by Task 2, produces 05-context-map.md, 06-canvases.md

Teammates claim tasks as they become unblocked.
Lead runs final step (Plan) after all complete.
```

**Best for:** Workflows where each stage needs output from the previous stage.

### Pattern 3: Adversarial Investigation (debug)

Teammates actively challenge each other's findings.

```
Lead formulates 3 hypotheses, creates tasks:
  Task 1: Investigate Hypothesis A — find evidence for/against
  Task 2: Investigate Hypothesis B — find evidence for/against
  Task 3: Investigate Hypothesis C — find evidence for/against

Teammates message each other with counter-evidence.
Lead converges on the theory with strongest support.
```

**Best for:** Root cause analysis where anchoring bias is a risk.

## Hook Integration

### Skill-Scoped Hooks

Hooks defined in skill frontmatter are active only while the skill runs:

```yaml
---
name: my-skill
hooks:
  PostToolUse:
    - matcher: "Write|Edit"
      hooks:
        - type: command
          command: "$CLAUDE_PROJECT_DIR/.claude/hooks/lint-on-save.sh"
  TaskCompleted:
    - hooks:
        - type: command
          command: "$CLAUDE_PROJECT_DIR/.claude/hooks/verify-artifact-exists.sh"
---
```

### Available Team Hooks

| Hook | When | Can Block? | Supports Matchers? |
|------|------|------------|-------------------|
| `TeammateIdle` | Teammate about to go idle | Yes (exit 2) | No |
| `TaskCompleted` | Task being marked complete | Yes (exit 2) | No |

### TeammateIdle Hook

Runs when a teammate finishes its turn. Exit 2 to keep the teammate working:

```bash
#!/bin/bash
# Check that the teammate produced output
if [ ! -f "./dist/output.js" ]; then
  echo "Output missing. Continue working." >&2
  exit 2
fi
exit 0
```

**Limitation:** TeammateIdle only supports command hooks, not prompt or agent hooks.

### TaskCompleted Hook

Runs when any agent marks a task as completed. Exit 2 to prevent completion:

```bash
#!/bin/bash
INPUT=$(cat)
TASK_SUBJECT=$(echo "$INPUT" | jq -r '.task_subject')

# Verify tests pass before allowing completion
if ! npm test 2>&1; then
  echo "Tests failing. Fix before completing: $TASK_SUBJECT" >&2
  exit 2
fi
exit 0
```

**Input fields:** `task_id`, `task_subject`, `task_description`, `teammate_name`, `team_name`

## Best Practices

### Task Design

- **5-6 tasks per teammate** keeps everyone productive
- Tasks should be **self-contained** with clear deliverables
- Include **expected output file paths** in task descriptions for hook verification
- Use **task dependencies** (blockedBy) for staged pipelines

### Avoiding Conflicts

- Each teammate should own **different files** — never have two teammates edit the same file
- For code review, teammates only **read** — the lead synthesizes
- For DDD, each teammate produces **different artifact files**

### Prompting Teammates

Give teammates specific, detailed context:

```
Spawn a security reviewer teammate with the prompt:
"Review src/auth/ for security vulnerabilities.
Focus on: token handling, session management, input validation.
The app uses JWT tokens in httpOnly cookies.
Report issues with severity ratings to research/review-security.md"
```

### Monitoring

- Check in on teammates regularly — don't let them run unattended too long
- Use `Shift+Up/Down` (in-process mode) to cycle through teammates
- If a teammate gets stuck, message them directly or spawn a replacement

### Cost Awareness

- Each teammate is a full Claude instance — token usage scales linearly
- Team mode is best for **complex** tasks where parallel exploration justifies the cost
- For routine tasks, single session with sub-agents is more cost-effective

## Limitations

- No session resumption with in-process teammates
- One team per session — clean up before starting a new team
- No nested teams — teammates cannot spawn their own teams
- Lead is fixed for the session lifetime
- All teammates start with the lead's permission settings

## Hook Scripts

Available in `.claude/hooks/`:

| Script | Purpose | Used By |
|--------|---------|---------|
| `lint-on-save.sh` | Auto-detect and run project linter on Write/Edit | implement-plan |
| `verify-artifact-exists.sh` | Verify expected output files exist on TaskCompleted | ddd-full, debug-issue |
