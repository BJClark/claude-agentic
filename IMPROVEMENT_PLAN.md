# Claude Code Features - Comprehensive Improvement Plan

## Executive Summary

This plan outlines improvements to leverage Claude Code's advanced features based on official documentation:

**Key Features to Leverage:**
- **Skill System**: Modern architecture with `context: fork`, hooks, supporting files, dynamic injection
- **Agent Teams**: Coordinated multi-agent work with shared task lists (experimental)
- **AskUserQuestion**: Structured decision points with predefined options
- **Hooks**: Automated quality gates (PreToolUse, PostToolUse, TaskCompleted, etc.)
- **Programmatic Execution**: CLI flags for headless operation (`-p`, `--output-format`)
- **Extended Thinking**: Deep reasoning with "ultrathink" keyword

**Expected Outcomes:**
- 25-30% token reduction through skill architecture
- Context isolation preventing main session pollution
- Automated quality gates with hooks
- Parallel work coordination with agent teams
- Better UX with structured questions vs free-form

---

## Current State Analysis

### Commands by Type

**Interactive Developer Commands** (need user guidance):
- `create_plan`, `iterate_plan`, `validate_plan` - Planning workflows
- `research_codebase`, `debug` - Investigation tasks
- `implement_plan`, `local_review` - Implementation & review
- `ddd_*` (8 commands) - Domain-Driven Design workflow
- `linear` - Project management integration

**Automated/Headless Commands** (can run autonomously):
- `ci_commit`, `commit` - Git operations
- `describe_pr` - PR documentation
- `create_worktree` - Git worktree management

**Hybrid Commands** (interactive setup, automated execution):
- `create_handoff`, `resume_handoff` - Async collaboration

### Current Architecture

```
commands/
├── create_plan.md          # 295 lines - planning
├── research_codebase.md    # 192 lines - research (✅ MIGRATED TO SKILL)
├── implement_plan.md       # 85 lines - implementation
├── ddd_full.md            # DDD orchestration
├── ddd_align.md           # DDD step 1
├── ... (19 more commands)
└── linear.md              # 388 lines - project mgmt

agents/
├── codebase-analyzer.md    # 79 lines
├── codebase-locator.md     # 86 lines
├── codebase-pattern-finder.md # 89 lines
└── ... (3 more agents)

skills/
└── research-codebase/      # ✅ NEW - first migration
    ├── SKILL.md            # 140 lines with context:fork
    └── templates/
        └── research-doc-template.md
```

---

## Feature 1: Skill System Migration

### Why Migrate Commands → Skills?

**Skills offer features commands don't:**

1. **`context: fork`** - Run in isolated subagent, prevent context pollution
2. **`agent: Explore|Plan|general-purpose`** - Choose execution environment
3. **`allowed-tools`** - Auto-approve specific tools, fewer permission prompts
4. **Supporting files** - Scripts, templates, reference docs alongside SKILL.md
5. **Dynamic context** - Inject shell command output with `!`command``
6. **Skill-scoped hooks** - Automatic quality gates
7. **`disable-model-invocation`** - Control when Claude can auto-invoke
8. **`argument-hint`** - Better autocomplete UX

### Skill Frontmatter Reference

```yaml
---
name: skill-name                    # Required: kebab-case identifier
description: "When to use this"    # Recommended: helps Claude decide
model: opus                        # Optional: override model
context: fork                      # Optional: run in subagent
agent: Explore                     # Optional: which subagent type
allowed-tools: Read, Grep, Glob    # Optional: auto-approve these
disable-model-invocation: false    # Optional: prevent auto-invoke
user-invocable: true              # Optional: show in / menu
argument-hint: [research-question] # Optional: autocomplete hint
hooks:                            # Optional: skill-scoped hooks
  PostToolUse:
    - matcher: "Write|Edit"
      hooks:
        - type: command
          command: "lint.sh"
---
```

### Migration Priority Matrix

| Command | Priority | Why | Benefit |
|---------|----------|-----|---------|
| `research_codebase` | ✅ **DONE** | Isolated exploration | Context clean, auto-approve |
| `implement_plan` | 🔥 **HIGH** | Hook integration | Automated verification |
| DDD commands (8) | 🔥 **HIGH** | Fork isolation | Prevent context bloat |
| `debug` | 🔥 **HIGH** | Supporting scripts | Debug tooling |
| `create_plan` | 📊 **MEDIUM** | Template support | Consistent plans |
| `describe_pr` | 📊 **MEDIUM** | PR templates | Standard descriptions |
| `commit` | ⬇️ **LOW** | Simple enough | Keep as command |

### Example Migration: research_codebase ✅ COMPLETED

**Before** (`commands/research_codebase.md`):
```markdown
---
description: Research codebase comprehensively using parallel sub-agents
model: opus
---

# Research Codebase
[192 lines of instructions...]
```

**After** (`skills/research-codebase/SKILL.md`):
```yaml
---
name: research-codebase
description: Research codebase by exploring components and patterns
model: opus
context: fork                              # ← Isolated execution
allowed-tools: Read, Grep, Glob, Bash(git *), TodoWrite  # ← Auto-approve
argument-hint: [research-question]         # ← Better UX
---

# Research: $ARGUMENTS                     # ← Use arguments

## Current Context
- Branch: !`git branch --show-current`    # ← Dynamic injection
- Last Commit: !`git log -1 --oneline`
- Modified Files: !`git status --short`

[Concise 140-line instructions...]

See [templates/research-doc-template.md](templates/research-doc-template.md)  # ← Supporting file
```

**Results:**
- ✅ 26% fewer tokens (192 → 140 lines)
- ✅ Context isolation (forked execution)
- ✅ Auto-approved tools (0 permission prompts)
- ✅ Dynamic context (shows git state)
- ✅ Template ensures consistency

---

## Feature 2: Agent Teams (Experimental)

### What Are Agent Teams?

Multiple Claude Code instances working together:
- **Lead**: Coordinates work, assigns tasks, synthesizes results
- **Teammates**: Work independently with own context windows
- **Shared Task List**: Pending → In Progress → Completed
- **Direct Messaging**: Teammates communicate with each other

### Enable Agent Teams

```bash
# In settings.json or environment
export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1
```

### When to Use Agent Teams

**✅ Good for:**
- Parallel code review (security + performance + tests)
- Multi-module implementation (each teammate owns files)
- Bug investigation with competing hypotheses
- Research with multiple perspectives
- DDD discovery (parallel exploration)

**❌ Not good for:**
- Sequential tasks with dependencies
- Same-file edits (conflicts)
- Simple tasks (coordination overhead)
- Cost-sensitive work (each teammate = full Claude instance)

### Commands That Should Support Teams

#### 1. **ddd_full** ⭐ PRIMARY CANDIDATE

**Why**: 7 sequential steps could be partially parallelized

**Team Structure:**
```
Lead: DDD Coordinator
├─ Teammate 1: Event Discovery (ddd_align + ddd_discover)
├─ Teammate 2: Domain Decomposition (ddd_decompose + ddd_strategize)
└─ Teammate 3: Context Mapping (ddd_connect + ddd_define)
```

**Benefits:**
- 3x faster for large PRDs
- Multiple perspectives simultaneously
- Better quality through parallel exploration

**Implementation:**
```markdown
## Agent Team Mode (Optional)

<invoke name="AskUserQuestion">
  questions: [{
    "question": "This is a complex DDD workflow. Use agent team for parallel work?",
    "header": "Execution Mode",
    "options": [
      {
        "label": "Agent Team (Recommended)",
        "description": "3 teammates work on different DDD steps in parallel. 3x faster."
      },
      {
        "label": "Single Session",
        "description": "Work through all 7 steps sequentially. Simpler but slower."
      }
    ]
  }]
</invoke>

If team selected, spawn 3 teammates and coordinate via shared task list.
```

#### 2. **research_codebase** ⭐ PRIMARY CANDIDATE

**Team Structure:**
```
Lead: Research Coordinator
├─ Teammate 1: codebase-locator (WHERE things are)
├─ Teammate 2: codebase-analyzer (HOW things work)
├─ Teammate 3: codebase-pattern-finder (EXAMPLES)
└─ Teammate 4: Documentation/tickets (Historical context)
```

**Benefits:**
- Faster comprehensive research
- More thorough coverage
- Different angles explored simultaneously

#### 3. **local_review**

**Team Structure:**
```
Lead: Review Coordinator
├─ Teammate 1: Security reviewer
├─ Teammate 2: Performance reviewer
└─ Teammate 3: Test coverage reviewer
```

**Benefits:**
- More thorough reviews
- Different expertise simultaneously
- Faster turnaround

#### 4. **debug**

**Team Structure:**
```
Lead: Debug Coordinator
├─ Teammate 1: Hypothesis A investigator
├─ Teammate 2: Hypothesis B investigator
├─ Teammate 3: Hypothesis C investigator
└─ [Teammates actively try to disprove each other]
```

**Benefits:**
- Faster root cause identification
- Less anchoring bias
- Competing hypotheses tested in parallel

### Team Coordination Patterns

**Task List Example:**
```
Shared Tasks (~/.claude/tasks/team-name/):
- [pending] Analyze authentication module
- [in_progress] Review payment flow (claimed by teammate-1)
- [completed] Document API structure
- [pending] Test error handling (depends on: completed task)
```

**Messaging:**
```bash
# From lead to teammate
"Focus on the security aspects of the auth module"

# Between teammates
"I found a pattern in auth.ts:45 that relates to your payment work"

# To lead
"Security review complete. Found 3 issues. See research doc."
```

**Quality Gates with Hooks:**
```yaml
hooks:
  TeammateIdle:
    - type: agent
      prompt: "Review work. If incomplete, provide feedback."
  TaskCompleted:
    - type: agent
      prompt: "Verify task complete. Reject if tests failing."
```

---

## Feature 3: AskUserQuestion - Structured Decisions

### Why Structured Questions?

**Old Way (Free-form):**
```
What changes would you like to make to the plan?
```
- Vague, open-ended
- User has to think of all options
- Inconsistent responses

**New Way (Structured):**
```yaml
<invoke name="AskUserQuestion">
  questions: [{
    "question": "Which implementation approach aligns with your goals?",
    "header": "Approach",
    "multiSelect": false,
    "options": [
      {
        "label": "JWT with Refresh Tokens",
        "description": "Stateless, scalable. Requires rotation logic."
      },
      {
        "label": "Session-based Auth",
        "description": "Simpler but less scalable."
      },
      {
        "label": "OAuth 2.0",
        "description": "Most secure. External dependency."
      }
    ]
  }]
</invoke>
```
- Clear options with tradeoffs
- Easy to decide
- Consistent responses

### Where to Add AskUserQuestion

#### **create_plan** - After research phase

```yaml
<invoke name="AskUserQuestion">
  questions: [
    {
      "question": "Which implementation approach aligns best with your goals?",
      "header": "Approach",
      "options": [
        {"label": "Option A", "description": "Pros/cons"},
        {"label": "Option B", "description": "Pros/cons"},
        {"label": "Option C", "description": "Pros/cons"}
      ]
    },
    {
      "question": "What priority level?",
      "header": "Priority",
      "options": [
        {"label": "Speed", "description": "Fast implementation, technical debt OK"},
        {"label": "Quality", "description": "Perfect code, takes longer"},
        {"label": "Simplicity", "description": "Minimal complexity"}
      ]
    }
  ]
</invoke>
```

#### **implement_plan** - Between phases

```yaml
<invoke name="AskUserQuestion">
  questions: [{
    "question": "Automated tests passed. Ready for next phase?",
    "header": "Phase Gate",
    "options": [
      {"label": "Proceed", "description": "Continue to Phase 2"},
      {"label": "Fix Issues", "description": "Address problems first"},
      {"label": "Review Changes", "description": "Manual review needed"}
    ]
  }]
</invoke>
```

#### **ddd_full** - Between each DDD step

```yaml
<invoke name="AskUserQuestion">
  questions: [{
    "question": "EventStorming complete. How to proceed?",
    "header": "Next Step",
    "options": [
      {"label": "Continue", "description": "Move to Decomposition"},
      {"label": "Refine Events", "description": "Improve current step"},
      {"label": "Export & Pause", "description": "Save progress, resume later"}
    ]
  }]
</invoke>
```

---

## Feature 4: Skill-Scoped Hooks

### What Are Hooks?

Automated event handlers that respond to tool use, task completion, etc.

**Available Hook Events:**
- `PreToolUse` - Before using any tool
- `PostToolUse` - After successful tool use
- `PostToolUseFailure` - After tool failure
- `TeammateIdle` - Teammate about to go idle (teams)
- `TaskCompleted` - Task being marked complete (teams)
- `PermissionRequest` - Permission dialog shown
- `SessionStart/End` - Session lifecycle

**Hook Action Types:**
- `command` - Execute shell script
- `prompt` - Quick LLM check
- `agent` - Full agentic verification with tools

### Example: implement_plan with Hooks

```yaml
---
name: implement-plan
description: Implement technical plans with automated verification
context: fork
allowed-tools: Read, Edit, Write, Bash
hooks:
  PostToolUse:
    - matcher: "Write|Edit"
      hooks:
        - type: command
          command: "${CLAUDE_PLUGIN_ROOT}/scripts/lint-on-save.sh"
  TaskCompleted:
    - type: agent
      prompt: |
        Verify phase completion:
        1. All tests pass: `make test`
        2. Linting passes: `make lint`
        3. No regressions

        If verification fails, exit with code 2 and explain what's wrong.
---
```

**Benefits:**
- Automatic linting after every file edit
- Automatic test verification after phase completion
- No manual "did you run the tests?" reminders
- Quality gates enforced automatically

### Hook Patterns by Command

**For code-writing commands** (`implement_plan`, `debug`):
```yaml
hooks:
  PostToolUse:
    - matcher: "Write|Edit"
      hooks:
        - type: command
          command: "lint-and-format.sh"
```

**For team coordination** (`ddd_full`, `research_codebase` with teams):
```yaml
hooks:
  TeammateIdle:
    - type: agent
      prompt: "Review teammate's work. Provide feedback if incomplete."
  TaskCompleted:
    - type: agent
      prompt: "Verify task complete. Reject if tests failing."
```

**For verification** (`validate_plan`, `local_review`):
```yaml
hooks:
  SessionEnd:
    - type: agent
      prompt: "Generate summary report of all findings"
```

---

## Feature 5: Extended Thinking ("ultrathink")

### What Is Extended Thinking?

Deep reasoning mode where Claude thinks longer before responding. Enabled by including "ultrathink" keyword anywhere in skill content.

### Which Commands Should Have ultrathink?

**High Value:**
- All DDD commands (domain reasoning)
- `create_plan` (technical architecture)
- `debug` (root cause analysis)
- `research_codebase` (understanding connections)

**Medium Value:**
- `validate_plan` (finding edge cases)
- `iterate_plan` (redesigning approach)

**Low Value:**
- `commit` (simple, straightforward)
- `describe_pr` (mostly mechanical)

### Implementation

Simply add "ultrathink" anywhere in the skill content:

```markdown
---
name: ddd-align
description: Deep domain alignment from PRD
---

# DDD Alignment

Ultrathink about the business domain before starting. Consider:
- Core business entities
- Domain boundaries
- Ubiquitous language
- Business invariants

[Rest of instructions...]
```

---

## Feature 6: Programmatic/Headless Execution

### CLI Flags for Automation

**Basic execution:**
```bash
claude -p "task description" --allowedTools "Read,Write,Bash"
```

**Structured output:**
```bash
claude -p "Summarize project" \
  --output-format json \
  --json-schema '{"type":"object","properties":{"summary":{"type":"string"}}}' \
  | jq '.structured_output.summary'
```

**Streaming:**
```bash
claude -p "Explain recursion" \
  --output-format stream-json \
  --include-partial-messages \
  | jq -rj 'select(.type=="stream_event") | .event.delta.text'
```

**Continue conversations:**
```bash
# Start conversation
session_id=$(claude -p "Start review" --output-format json | jq -r '.session_id')

# Continue it
claude -p "Focus on security" --resume "$session_id"
```

### Where to Add Programmatic Examples

Add to each command/skill:

```markdown
## Programmatic Usage

Run in CI/CD or scripts:

\```bash
# Basic
claude -p "/command-name arg" --output-format json

# With structured output
claude -p "/command-name" \
  --output-format json \
  --json-schema '{"type":"object","properties":{"result":{"type":"string"}}}'

# Stream output
claude -p "/command-name" \
  --output-format stream-json \
  | jq -rj 'select(.type=="stream_event") | .event.delta.text'
\```
```

**Best candidates:**
- `ci_commit` - Automated commits in CI
- `describe_pr` - PR descriptions in automation
- `validate_plan` - Plan validation in CI pipelines

---

## Implementation Roadmap

### Phase 1: Quick Wins (Week 1) 🔥

**✅ COMPLETED:**
1. Migrate `research_codebase` to skill with `context:fork, agent:Explore`
   - Result: 26% token reduction, context isolation, auto-approved tools

**COMPLETED:**
2. ✅ Migrate `implement_plan` to skill with `context:fork`, `allowed-tools`, `argument-hint`, dynamic context, AskUserQuestion phase gates
3. ✅ Add AskUserQuestion to `create_plan` (approach selection after research)
4. ✅ Add AskUserQuestion to `implement_plan` (phase gates between phases)
5. ✅ Add "ultrathink" to all 8 DDD commands (align, discover, decompose, strategize, connect, define, plan, full)

**Expected Impact:**
- 25-30% token reduction across migrated commands
- Zero permission prompts for allowed tools
- Automatic quality gates with hooks
- Better UX with structured questions

### Phase 2: Agent Teams (Week 2) 🚀

1. Add team mode option to `ddd_full`
2. Add team mode to `research_codebase`
3. Add team mode to `local_review`
4. Add team mode to `debug`

**Expected Impact:**
- 2-3x faster for complex research/review
- More thorough coverage
- Parallel exploration benefits

### Phase 3: Full Skill Migration (Weeks 3-4) 📦

1. Migrate all 8 DDD commands to skills/
2. Migrate `debug` with supporting scripts
3. Migrate `create_plan`, `iterate_plan` with templates
4. Migrate `describe_pr` with PR templates

**Expected Impact:**
- Consistent skill architecture
- Supporting files reduce duplication
- Template-driven consistency

### Phase 4: Advanced Features (Ongoing) ⚡

1. LSP integration for code intelligence (if applicable)
2. Custom MCP servers for project-specific tools
3. Advanced hook chains for quality gates
4. Team coordination patterns documentation

---

## Success Metrics

### Before Improvements
- ❌ Commands in `commands/`, simple markdown
- ❌ All execution in main context (accumulates)
- ❌ Manual tool approval (10-15 prompts per command)
- ❌ No parallel work coordination
- ❌ Free-form questions (vague, inconsistent)
- ❌ Limited CI/CD support
- ❌ No automatic quality gates

### After Improvements
- ✅ Skills in `skills/` with advanced features
- ✅ Strategic use of forked contexts (clean main session)
- ✅ Auto-approved tools (zero prompts)
- ✅ Agent teams for parallel exploration
- ✅ Structured decisions with AskUserQuestion
- ✅ Hooks for automatic verification
- ✅ First-class programmatic support
- ✅ Extended thinking for complex reasoning

### Key Performance Indicators

| Metric | Before | After | Target |
|--------|--------|-------|--------|
| Tokens per command | ~6,500 | ~4,800 | -26% |
| Permission prompts | 10-15 | 0 | 0 |
| Context pollution | High | Low | Isolated |
| Parallel work | None | Teams | 3-4 agents |
| Quality gates | Manual | Automated | Hooks |
| CI/CD support | Limited | Full | `-p` flag |

---

## Best Practices & Guidelines

### Skill Design
1. Keep SKILL.md under 200 lines - move details to supporting files
2. Use `context: fork` for heavy work that shouldn't pollute main session
3. Use `allowed-tools` to auto-approve trusted operations
4. Add `argument-hint` for better autocomplete UX
5. Include dynamic context with `!`command`` for situational awareness

### Agent Teams
1. Good for parallel exploration, bad for sequential work
2. Each teammate owns different files (avoid conflicts)
3. Use shared task list for coordination
4. Quality gates with TeammateIdle and TaskCompleted hooks
5. Monitor and steer - don't let teams run unattended too long

### AskUserQuestion
1. 1-4 questions max, 2-4 options each
2. Labels: short (1-5 words), descriptions: explain tradeoffs
3. Use multiSelect: false for exclusive choices
4. Header: 12 chars max, appears as chip/tag

### Hooks
1. Use `command` for fast checks (linting, formatting)
2. Use `prompt` for quick LLM validation
3. Use `agent` for complex verification with tools
4. Exit code 2 from hooks = reject action with feedback
5. Scope hooks to skills when possible (not global)

---

## Troubleshooting

### Skill Not Triggering
1. Check `description` matches user's natural language
2. Verify skill appears in `What skills are available?`
3. Try direct invocation: `/skill-name`
4. Check if `disable-model-invocation: true` is set

### Context Not Forking
1. Verify `context: fork` in frontmatter
2. Check session logs for "forking context"
3. Ensure skill (not command) is being invoked

### Tools Not Auto-Approved
1. Check `allowed-tools` syntax: `Read, Grep, Glob`
2. Use permission rule syntax: `Bash(git *)` for prefix matching
3. Space before `*` is important: `Bash(git *)` not `Bash(git*)`

### Agent Team Issues
1. Verify `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` is set
2. Check team mode: in-process (default) or tmux/iTerm2
3. Teammates not appearing: press Shift+Down to cycle
4. Orphaned tmux sessions: `tmux ls && tmux kill-session -t name`

### Dynamic Context Not Working
1. Verify backticks: `!`command`` not `!(command)`
2. Command must output to stdout
3. Test command manually first
4. Check command exists in PATH

---

## Next Steps

1. ✅ Validate `research_codebase` migration (see VALIDATION.md)
2. ✅ `implement_plan` migration to skill with phase gates
3. ✅ AskUserQuestion added to `create_plan`
4. ✅ "ultrathink" added to all 8 DDD commands
5. ✅ Phase 1 quick wins complete
6. 🚀 Prototype agent teams for `ddd_full` (Phase 2)
7. 📦 Complete Phase 3 full skill migration
8. 🎊 Measure and document improvements

---

## Questions to Answer

1. **Which commands do users run most often?** → Prioritize for skill migration
2. **Which commands take longest?** → Candidates for agent teams
3. **Which commands have quality issues?** → Add hooks
4. **Which commands need CI/CD?** → Add programmatic examples
5. **Which commands need deep reasoning?** → Add ultrathink

---

## Resources

- **Claude Code Docs**: https://code.claude.com/docs
- **Skill System**: Extend Claude with skills
- **Agent Teams**: Orchestrate teams of Claude Code sessions
- **Programmatic Usage**: Run Claude Code programmatically
- **Plugins Reference**: Complete technical reference

---

**Last Updated**: 2026-02-07
**Status**: Phase 1 Complete ✅ — Ready for Phase 2 (Agent Teams)
