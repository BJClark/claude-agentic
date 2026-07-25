---
date: 2026-05-30
branch: main
base_commit: ad4e5a0
repository: claude-agentic
status: draft
title: Model-tiering + role taxonomy + QRSPI orchestration refactor
---

# Model-tiering + Role Taxonomy + QRSPI Orchestration Refactor

## Goal

Make the repo support the operating model: **Sonnet (or Haiku) as the cheap main loop, the right model per *role* inside subagents, an orchestrator that drives a ticket through QRSPI, and a clean skills↔agents grammar.** The architecture is already ~70% there (`implement-plan` → `plan-implementer` is the exemplar; `babysit-pr` already delegates all edits). This plan corrects the inverted model tiers, reorganizes the agent roster around a **role taxonomy**, builds the missing QRSPI connective tissue, and retires the legacy commands.

## Governing mechanic (why these changes work)

- **Inline skill `model:`** temporarily promotes the *whole main loop* for that turn, then reverts. Good for interactive hard-reasoning skills; bad for batch work (bloats main context).
- **Forked skill (`context: fork`) `model:`** runs in an isolated subagent on that model; main loop keeps its own model; only a summary returns.
- **Agent (`agents/*.md`) `model:`** is independent of the main loop.
- **`AskUserQuestion` does not exist in any subagent** (forked skill or Task agent). → Interactive gates must stay inline. This is the binding constraint on the whole design.
- **A role spans two surfaces.** An interactive role (Architect, PM) lives as an *inline skill-persona* (so its gates work); a delegated role (Developer, Researcher, Scout) lives as a *subagent*. QA spans both (subagent + reviewer persona in `critique`).
- **Unattended orchestrators stay Opus.** The "cheap orchestrator" rule only holds for *interactive* orchestrators, where human gates catch a bad call. An orchestrator running in auto mode (cron / headless, no human present — e.g. `babysit-pr`) must be Opus: its autonomous routing, escalation, and anti-loop judgment has nothing to catch a mistake. Tier orchestrators by how much judgment they exercise *without* a gate.
- No `CLAUDE_CODE_SUBAGENT_MODEL` override is set, so per-agent `model:` frontmatter is honored.

## Decisions (locked 2026-05-30)

- **Role set**: 6 roles — Developer, Architect, Product Manager, QA/Reviewer, Researcher, Scout.
- **Naming**: job titles (`developer`, `architect`, `product-manager`, `qa-engineer`, `researcher`, `scout`). Renames touch every skill that references an agent.
- **Model tiers (tier-by-role, supersedes earlier "all agents → Opus")**: Developer / Architect / PM / QA → Opus; Researcher → Sonnet; Scout → Haiku.
- **Consolidation**: moderate — merge the generic read/search agents into Researcher + Scout; keep DDD discovery agents as named Architect-family specialists.
- **Role surface**: Architect & PM are inline skill-personas; spawn an `architect` subagent only for batch *design-it-twice*. No standing PM agent.
- **Persona framing**: yes — each role body opens with a one-line "You are a senior X" then the precise contract.
- **Glossary**: yes — `references/ROLES.md` is the single source of truth for the taxonomy.
- **Contract invariant**: every role keeps a sharp invocation contract (like `plan-implementer`'s "implement phase N, verify, return <400-word report"). Role frames; contract does the work.

## Role taxonomy (target state)

| Role | Surface | Model | Tools (scope) | Embodied by | Contract |
|---|---|---|---|---|---|
| **developer** | subagent (always) | opus | Read, Edit, Write, Grep, Glob, Bash, TodoWrite | `plan-implementer` → rename | implement a plan phase / apply a scoped fix; verify; return <400-word report |
| **architect** | inline persona (`tech-spec`, `improve-codebase-architecture`, `create-plan`) + subagent for batch design-it-twice | opus | inline: skill tools / batch agent: Read, Grep, Glob, Write | persona text in those skills; new `agents/architect.md` (batch only) | inline: design interfaces/boundaries with the user. batch: produce one alternative interface under a stated constraint |
| **product-manager** | inline persona only | opus | skill tools | persona in `pm-synthesize` + new `/pm` skill | synthesize story map + DDD into a build plan |
| **qa-engineer** | subagent + reviewer persona in `critique` | opus | Read, Grep, Glob, LS, Bash, Write, Edit | `veteran-qa-engineer` → rename; `critique` carries the reviewer persona | test through execution / review against checklist; return findings; no scope creep |
| **researcher** | subagent | sonnet | Read, Grep, Glob, LS, WebSearch, WebFetch, TodoWrite | merge `codebase-analyzer` + `codebase-pattern-finder` + `artifacts-analyzer` + `web-search-researcher` | investigate code / prior artifacts / web; document findings; never edit |
| **scout** | subagent | haiku | Grep, Glob, LS | merge `codebase-locator` + `artifacts-locator` | locate files/dirs/symbols; return paths + line numbers only |

**Architect-family specialists** (kept by name, opus, invoked by the DDD step-skills): `ddd-event-discoverer`, `ddd-context-analyzer`, `ddd-canvas-builder`.

### agents/ before → after (13 → 8)

| After | From |
|---|---|
| `developer.md` (opus) | rename of `plan-implementer.md` |
| `architect.md` (opus) | new — batch design-it-twice worker only |
| `qa-engineer.md` (opus) | rename of `veteran-qa-engineer.md` |
| `researcher.md` (sonnet) | merge of `codebase-analyzer` + `codebase-pattern-finder` + `artifacts-analyzer` + `web-search-researcher` |
| `scout.md` (haiku) | merge of `codebase-locator` + `artifacts-locator` |
| `ddd-event-discoverer.md` (opus) | retier only |
| `ddd-context-analyzer.md` (opus) | retier only |
| `ddd-canvas-builder.md` (opus) | retier only |

**Retired files**: `plan-implementer`, `veteran-qa-engineer`, `codebase-analyzer`, `codebase-locator`, `codebase-pattern-finder`, `artifacts-analyzer`, `artifacts-locator`, `web-search-researcher`, `ddd-architect`, `pm-architect`.

---

## Phase 1 — Cheap skill flip (independent, do first)

- [x] `skills/critique/SKILL.md`: add `context: fork` (keep `model: opus`). It writes an artifact and uses no `AskUserQuestion`, so forking keeps the big review out of main context. Document the caveat: a forked critique only sees its argument, not conversation history — callers pass the target explicitly (path / PR / branch / draft). `tech-spec` already does.

> **`babysit-pr` stays Opus** (do NOT flip it). It runs unattended in auto mode — cron-driven cycles via `/goal` + `CronCreate`, no human gate — so its routing/escalation/anti-loop judgment must be on the strong model. It already delegates edits to the Opus `developer`; the orchestrator itself is the autonomous decision-maker, which is exactly what needs Opus. This corrects the earlier "babysit-pr → sonnet" idea: that only made sense if it were interactive.

### Automated verification
- [x] `grep -n 'context: fork' skills/critique/SKILL.md` matches.
- [x] `grep '^model:' skills/babysit-pr/SKILL.md` still shows `opus`.

---

## Phase 2 — Role taxonomy (the roster pass)

Foundational — Phases 3 and 4 reference role names.

### 2a. Glossary
- [x] Write `references/ROLES.md`: for each of the 6 roles — purpose, surface(s), model tier, tool scope, embodying skills/agents, and the invocation contract. State the contract-invariant and the role-surface rule. This is the ubiquitous-language for the agent team; agents/skills link to it.

### 2b. Consolidate + rename + retier agents
- [x] Create `agents/developer.md` from `plan-implementer.md` (model `opus`; persona line + existing contract verbatim). Delete `plan-implementer.md`.
- [x] Create `agents/qa-engineer.md` from `veteran-qa-engineer.md` (opus; persona + contract). Delete original.
- [x] Create `agents/researcher.md` (sonnet) merging the four readers' contracts into one body with explicit modes (code / prior-artifacts / web), tools `Read, Grep, Glob, LS, WebSearch, WebFetch, TodoWrite`. Delete the four source files.
- [x] Create `agents/scout.md` (haiku) merging the two locators; tools `Grep, Glob, LS`; contract returns paths + line numbers only. Delete the two source files.
- [x] Create `agents/architect.md` (opus) as the batch design-it-twice worker (one alternative interface under a stated constraint). Tools `Read, Grep, Glob, Write`.
- [x] Retier the DDD specialists to `model: opus`: `ddd-event-discoverer`, `ddd-context-analyzer`, `ddd-canvas-builder`. Add the architect-family persona line to each.
- [x] Delete `ddd-architect.md` and `pm-architect.md` (their orchestration moves inline in Phase 3).

### 2c. Add persona framing
- [x] Each surviving agent body opens with one line — e.g. "You are a senior developer." / "You are a staff-level code reviewer." — immediately followed by the existing sharp contract. No tone drift, no padding.
- [x] Add the matching persona line to the inline Architect/PM/Reviewer skills: `tech-spec`, `improve-codebase-architecture`, `create-plan` (architect), `pm-synthesize` (PM), `critique` (reviewer).

### 2d. Update all references (the churn)
- [x] For each retired name, grep `skills/`, `agents/`, `commands/`, `README.md` and update every `subagent_type` / Task / prose reference to the new role name:
  - `plan-implementer` → `developer`
  - `veteran-qa-engineer` → `qa-engineer`
  - `codebase-locator`, `artifacts-locator` → `scout`
  - `codebase-analyzer`, `codebase-pattern-finder`, `artifacts-analyzer`, `web-search-researcher` → `researcher`
  - `ddd-architect`, `pm-architect` → (removed; see Phase 3)
- [x] `Explore` subagent spawns in `improve-codebase-architecture` / `grill-me` are the built-in `Explore` type — leave unchanged.

### Automated verification
- [x] `ls agents/` shows exactly the 8 target files.
- [x] `grep -rEn 'plan-implementer|veteran-qa-engineer|codebase-(locator|analyzer|pattern-finder)|artifacts-(locator|analyzer)|web-search-researcher|ddd-architect|pm-architect' skills/ agents/ commands/ README.md` returns nothing.
- [x] Every `agents/*.md` has a `model:` matching the tier table (developer/architect/qa-engineer + 3 DDD = opus; researcher = sonnet; scout = haiku).
- [x] `references/ROLES.md` exists and lists all 6 roles.
- [x] `scripts/install.sh` runs clean.

---

## Phase 3 — Commands → skills + DDD/PM gate fix

Convert the 4 commands to skills; rebuild `/ddd` and `/pm` inline so their gates fire (this is *where* the retired architect agents' orchestration goes).

### 3a. Verify the gate bug
- [x] Confirm `/ddd` and `/pm` (commands) spawned `ddd-architect` / `pm-architect` as Task subagents while those agents declared `AskUserQuestion` — meaning the "confirmation gates between steps" silently degraded. Record in implementation notes.

### 3b. Simple conversions
- [x] `commands/commit.md` → `skills/commit/SKILL.md` (`model: sonnet`, `disable-model-invocation: true` for manual-only). Preserve "NEVER add Claude attribution." **Flag**: conflicts with the global instruction to append `Co-Authored-By: Claude` — surface for the user to resolve per-repo.
- [x] `commands/validate_plan.md` → `skills/validate-plan/SKILL.md` (`model: sonnet`). Delegate the heavy verification (`make check test`, parallel research) to the `qa-engineer` subagent; only the report surfaces inline.

### 3c. Rebuild `/ddd` as an inline orchestrator skill
- [x] `commands/ddd.md` → `skills/ddd/SKILL.md` (`model: sonnet`, inline — needs AskUserQuestion). Sequences the 7 existing `ddd-*` step skills via `Skill()` inline, gating between steps. The Architect-family specialists (`ddd-event-discoverer`, `ddd-context-analyzer`, `ddd-canvas-builder`) remain the Opus workers the step-skills call. `ddd-architect` is gone (Phase 2).

### 3d. Rebuild `/pm` as an inline orchestrator skill
- [x] `commands/pm.md` → `skills/pm/SKILL.md` (`model: sonnet`, inline). Orchestrates by calling `pm-synthesize` (the PM inline persona) with gates instead of spawning a `pm-architect` subagent. Rationalize the former `pm-architect` vs `pm-synthesize` overlap into the single inline path.

### 3e. Tidy up
- [x] Remove converted files from `commands/`; verify nothing references them.
- [x] Refresh `README.md`: it still documents `/create_plan`-style commands and a stale install flow; update the command/skill/agent lists to match the role taxonomy.
- [x] Confirm `scripts/install.sh --delete` removes retired commands from `~/.claude/commands/`.

### Automated verification
- [x] `ls commands/` is empty.
- [x] `skills/{ddd,pm,commit,validate-plan}/SKILL.md` exist, `name` matches folder, valid `---` frontmatter.
- [x] `grep -rn 'ddd-architect\|pm-architect' .` (excluding `.git/`, this plan) returns nothing (only documentation comments in skill bodies, no functional references).
- [x] `scripts/install.sh` runs clean.

---

## Phase 4 — New `/qrspi` orchestrator skill

The connective tissue that drives one ticket through Q→R→S→P→I, delegating to roles.

### Design
- **Skill**: `skills/qrspi/SKILL.md`, `model: sonnet`, **inline** (needs AskUserQuestion). Sonnet is correct *because gates are present*; if you later run `/qrspi` fully unattended, revisit per the unattended-orchestrator rule — it would need Opus.
- **`allowed-tools`**: `Read, Grep, Glob, Bash(git *), Bash(gh *), Task, AskUserQuestion, TodoWrite, Skill` + Linear MCP read tools.
- **`argument-hint`**: `[TICKET-ID]`; **invocation**: `/loop /qrspi ENG-123` (self-paced; each wake runs ONE step).

### State machine (Linear status → next stage)
| Current status | Next stage skill | Advances to |
|---|---|---|
| Backlog / Todo | `improve-issue` | Ready for Research |
| Ready for Research | `research-codebase` (gate: design needed? → `tech-spec`) | Ready for Plan |
| Ready for Plan | `create-plan` | In Plan |
| In Plan | `implement-plan` (→ `developer` subagent) | In Progress |
| In Progress | `implement-plan` / `describe-pr` | In Review |
| In Review | hand off to `babysit-pr` (its own loop → merge) | Done |
| Done | terminal — stop | — |

### Stop-state (compensates for `/loop` lacking `/goal` tripwires)
- [x] Maintain `thoughts/shared/qrspi/<ticket>.md`: last status, last stage, attempt count, `halt` flag (`needs-user` | `blocked` | `terminal`).
- [x] Halt (stop + surface to user) when: a stage returns blocked; the same stage would run a 2nd consecutive time without status advancing (anti-loop guard); status is terminal; or an unanswered gate is pending.
- [x] On a clean completion with the next stage autonomous-safe, end the turn so the `/loop` re-invocation picks up the next stage.

### Build
- [x] Write `skills/qrspi/SKILL.md` (ultrathink header, Current Context git block, with/without-ticket initial response, state-machine table, per-stage `Skill()` dispatch, gates, stop-state, troubleshooting).
- [x] Write `skills/qrspi/references/state-machine.md` if SKILL.md exceeds ~5k words.

### Automated verification
- [x] `skills/qrspi/SKILL.md` exists; `name: qrspi`; description < 1024 chars, no angle brackets.
- [ ] Dry-run `/qrspi <real-ticket>` reads status and selects the correct next stage, gating before any destructive action.

---

## Phase 5 — Operating-model guidance (low-risk, anytime)

- [x] Add an "Operating model" section to `README.md`: run the session on Sonnet (`/model sonnet`); Sonnet skills run cheap, the opus skills auto-promote only their turn, subagents run their role tier. Recommend Sonnet (not Haiku) as the default orchestrator; Haiku for mechanical/polling sessions only.
- [x] Optional: add `"model": "sonnet"` to `.claude/settings.json` as the repo default.

### Automated verification
- [x] README has an "Operating model" section reflecting the role tiers.

---

## Risks & notes

- **Reference churn (Phase 2d) is the riskiest mechanical step** — a missed `subagent_type` rename breaks a skill silently. The grep verification is load-bearing; run it before commit.
- **Merging four readers into `researcher`** must preserve each former agent's distinct contract as a mode, or research quality regresses. Keep the modes explicit in the body.
- **Scout on Haiku**: pure grep/glob locate is mechanical, but if Haiku under-locates, fall back to Sonnet.
- **`/loop` robustness**: without `/goal` tripwires, the Phase 4 stop-state is load-bearing — build it before unattended runs. `babysit-pr` keeps its `/goal` + cron for the merge tail.
- **Forked `critique`**: loses conversational context; only an issue for "critique what we just discussed," which isn't its job. Document the caveat.
- **Sequencing**: Phase 1 anytime. Phase 2 before 3 and 4. Phase 5 anytime. Phase 3 and 4 can run in parallel after Phase 2.

## Out of scope (separate follow-ups)
- Splitting the interactive opus skills (`create-plan`, `tech-spec`, `grill-me`, `improve-codebase-architecture`, `ubiquitous-language`, `skill-builder`) further — inline-opus is correct for them given the gate constraint.
- Reworking `linear-ticket-status-sync`'s status names.
