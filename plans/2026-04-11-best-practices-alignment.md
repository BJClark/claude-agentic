# Best Practices Alignment Implementation Plan

## Overview

Align the 22 skills, 15 agents, and 14 commands in this repo with best practices from QRSPI (HumanLayer), Anthropic's Complete Guide to Building Skills, and Claude Code's official documentation. The audit at `research/2026-04-11-best-practices-audit.md` identified 9 drifts across high/medium/low severity. This plan addresses all 9 in 4 phases, ordered to reduce context pressure first (deduplication), then improve quality (triggers + models), then restructure for progressive disclosure, then clean up agents.

## Current State Analysis

- **51 prompt artifacts** (22 skills + 14 commands + 15 agents) loaded into every session
- **15/22 skills** missing trigger phrases — Claude can't auto-invoke them
- **2 domains** (linear, linear-pm) duplicated across skills AND commands with conflicting instructions
- **20/22 skills** on `model: opus` when most are execution tasks suited for sonnet
- **17/22 skills** have no `references/` directory — large bodies inline
- **0/22 skills** use `scripts/` for deterministic validation
- **4/15 agents** have no tool restrictions
- `install.sh` doesn't `--delete` for commands, causing stale accumulation

### Key Discoveries:
- `commands/linear.md` (391 lines) references deprecated `mcp__linear__` tool names; `skills/linear/SKILL.md` (149 lines) uses the correct `mcp__mise-tools__linear_{ws}_*` namespace
- `commands/linear_pm.md` (293 lines) is a verbose version of `skills/linear-pm/SKILL.md` (208 lines) with no unique functional content
- Unique content worth preserving from commands: comment quality guidelines, example transformations (verbose thoughts → concise ticket)
- `oneshot.md` and `oneshot_plan.md` depend on `ralph_*` commands — must be deleted together
- `commands/ddd.md`, `commands/pm.md`, `commands/commit.md`, `commands/create_handoff.md`, `commands/resume_handoff.md`, `commands/validate_plan.md`, `commands/founder_mode.md` are independent commands not duplicating skills
- Agent frontmatter uses `tools` (11 agents) vs `allowed-tools` (2 orchestrators) — the runtime treats these differently

## Desired End State

- All 22 skills have trigger phrases in descriptions enabling auto-invocation
- No duplicate coverage between skills and commands for the same domain
- Execution skills run on sonnet, orchestration skills on opus
- Large skills use progressive disclosure via `references/`
- `implement-plan` has a `scripts/verify.sh` exemplar for deterministic validation
- All agents have explicit tool restrictions and consistent frontmatter
- `install.sh` cleanly syncs all three directories with `--delete`
- 7 stale/duplicate commands removed, net reduction of ~1,200 lines from system prompt

## Technical Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Duplicate commands | Merge unique content into skills, then delete commands | Skills are the modern format with frontmatter, model selection, and progressive disclosure. Commands lack these. |
| ralph_* commands | Delete along with oneshot/oneshot_plan | User confirmed these are legacy HumanLayer patterns no longer in use |
| Model for DDD skills | sonnet | DDD steps are scoped analysis tasks following a predefined template — no orchestration needed |
| Model for describe-pr | sonnet | Scoped generation task — reads diff, writes PR description |
| Model for debug-issue | opus (keep) | Requires broad reasoning across logs, git history, and database — orchestration-level complexity |
| Model for create-plan, implement-plan, skill-builder | opus (keep) | These are orchestration skills that spawn subagents and make multi-step decisions |
| Agent frontmatter key | Standardize on `tools` | `tools` is the documented key in Claude Code agent docs. `allowed-tools` is the skill-level key. |
| github-project-manager filename | Keep filename, fix name field | Changing `name: pm` to `name: github-project-manager` avoids confusion with the `pm` command |
| Command content to preserve | Move to `skills/linear/references/quality-guidelines.md` | Comment quality guidelines and example transformations are useful reference material |

## What We're NOT Doing

- Consolidating the 7 DDD skills into fewer skills (each step is intentionally separate for the DDD workflow)
- Selective skill enablement per project (future optimization, requires Claude Code config changes)
- Adding scripts/ to all 22 skills (one exemplar in implement-plan; expand later based on results)
- Migrating remaining 7 commands to skills (they serve different purposes and aren't duplicating)
- Changing skill body content beyond what's needed for progressive disclosure

## Implementation Approach

Four phases, each independently shippable. Phase 1 reduces context pressure by removing duplicates. Phase 2 improves skill discoverability and cost. Phase 3 restructures for progressive disclosure. Phase 4 cleans up agent inconsistencies. Each phase ends with `scripts/install.sh` and spot-checking that skills/agents load correctly.

---

## Phase 1: Deduplication & Cleanup

### Overview
Remove duplicate commands, delete legacy ralph_* workflow, merge unique content into skills, and fix install.sh. Net removal of 7 commands (~1,200 lines from system prompt).

### Changes Required:

#### 1. Extract unique content from commands before deletion
**File**: `skills/linear/references/quality-guidelines.md` (new)
**Changes**: Create reference doc with comment quality guidelines and example transformations from `commands/linear.md` lines 179-203 and 337-352.

```markdown
# Linear Quality Guidelines

## Comment Quality
When creating comments, focus on the most valuable information for a human reader:
- Key insights over summaries: What's the "aha" moment?
- Decisions and tradeoffs: What approach was chosen and what it enables/prevents
- Blockers resolved: What was preventing progress and how it was addressed
- State changes: What's different now and what it means for next steps
- Surprises or discoveries: Unexpected findings that affect the work

Avoid:
- Mechanical lists of changes without context
- Restating what's obvious from code diffs
- Generic summaries that don't add value

## Example: Thoughts Document → Ticket

### From verbose thoughts:
"I've been thinking about how our resumed sessions don't inherit permissions properly.
This is causing issues where users have to re-specify everything..."

### To concise ticket:
Title: Fix resumed sessions to inherit all configuration from parent

Description:
## Problem to solve
Currently, resumed sessions only inherit Model and WorkingDir from parent sessions,
causing all other configuration to be lost.

## Solution
Store all session configuration in the database and automatically inherit it when
resuming sessions, with support for explicit overrides.
```

#### 2. Add reference link to linear skill
**File**: `skills/linear/SKILL.md`
**Changes**: Add link to quality guidelines in the Guidelines section.

Add after existing guideline 7:
```markdown
8. **Comment quality**: See [references/quality-guidelines.md](references/quality-guidelines.md) for comment and ticket writing standards
```

#### 3. Delete duplicate commands
**Files to delete**:
- `commands/linear.md` (391 lines — duplicates `skills/linear/`)
- `commands/linear_pm.md` (293 lines — duplicates `skills/linear-pm/`)

#### 4. Delete legacy ralph_* workflow
**Files to delete**:
- `commands/ralph_impl.md`
- `commands/ralph_plan.md`
- `commands/ralph_research.md`
- `commands/oneshot.md` (depends on ralph_research)
- `commands/oneshot_plan.md` (depends on ralph_plan + ralph_impl)

#### 5. Fix install.sh sync asymmetry
**File**: `scripts/install.sh`
**Changes**: Add `--delete` flag to commands rsync.

```bash
# Before:
rsync -av "$REPO_DIR/commands/" "$CLAUDE_DIR/commands/"

# After:
rsync -av --delete "$REPO_DIR/commands/" "$CLAUDE_DIR/commands/"
```

### Success Criteria:

#### Automated Verification:
- [x] `ls commands/` shows exactly 7 files: `commit.md`, `create_handoff.md`, `resume_handoff.md`, `validate_plan.md`, `founder_mode.md`, `ddd.md`, `pm.md`
- [x] `grep -r "ralph" commands/` returns no results
- [x] `grep -r "oneshot" commands/` returns no results
- [x] `cat scripts/install.sh | grep "commands" | grep -- "--delete"` confirms the flag is present
- [x] `skills/linear/references/quality-guidelines.md` exists
- [x] `scripts/install.sh` runs without errors

#### Manual Verification:
- [ ] Start a new Claude Code session and invoke `/linear` — skill loads correctly
- [ ] Start a new Claude Code session and invoke `/linear-pm` — skill loads correctly
- [ ] Verify no stale commands appear in session's skill list

**Implementation Note**: After automated verification passes, pause for manual confirmation before next phase.

---

## Phase 2: Skill Quality — Trigger Phrases & Model Selection

### Overview
Add "Use when..." trigger phrases to 15 skills and downgrade 12 execution-focused skills from opus to sonnet.

### Changes Required:

#### 1. Add trigger phrases to skill descriptions

Update the `description` field in YAML frontmatter for each skill. The format is: `[What it does]. Use when [trigger condition].`

| Skill | New Description |
|-------|----------------|
| `analyze-project` | `Analyze a Linear project's stories for completeness and gaps, improve them, and prepare all cards for research. Use when you have a Linear project and want to audit story quality and move cards to Ready for Research.` |
| `create-plan` | `Create detailed implementation plans through interactive research and iteration. Optionally syncs plan to Linear tickets with phase sub-issues. Use when you need to create a new implementation plan for a ticket or feature.` |
| `ddd-connect` | `DDD Step 5: Context Mapping — define relationships between bounded contexts. Use when you have defined bounded contexts and need to map relationships and integration patterns between them.` |
| `ddd-decompose` | `DDD Step 3: Decompose the domain into sub-domains and bounded contexts. Use when you have an event catalog and need to identify bounded context boundaries.` |
| `ddd-define` | `DDD Step 7: Define bounded context canvases and aggregate design canvases. Use when you have finalized bounded contexts and need to produce formal BC and Aggregate canvases.` |
| `ddd-discover` | `DDD Step 2: EventStorming — discover domain events, commands, actors, and policies. Use when you have a PRD or requirements and need to extract domain building blocks via EventStorming.` |
| `ddd-plan` | `DDD Step 8: Convert DDD artifacts into implementation plans for /implement-plan. Use when DDD artifacts are complete and you need to translate them into phased implementation plans.` |
| `ddd-strategize` | `DDD Step 4: Strategize — classify sub-domains and make investment decisions. Use when you have identified sub-domains and need to classify them on a Core Domain Chart.` |
| `debug-issue` | `Debug issues by investigating logs, database state, and git history. Use when something is broken and you need to investigate the cause without editing files.` |
| `describe-pr` | `Generate comprehensive PR descriptions following repository templates. Use when you have an open PR or branch and need a well-structured description from the diff and commit history.` |
| `implement-plan` | `Implement technical plans from thoughts/shared/plans with automated verification and phase gates. Use when you have an approved plan file and are ready to execute it phase by phase.` |
| `improve-issue` | `Enrich a ticket with clarifications and context so an engineer can start planning. Use when a Linear or GitHub ticket is too vague and needs acceptance criteria and technical context.` |
| `iterate-plan` | `Iterate on existing implementation plans with thorough research and updates. Use when you have an existing plan and want to revise it based on feedback or new findings.` |
| `local-review` | `Set up worktree for reviewing colleague's branch with optional parallel review team. Use when you need to review a colleague's branch in an isolated git worktree.` |
| `research-codebase` | `Research codebase comprehensively by exploring components, patterns, and connections. Document what exists without evaluation. Use when you need a factual deep dive into how a specific part of the codebase works.` |

**File**: Each skill's `SKILL.md` — update only the `description:` line in frontmatter.

#### 2. Downgrade execution skills to model: sonnet

Update the `model` field in YAML frontmatter for these 12 skills:

| Skill | Current | New | Rationale |
|-------|---------|-----|-----------|
| `analyze-project` | opus | sonnet | Scoped analysis of Linear project cards |
| `ddd-connect` | opus | sonnet | Template-driven DDD step |
| `ddd-decompose` | opus | sonnet | Template-driven DDD step |
| `ddd-define` | opus | sonnet | Template-driven DDD step |
| `ddd-discover` | opus | sonnet | Template-driven DDD step |
| `ddd-plan` | opus | sonnet | Template-driven DDD step |
| `ddd-strategize` | opus | sonnet | Template-driven DDD step |
| `describe-pr` | (unset) | sonnet | Scoped generation from diff |
| `improve-issue` | opus | sonnet | Scoped ticket enrichment |
| `iterate-plan` | opus | sonnet | Iterating on existing plan, not creating from scratch |
| `linear` | opus | sonnet | Scoped ticket CRUD with references/ for context |
| `linear-pm` | opus | sonnet | Scoped PM CRUD with references/ for context |

**Keep on opus** (8 skills): `create-plan`, `debug-issue`, `implement-plan`, `local-review`, `pm-synthesize`, `qa`, `research-codebase`, `skill-builder`

**File**: Each skill's `SKILL.md` — update only the `model:` line in frontmatter.

### Success Criteria:

#### Automated Verification:
- [x] `grep -l "Use when" skills/*/SKILL.md | wc -l` returns 22 (all skills have triggers)
- [x] `grep "model: opus" skills/*/SKILL.md | wc -l` returns 8
- [x] `grep "model: sonnet" skills/*/SKILL.md | wc -l` returns 14 (12 new + linear-ticket-status-sync + describe-pr)
- [x] No skill has `model:` field missing: `for f in skills/*/SKILL.md; do grep -L "^model:" "$f"; done` returns nothing

#### Manual Verification:
- [ ] Start a new session and say "I need to create a plan for a ticket" — verify `create-plan` auto-triggers
- [ ] Start a new session and say "This ticket is too vague" — verify `improve-issue` auto-triggers
- [ ] Invoke `/ddd-discover` — verify it runs on sonnet (check model in output if visible)

**Implementation Note**: After automated verification passes, pause for manual confirmation before next phase.

---

## Phase 3: Progressive Disclosure & Validation Scripts

### Overview
Extract inline content from large skills into `references/` directories. Create a `scripts/verify.sh` exemplar for `implement-plan`. This reduces SKILL.md body sizes and establishes the scripts/ pattern.

### Changes Required:

#### 1. Extract references for improve-issue (222 lines)
**File**: `skills/improve-issue/SKILL.md`
**New file**: `skills/improve-issue/references/enrichment-checklist.md`
**Changes**: Move the detailed enrichment checklist, example questions, and acceptance criteria templates from SKILL.md body into a reference doc. Replace with a link: `See [references/enrichment-checklist.md](references/enrichment-checklist.md) for the detailed checklist.`

#### 2. Extract references for analyze-project (297 lines)
**File**: `skills/analyze-project/SKILL.md`
**New file**: `skills/analyze-project/references/analysis-criteria.md`
**Changes**: Move detailed analysis criteria, scoring rubrics, and example outputs into a reference doc. Replace with a link in SKILL.md.

#### 3. Extract references for debug-issue (172 lines)
**File**: `skills/debug-issue/SKILL.md`
**New file**: `skills/debug-issue/references/investigation-playbook.md`
**Changes**: Move investigation patterns and diagnostic commands into a reference doc.

#### 4. Create implement-plan validation script exemplar
**File**: `skills/implement-plan/scripts/verify.sh` (new)
**Changes**: Create a bash script that runs deterministic checks after each phase:

```bash
#!/usr/bin/env bash
# verify.sh — Deterministic post-phase validation for implement-plan
# Usage: scripts/verify.sh [phase-number]
set -euo pipefail

phase="${1:-all}"
errors=0

check() {
  local desc="$1"; shift
  if "$@" > /dev/null 2>&1; then
    echo "✓ $desc"
  else
    echo "✗ $desc"
    ((errors++))
  fi
}

# Universal checks (every phase)
echo "=== Universal checks ==="
check "TypeScript compiles"    npx tsc --noEmit 2>/dev/null || check "TypeScript compiles" echo "SKIP: no tsconfig.json"
check "Linting passes"         npm run lint 2>/dev/null || check "Linting passes" echo "SKIP: no lint script"
check "Tests pass"             npm test 2>/dev/null || check "Tests pass" echo "SKIP: no test script"
check "No uncommitted changes" git diff --quiet

echo ""
if [ "$errors" -gt 0 ]; then
  echo "FAILED: $errors check(s) failed"
  exit 1
else
  echo "PASSED: All checks passed"
  exit 0
fi
```

#### 5. Reference the script from implement-plan SKILL.md
**File**: `skills/implement-plan/SKILL.md`
**Changes**: Add to the phase gate section:

```markdown
After each phase, run deterministic verification:
`bash skills/implement-plan/scripts/verify.sh [phase-number]`
```

### Success Criteria:

#### Automated Verification:
- [x] `wc -l skills/improve-issue/SKILL.md` is under 150 lines (down from 222)
- [x] `wc -l skills/analyze-project/SKILL.md` is under 200 lines (down from 297)
- [x] `wc -l skills/debug-issue/SKILL.md` is under 120 lines (down from 172)
- [x] `test -x skills/implement-plan/scripts/verify.sh` confirms script is executable
- [x] `ls skills/improve-issue/references/ skills/analyze-project/references/ skills/debug-issue/references/` all succeed

#### Manual Verification:
- [ ] Invoke `/improve-issue` on a vague ticket — verify it still references the enrichment checklist
- [ ] Invoke `/implement-plan` on a test plan — verify it runs verify.sh between phases
- [ ] Verify extracted reference content is complete (no information lost)

**Implementation Note**: After automated verification passes, pause for manual confirmation before next phase.

---

## Phase 4: Agent Hygiene

### Overview
Fix agent name/filename mismatch, add tool restrictions to 4 unrestricted agents, and normalize frontmatter key from `allowed-tools` to `tools` on orchestrator agents.

### Changes Required:

#### 1. Fix github-project-manager name field
**File**: `agents/github-project-manager.md`
**Changes**: Change `name: pm` to `name: github-project-manager`

#### 2. Add tool restrictions to unrestricted agents

**File**: `agents/devenv-docker-bash.md`
**Changes**: Add `tools:` field. This agent writes Docker configs and bash scripts.
```yaml
tools: Read, Write, Edit, Grep, Glob, LS, Bash
model: sonnet  # change from inherit to explicit
```

**File**: `agents/github-project-manager.md`
**Changes**: Add `tools:` field. This agent manages GitHub PRs/issues.
```yaml
tools: Read, Grep, Glob, LS, Bash
```

**File**: `agents/sitrep.md`
**Changes**: Add `tools:` field. This agent reports situation status.
```yaml
tools: Read, Grep, Glob, LS, Bash
```

**File**: `agents/veteran-qa-engineer.md`
**Changes**: Add `tools:` field. This agent runs tests and validates.
```yaml
tools: Read, Grep, Glob, LS, Bash, Write, Edit
```

#### 3. Normalize orchestrator agent frontmatter key
**File**: `agents/ddd-architect.md`
**Changes**: Rename `allowed-tools:` to `tools:` (keep same value)

**File**: `agents/pm-architect.md`
**Changes**: Rename `allowed-tools:` to `tools:` (keep same value)

### Success Criteria:

#### Automated Verification:
- [x] `grep "name: github-project-manager" agents/github-project-manager.md` matches
- [x] `grep -L "^tools:" agents/*.md` returns no files (all agents have tools field)
- [x] `grep "allowed-tools" agents/*.md` returns no matches (key normalized)
- [x] `grep "model: inherit" agents/*.md` returns no matches

#### Manual Verification:
- [ ] Invoke an agent that was previously unrestricted (e.g., sitrep) — verify it still works with restricted tools
- [ ] Invoke `/ddd` which uses ddd-architect — verify it still spawns correctly with `tools:` key

**Implementation Note**: After automated verification passes, run `scripts/install.sh` to sync all changes to `~/.claude/`.

---

## Testing Strategy

### Per-Phase Verification:
Each phase has its own automated + manual verification criteria above. Run `scripts/install.sh` after each phase.

### End-to-End:
After all 4 phases:
1. Start a fresh Claude Code session
2. Verify skill count in system prompt hasn't changed (22 skills, but commands reduced from 14 to 7)
3. Test auto-triggering: say "this ticket needs more detail" — should invoke `improve-issue`
4. Test DDD workflow: `/ddd` → verify it runs on sonnet for steps, opus for orchestration
5. Test linear: `/linear` → verify workspace selection and ticket creation still work
6. Verify `~/.claude/commands/` has exactly 7 files (stale commands cleaned by --delete)

### Rollback:
All changes are in version-controlled files. `git revert` on any phase's commit restores the previous state.

## Migration Notes

- After Phase 1, users who invoke `/ralph_research`, `/ralph_plan`, `/ralph_impl`, `/oneshot`, or `/oneshot_plan` will get "skill not found". These are confirmed legacy and unused.
- After Phase 1, `~/.claude/commands/` will be cleaned on next `install.sh` run — any manually-added commands there will be deleted by `--delete`. Verify no manually-created commands exist in `~/.claude/commands/` before running.
- The `pm` command (`commands/pm.md`) is NOT being deleted — it orchestrates the PM workspace build workflow and doesn't duplicate a skill.

## References
- Audit: `research/2026-04-11-best-practices-audit.md`
- Anthropic Skills Guide: `The-Complete-Guide-to-Building-Skill-for-Claude-3.pdf`
- QRSPI: Referenced in audit (HumanLayer's QRSPI pipeline document)
- Claude Code subagent docs: https://code.claude.com/docs/en/agent-sdk/subagents
