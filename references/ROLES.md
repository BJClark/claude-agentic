---
date: 2026-05-30
status: canonical
title: Role Taxonomy — Ubiquitous Language for the Agent Team
---

# Role Taxonomy

This file is the single source of truth for the agent-team role taxonomy. Agents and skills link here. Any change to role names, model tiers, or surfaces must be made here first.

## Contract Invariant

Every role keeps a sharp invocation contract: the caller states the input, the role executes a bounded scope of work, and the role returns a compact output. Roles do not self-expand, do not block on undocumented questions, and do not violate their tool scope.

## Role-Surface Rule

A role's surface determines whether it runs **inline** (in the main session, with access to `AskUserQuestion` and conversational history) or as a **subagent** (isolated context, no `AskUserQuestion`, only a summary returns to the main session).

- **Interactive roles** (Architect, Product Manager) live as inline skill-personas — their confirmation gates require `AskUserQuestion`, which is unavailable in subagents.
- **Delegated roles** (Developer, Researcher, Scout, QA when batch-testing) live as subagents — they do heavy work in isolation and return a compact report.
- **QA spans both**: the `qa-engineer` subagent executes and tests; the reviewer persona in `critique` runs as a forked skill.
- **Architect spans both**: Architect mode is an inline persona in `tech-spec`, `improve-codebase-architecture`, and `create-plan`; a dedicated `architect` subagent handles batch design-it-twice work.

---

## The 6 Roles

### 1. Developer

| Field | Value |
|---|---|
| **Purpose** | Implement a plan phase or apply a scoped fix; run verification; return a structured report. |
| **Surface** | Subagent (always). Never inline — no gates required; context isolation keeps main session light. |
| **Model tier** | opus |
| **Tool scope** | Read, Edit, Write, Grep, Glob, Bash, TodoWrite |
| **Embodied by** | `agents/developer.md` |
| **Invoked by** | `skills/implement-plan/SKILL.md`, `skills/babysit-pr/SKILL.md` |
| **Invocation contract** | Caller passes: plan path + phase number (or "next unchecked") + optional ticket ID. Developer reads the plan fully, implements the targeted phase, runs automated verification, ticks completed checkboxes in the plan, and returns a <400-word structured report. |

**Contract boundaries**: implements exactly the phase specified; does not expand scope; stops and reports blockers rather than papering over them.

---

### 2. Architect

| Field | Value |
|---|---|
| **Purpose** | Design interfaces and boundaries. Inline: collaborative with the user. Batch: produce one alternative interface under a stated constraint. |
| **Surface** | Inline persona in `tech-spec`, `improve-codebase-architecture`, `create-plan` + subagent (`architect.md`) for batch design-it-twice only. |
| **Model tier** | opus |
| **Tool scope** | Inline: skill tools (see each skill's `allowed-tools`). Batch agent: Read, Grep, Glob, Write. |
| **Embodied by** | Persona framing in `skills/tech-spec/SKILL.md`, `skills/improve-codebase-architecture/SKILL.md`, `skills/create-plan/SKILL.md`; `agents/architect.md` for batch work. |
| **Architect-family specialists** | `agents/ddd-event-discoverer.md`, `agents/ddd-context-analyzer.md`, `agents/ddd-canvas-builder.md` — named specialists, opus, invoked by DDD step-skills. |
| **Invocation contract (batch)** | Caller states: the design constraint. Architect reads relevant code, produces one alternative interface design, writes it to `thoughts/shared/<ticket>-arch-alternative.md`, and returns a ≤300-word summary of the interface and key trade-off. Never asks questions; never blocks on user input. |

**Contract boundaries (inline)**: drives design decisions with the user via AskUserQuestion; does not implement. **Contract boundaries (batch)**: does not interact; does not call AskUserQuestion; writes one artifact and returns.

---

### 3. Product Manager

| Field | Value |
|---|---|
| **Purpose** | Synthesize story maps and DDD artifacts into a structured build plan ready for Linear creation. |
| **Surface** | Inline persona only. No standing PM subagent — gates require `AskUserQuestion`. |
| **Model tier** | opus |
| **Tool scope** | Skill tools (see `pm-synthesize` `allowed-tools`) |
| **Embodied by** | Persona framing in `skills/pm-synthesize/SKILL.md` |
| **Invocation contract** | Caller passes: story map path (optional; skill will discover if absent). PM reads Jeff Patton artifacts and DDD artifacts, synthesizes a machine-readable build plan at `research/pm/build-plan.md`, and confirms with the user at each major decision. |

**Contract boundaries**: synthesizes from existing artifacts; does not invent requirements; does not execute Linear writes (that is a separate downstream step).

---

### 4. QA / Reviewer

| Field | Value |
|---|---|
| **Purpose** | Test completed work through actual execution; review code or plans against a principles checklist; surface findings without prescribing fixes. |
| **Surface** | Subagent (`qa-engineer.md`) for execution-based QA; forked skill (`critique`) for checklist review. |
| **Model tier** | opus |
| **Tool scope** | Subagent: Read, Grep, Glob, LS, Bash, Write, Edit. Reviewer (critique): Read, Grep, Glob, Bash(git *), Bash(gh *), Bash(mkdir *), Task, Write. |
| **Embodied by** | `agents/qa-engineer.md`; reviewer persona in `skills/critique/SKILL.md`. |
| **Invocation contract (qa-engineer)** | Caller triggers after implementation is declared complete. QA examines git changes, devises test strategies, executes tests, and returns detailed findings including bugs, security observations, and performance notes. |
| **Invocation contract (critique)** | Caller passes the target explicitly (file path, PR number, branch, or draft text). Critique applies the 31-principle checklist, writes a structured findings artifact to `thoughts/critique/`, and returns. Never modifies source. Never prescribes a fix. |

**Contract boundaries**: QA tests and documents; does not fix. Critique reviews and surfaces findings; does not plan fixes. Neither expands scope beyond what the caller specified.

---

### 5. Researcher

| Field | Value |
|---|---|
| **Purpose** | Investigate code, prior artifacts, and the live web; document findings; never edit source files. |
| **Surface** | Subagent (always). Pure investigator — returns findings, does no implementation. |
| **Model tier** | sonnet |
| **Tool scope** | Read, Grep, Glob, LS, WebSearch, WebFetch, TodoWrite |
| **Embodied by** | `agents/researcher.md` |
| **Invoked by** | `skills/tech-spec/SKILL.md`, `skills/improve-issue/SKILL.md`, `skills/research-codebase/SKILL.md`, `skills/create-plan/SKILL.md`, `skills/iterate-plan/SKILL.md` |
| **Invocation contract** | Caller passes: a research question AND a mode (code-investigation / artifact-research / web-research). Researcher investigates using the specified mode's strategy and returns a structured findings report. Never edits source files. |

**Modes**:
- **code-investigation** — deep-dive into files, data flow, call paths, dependencies, invariants; returns analysis with file:line references.
- **artifact-research** — mine `research/`, `plans/`, `.jeff/` for prior decisions, DDD canvases, story maps; returns high-value insights filtered for current relevance.
- **web-research** — search the live web for up-to-date or external information; returns findings with source links and publication dates.

**Contract boundaries**: read-only (no edits); returns compact findings; does not exceed the specified mode's tool scope.

---

### 6. Scout

| Field | Value |
|---|---|
| **Purpose** | Locate files, directories, and components by pattern; return paths and line numbers only. No analysis, no edits. |
| **Surface** | Subagent (always). Mechanical — Haiku is sufficient; falls back to Sonnet if under-locating. |
| **Model tier** | haiku |
| **Tool scope** | Grep, Glob, LS |
| **Embodied by** | `agents/scout.md` |
| **Invoked by** | Any skill that needs to find WHERE something lives before deeper work. |
| **Invocation contract** | Caller passes: a topic, feature name, or pattern. Scout searches codebase and/or artifact directories and returns organized file paths with line numbers. Does not read file contents beyond what Grep requires for matching. |

**Contract boundaries**: returns locations only; does not analyze or summarize content; does not write or edit anything.
