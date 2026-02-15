# Skill Conventions Reference

Quick reference for building skills in this repo. Distilled from analyzing existing skills.

## Frontmatter Fields

| Field | Required | Description | Example |
|-------|----------|-------------|---------|
| `name` | Yes | kebab-case identifier, matches folder name | `create-plan` |
| `description` | Yes | WHAT + WHEN in one sentence | `"Create plans. Use when starting implementation."` |
| `model` | No | Model to use (default: opus) | `opus` |
| `context` | No | Execution context | `fork` |
| `allowed-tools` | No | Comma-separated tool list | `Read, Grep, Glob, Write` |
| `argument-hint` | No | Hint shown in CLI | `[ticket-id]` |
| `user-invocable` | No | Can user call directly | `true` |
| `hooks` | No | PostToolUse hooks | See hooks section |

## Tool Permission Patterns

**Research-only** (read the codebase, no changes):
```
allowed-tools: Read, Grep, Glob, Bash(git *), TodoWrite
```

**Research + interaction** (read and ask questions):
```
allowed-tools: Read, Grep, Glob, Task, AskUserQuestion, TodoWrite
```

**Research + write** (produce artifacts):
```
allowed-tools: Read, Grep, Glob, Write, Edit, Task, AskUserQuestion, TodoWrite
```

**Full implementation** (modify code):
```
allowed-tools: Read, Grep, Glob, Write, Edit, Task, AskUserQuestion, TodoWrite, Bash
```

## Template Variables

Git context commands use `!` prefix with backticks:
```
- **Branch**: !`git branch --show-current 2>/dev/null || echo "N/A"`
- **Last Commit**: !`git log -1 --oneline 2>/dev/null || echo "N/A"`
- **Modified Files**: !`(git status --short 2>/dev/null || echo "N/A") | head -10`
```

User input is referenced as `$ARGUMENTS`.

## Output Path Conventions

| Artifact Type | Path |
|--------------|------|
| Plans | `thoughts/shared/plans/YYYY-MM-DD-description.md` |
| Research | `research/YYYY-MM-DD-topic.md` |
| DDD artifacts | `research/ddd/NN-name.md` |
| PR descriptions | `prs/{number}_description.md` |
| Tickets | `thoughts/shared/tickets/ENG-xxxx.md` |

## AskUserQuestion Patterns

Always use AskUserQuestion for decisions. Never print questions as plain text.

**Good**: Tailored options based on actual findings
```
Get decision using AskUserQuestion:
- **Approach**: Which design pattern fits better?
- Options should cover: Repository pattern (matches existing UserStore), Service layer (simpler but less consistent), Event-driven (most flexible but complex)
```

**Bad**: Generic yes/no
```
Ask the user: "Should I proceed?" with options Yes/No
```

## Hooks

PostToolUse hooks run scripts after specific tools:
```yaml
hooks:
  PostToolUse:
    - matcher: "Write|Edit"
      hooks:
        - type: command
          command: ".claude/hooks/lint-on-save.sh"
          timeout: 30
          statusMessage: "Running lint check..."
```

## Sub-Agent Types

Available for Task tool:
- `codebase-locator`: Find WHERE files/components live
- `codebase-analyzer`: Understand HOW code works
- `codebase-pattern-finder`: Find similar patterns/examples
- `thoughts-locator`: Find relevant documents in thoughts/
- `thoughts-analyzer`: Extract insights from documents
- `web-search-researcher`: External docs/resources

## Anti-Patterns

- Vague descriptions that don't say WHEN to trigger
- Over-permissioned tool lists (granting Write when only Read needed)
- Plain text questions instead of AskUserQuestion
- Generic AskUserQuestion options (yes/no) instead of tailored choices
- Everything in SKILL.md instead of using templates/ and references/
- Missing error handling for common failures
- No examples showing realistic usage
- XML/HTML tags in skill content
