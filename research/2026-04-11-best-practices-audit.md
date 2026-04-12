---
date: 2026-04-11
researcher: Claude Opus 4.6
git_commit: a51adad
branch: main
repository: scidept/claude-agentic
topic: Best practices audit of skills, agents, and commands
tags: [audit, best-practices, QRSPI, skills-guide, context-engineering]
status: complete
sources:
  - QRSPI.md (HumanLayer's QRSPI pipeline)
  - The Complete Guide to Building Skills for Claude (Anthropic PDF, 33 pages)
  - https://code.claude.com/docs/en/agent-sdk/todo-tracking
  - https://code.claude.com/docs/en/agent-sdk/subagents
  - https://code.claude.com/docs/en/tools-reference
---

# Best Practices Audit: Skills, Agents, and Commands

## Research Question

Where is this repo drifting from best practices as defined by QRSPI (HumanLayer), Anthropic's Complete Guide to Building Skills, and Claude Code's official documentation on subagents, task tracking, and tools?

## Summary

The repo contains **22 skills**, **15 agents**, and **14 commands** — 51 total prompt artifacts. Several structural drifts emerge when compared against three authoritative sources. The most impactful issues are: (1) instruction budget overload from too many simultaneous skills, (2) missing trigger phrases in 68% of skill descriptions, (3) duplicate coverage between skills and commands for the same domain, and (4) nearly universal use of `model: opus` when cheaper models should handle most execution.

---

## 1. Skill Description Quality

### Best Practice (Anthropic Skills Guide, p.10-12)

> Description MUST include BOTH: what the skill does + when to use it (trigger conditions). Structure: `[What it does] + [When to use it] + [Key capabilities]`. Include specific tasks users might say.

### Current State

| Quality | Count | Percentage |
|---------|-------|------------|
| Good (has WHAT + WHEN) | 7 | 32% |
| Missing triggers (WHAT only) | 15 | 68% |

**Good descriptions** (7): `ddd-align`, `linear`, `linear-pm`, `linear-ticket-status-sync`, `pm-synthesize`, `qa`, `skill-builder`

**Missing trigger phrases** (15): `analyze-project`, `create-plan`, `ddd-connect`, `ddd-decompose`, `ddd-define`, `ddd-discover`, `ddd-plan`, `ddd-strategize`, `debug-issue`, `describe-pr`, `implement-plan`, `improve-issue`, `iterate-plan`, `local-review`, `research-codebase`

### Impact

Without "Use when..." phrasing, Claude cannot reliably auto-trigger skills. Users must manually invoke them via `/skill-name`. The Anthropic guide explicitly warns: "Skill doesn't load when it should — Solution: Add more detail and nuance to the description."

---

## 2. Instruction Budget & Context Pressure

### Best Practice (QRSPI, p.1-3)

> Each QRSPI stage contains fewer than 40 instructions. Frontier LLMs lose consistency after ~150-200 instructions. Claude Code's system prompt consumes ~50 instructions before any user config. CLAUDE.md should be under 60 lines.

### Best Practice (Anthropic Skills Guide, p.27)

> Keep SKILL.md under 5,000 words. Evaluate if you have more than 20-50 skills enabled simultaneously. Consider selective enablement.

### Current State

**Skills body line counts (top 5):**
- `analyze-project`: 297 lines
- `skill-builder`: 246 lines
- `linear-ticket-status-sync`: 222 lines
- `improve-issue`: 222 lines
- `qa`: 218 lines

**Total across all SKILL.md files: 3,345 lines**

**Commands (top 3):**
- `linear.md`: 391 lines, ~45 directives
- `linear_pm.md`: 293 lines, ~35 directives
- `resume_handoff.md`: 218 lines, ~30 directives

**Combined: 22 skills + 14 commands = 36 prompt artifacts** whose frontmatter (level 1) is loaded into every session. The 15 agents add further description text to the system prompt.

### Impact

`linear.md` alone at ~45 directives exceeds QRSPI's 40-instruction ceiling per stage. When combined with Claude Code's ~50 base instructions plus all skill/agent descriptions, the total instruction count in the system prompt is well above the 150-200 instruction consistency threshold.

---

## 3. Model Selection

### Best Practice (QRSPI, p.4; Claude Code Subagents docs)

> Opus for parent/orchestration. Sonnet or Haiku for scoped sub-tasks — code writing, test execution, codebase searching.

### Current State

**Skills:** 20 use `model: opus`, 1 uses `model: sonnet` (`linear-ticket-status-sync`), 1 has no model field (`describe-pr`).

**Agents:** 9 sonnet, 2 opus (orchestrators: `ddd-architect`, `pm-architect`), 2 haiku (`github-project-manager`, `sitrep`), 1 inherit (`devenv-docker-bash`).

### Analysis

The agent model allocation is well-aligned with QRSPI: research/analysis agents on sonnet, orchestrators on opus, lightweight reporters on haiku.

Skills are the opposite — 20 of 22 on opus. Skills like `describe-pr` (PR description generation), `linear-ticket-status-sync` (ticket status updates), and the DDD chain steps (connect, decompose, define, discover, plan, strategize) are scoped tasks that could run on sonnet.

---

## 4. Skills vs. Commands Duplication

### Current State

Several domains have both a skill AND a command covering the same functionality:

| Domain | Skill | Command | Skill Lines | Command Lines |
|--------|-------|---------|-------------|---------------|
| Linear tickets | `skills/linear/` | `commands/linear.md` | 148 | 391 |
| Linear PM | `skills/linear-pm/` | `commands/linear_pm.md` | 207 | 293 |
| Commit | — | `commands/commit.md` | — | 43 |
| Plan creation | `skills/create-plan/` | — | 134 | — |
| Implementation | `skills/implement-plan/` | — | 113 | — |

### Impact

When both `skills/linear/SKILL.md` and `commands/linear.md` are loaded, Claude receives two sets of potentially conflicting instructions for the same domain. The command version is 2.6x larger than the skill version. This doubles context consumption without clear benefit.

Per the Anthropic Skills Guide: "Skills are one of the most powerful ways to customize Claude... Instead of re-explaining your preferences, processes, and domain expertise in every conversation." Skills are the recommended replacement for commands.

---

## 5. Progressive Disclosure

### Best Practice (Anthropic Skills Guide, p.5, 13)

> Three-level system: (1) Frontmatter — always loaded, (2) SKILL.md body — loaded when relevant, (3) references/ — discovered on demand. Move detailed docs to references/ and link to them. Keep SKILL.md focused on core instructions.

### Current State

| Has references/ | Count |
|-----------------|-------|
| Yes | 5 of 22 skills |
| No | 17 of 22 skills |

| Has templates/ | Count |
|----------------|-------|
| Yes | 6 of 22 skills |
| No | 16 of 22 skills |

| Has scripts/ | Count |
|--------------|-------|
| Yes | 0 of 22 skills |
| No | 22 of 22 skills |

Skills using progressive disclosure well: `qa` (references + templates), `skill-builder` (references + templates), `linear` (references), `linear-pm` (references).

Larger skills like `improve-issue` (222 lines), `analyze-project` (297 lines), and `debug-issue` (172 lines) have all content inline in SKILL.md with no references/ breakout.

---

## 6. Agent Consistency Issues

### Best Practice (Claude Code docs; QRSPI)

> Subagents should restrict tools to minimum needed. Filename should match name field. Use `tools` field in agent frontmatter.

### Current State

**Name/filename mismatch:** `github-project-manager.md` declares `name: pm`. The file is called `github-project-manager` but the agent is registered as `pm`.

**No tool restrictions (4 agents):**
- `devenv-docker-bash` — no tools field, inherits all
- `github-project-manager` — no tools field, inherits all
- `sitrep` — no tools field, inherits all
- `veteran-qa-engineer` — no tools field, inherits all

**Inconsistent frontmatter key:** Orchestrator agents (`ddd-architect`, `pm-architect`) use `allowed-tools`. All other agents use `tools`. These may be treated differently by the runtime.

**model: inherit:** `devenv-docker-bash` uses `model: inherit` instead of specifying a model explicitly.

---

## 7. Naming Convention Inconsistency

### Best Practice (Anthropic Skills Guide, p.10)

> Skill folders: kebab-case. No spaces, underscores, or capitals.

### Current State

**Skills:** All 22 correctly use kebab-case. No violations.

**Commands:** 9 of 14 use underscores (`create_handoff`, `founder_mode`, `linear_pm`, `oneshot_plan`, `ralph_impl`, `ralph_plan`, `ralph_research`, `resume_handoff`, `validate_plan`). Commands historically used underscores, but if they're being migrated to skills, the naming diverges.

**Agents:** All use kebab-case. One filename/name-field mismatch (`github-project-manager.md` → `name: pm`).

---

## 8. install.sh Sync Asymmetry

### Current State

```bash
rsync -av --delete "$REPO_DIR/skills/" "$CLAUDE_DIR/skills/"   # --delete
rsync -av "$REPO_DIR/commands/" "$CLAUDE_DIR/commands/"         # NO --delete
rsync -av --delete "$REPO_DIR/agents/" "$CLAUDE_DIR/agents/"   # --delete
```

Skills and agents use `--delete` (clean sync). Commands do NOT — removed commands persist in `~/.claude/commands/` after deletion from the repo. This means stale commands accumulate.

---

## 9. Deterministic Validation

### Best Practice (QRSPI, p.3-4)

> HumanLayer's `run_silent()` function swallows test/build output, returning ✓ on success. Use deterministic validation scripts over prose instructions. "Code is deterministic; language interpretation isn't."

### Best Practice (Anthropic Skills Guide, p.26)

> For critical validations, consider bundling a script that performs checks programmatically. Code is deterministic; language interpretation isn't.

### Current State

Zero skills use `scripts/`. All validation is prose-based ("verify that...", "check that...", "ensure that..."). The `implement-plan` skill has a `hooks: PostToolUse` block for lint-on-save, which is the closest approach to deterministic validation.

---

## 10. Context vs. Fork for Skills Using AskUserQuestion

### Known Constraint (MEMORY.md)

> AskUserQuestion is unavailable in subagents. Any skill that calls AskUserQuestion must NOT declare `context: fork`.

### Current State

All skills that list `AskUserQuestion` in `allowed-tools` (18 of 22) do NOT declare `context: fork`. This is correctly handled. The `analyze-project` skill has `disable-model-invocation: true` instead, which is a different mechanism. No violations found.

---

## Drift Summary

| Issue | Severity | Count | Source |
|-------|----------|-------|--------|
| Missing trigger phrases in descriptions | High | 15 of 22 skills | Anthropic Guide |
| Commands duplicating skills | High | 2 domains (linear, linear-pm) | Anthropic Guide |
| Nearly all skills on model: opus | Medium | 20 of 22 skills | QRSPI |
| linear.md exceeds 40-instruction limit | Medium | 45 directives | QRSPI |
| No scripts/ for deterministic validation | Medium | 0 of 22 skills | QRSPI + Guide |
| 22 skills loaded simultaneously | Medium | 22 | Anthropic Guide |
| Large SKILL.md without references/ breakout | Medium | 17 of 22 | Anthropic Guide |
| Agent tool restrictions missing | Low | 4 of 15 agents | Claude Code docs |
| Agent name/filename mismatch | Low | 1 agent | Claude Code docs |
| install.sh --delete asymmetry for commands | Low | 1 script | Repo hygiene |
| Agent frontmatter key inconsistency (tools vs allowed-tools) | Low | 2 agents | Consistency |

---

## Open Questions

1. Are the `ralph_*` commands still actively used, or are they legacy from HumanLayer's pattern that should be retired?
2. Should the DDD skill chain (7 skills) be consolidated, or does each step intentionally warrant its own skill?
3. Is there a strategy for selective skill enablement per project (e.g., DDD-heavy projects enable DDD skills, others don't)?
4. Should `commands/` be fully migrated to `skills/` and the commands directory deprecated?
