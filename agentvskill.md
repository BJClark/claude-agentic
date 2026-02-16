```markdown
# Claude Code: Agents, Commands & Skills Reference

## Quick Definitions

### Agent
**What**: Autonomous Claude instances with specific tools/permissions/models
- **Main Claude**: The agent you're talking to
- **Sub-agents**: Specialists Claude spawns for complex tasks
- **Custom agents**: User-defined configurations in `.claude/agents/`

### Command (Legacy)
**What**: User-invoked shortcuts stored as `.md` files
- Location: `.claude/commands/`
- Invocation: Always manual via `/command-name`
- Status: Still works, but skills are preferred

### Skill
**What**: Smart capabilities Claude can discover OR you manually trigger
- Location: `.claude/skills/skill-name/SKILL.md`
- Invocation: Auto-discovered by Claude OR manual via `/skill-name`
- Structure: YAML frontmatter + instructions + optional support files
- Standard: Follows [Agent Skills open standard](https://agentskills.io)

---

## Decision Framework

| Use... | When... | Example |
|--------|---------|---------|
| **Skill** | Repeatable workflow Claude should auto-discover | Converting feature requests to user stories |
| **Command** | Explicit task you always control timing of | Daily standup updates |
| **Agent** | Complex multi-step work needing different permissions/model | Competitive research with web scraping |

---

## Key Differences

**Skills vs Commands**
- Skills: Claude can auto-load when relevant + manual invocation
- Commands: Manual only, explicit control

**Skills vs Agents**
- Skills: Instructions for Claude to follow
- Agents: Separate Claude instances with isolated context

**When to use Agents**
- Different tool permissions needed
- Heavier model required (Opus vs Sonnet)
- Multi-step autonomous work
- Parallel execution

---

## Product Management Example

### Skill: User Story Generator
```yaml
# .claude/skills/user-story/SKILL.md
---
name: user-story
description: Creates user stories from feature requests. Use when writing user stories, requirements, or acceptance criteria.
---

# User Story Generator

Convert feature requests into properly formatted user stories with:
- As a [user type]
- I want to [action]
- So that [benefit]

Include acceptance criteria and edge cases.
```

**Why**: Claude auto-suggests when you paste feature requests, OR you invoke manually.

---

### Command: Standup Update
```markdown
# .claude/commands/standup.md
---
name: standup
description: Generate my standup update from today's work
---

Review git commits and modified files from today. Create standup update:
- What I completed today
- What I'm working on next
- Any blockers
```

**Why**: Daily ritual you control timing of—never want auto-invoked.

---

### Agent: Competitive Analysis
```yaml
# .claude/agents/competitive-analysis.md
---
name: competitive-analysis
allowed-tools: 
  - Read
  - Bash(curl *)
  - web_search
model: claude-opus-4-5
description: Deep competitive research specialist with web access
---

# Competitive Analysis Agent

Research competitors by:
1. Web scraping product pages
2. Analyzing pricing/features
3. Reading reviews/discussions
4. Synthesizing findings

Deliver structured competitive intelligence report.
```

**Why**: Needs web access + heavier model + multi-step autonomous research.

---

## Typical Workflow

**Request**: "Analyze Notion's new AI features"

1. **Main Claude** → spawns `competitive-analysis` **agent**
2. **Agent** → researches, scrapes, synthesizes (returns to main Claude)
3. **Main Claude** → auto-loads `/user-story` **skill** to create actionable stories
4. **You** → manually run `/standup` **command** to package for meeting

---

## Migration Path

**Old**: Everything as commands in `.claude/commands/`  
**New**: Skills in `.claude/skills/` (commands still work but deprecated)

**Convert command to skill**:
1. Create directory: `.claude/skills/my-skill/`
2. Move content to `SKILL.md` with frontmatter
3. Add description for auto-discovery
4. Delete old command file (optional)

---

## Best Practices

**Skills**
- Clear, specific descriptions (Claude uses this for auto-discovery)
- Use `disable-model-invocation: true` if manual-only
- Bundle related files in skill directory

**Agents**
- Grant minimal necessary permissions
- Use heavier models only when needed
- Clear delegation criteria in description

**Commands** (if still using)
- Migrate to skills for better discoverability
- Keep for explicit-only workflows temporarily
```