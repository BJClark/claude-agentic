---
name: tech-spec
description: "Design phase between research and planning: given a Linear ticket or PR, draft a Scoping Brief (success metric, scale, SLA, consistency, fear, existing solutions), explore 2–4 candidate approaches (including adopt-OSS candidates), pick one with the user, run /critique on the draft, and produce a durable high-level Tech Spec synced to Linear. Use after /research-codebase but before /create-plan — when the question is 'which way should we build this?'. Triggers on 'tech spec for ENG-1234', 'tech spec for PR 567', 'design doc for Y', 'compare approaches for Z', 'spec this out before we plan'."
model: opus
user-invocable: true
allowed-tools: Read, Grep, Glob, Write, Edit, Task, AskUserQuestion, TodoWrite, Skill, Bash(git *), Bash(gh *)
argument-hint: [linear-ticket-or-pr-number]
---

# Tech Spec

Ultrathink about the design space before writing anything. A tech spec is not a plan — it is a *decision artifact*. Its job is to make the "which approach" choice visible: to surface the 2–4 real options (including "adopt something that already exists"), to state the tradeoffs in the user's terms with concrete numbers, and to record which one was chosen and why. Plans execute a choice; specs make it.

This skill sits **between** `/research-codebase` (documents what exists, no evaluation) and `/create-plan` (phase-by-phase execution). If you find yourself picking an approach inside `/create-plan`, the tech spec is missing.

**Input**: $ARGUMENTS — expected to be a Linear ticket ID (e.g. `ENG-1234`) or a PR number / URL. Research-doc paths and free-form topics are accepted as fallbacks; the skill will warn that the spec will be weaker without a ticket or PR.

## Current Context

- **Branch**: !`git branch --show-current`
- **Last Commit**: !`git log -1 --oneline`
- **Open PR on branch**: !`gh pr view --json number,title,url 2>/dev/null || echo "(none)"`
- **Recent tech specs**: !`ls -t research/*techspec*.md 2>/dev/null | head -5 || echo "(none)"`

## Initial Response

1. **`$ARGUMENTS` matches Linear ticket ID** (`(?i)(ENG|PLAT|OPS|STELLAR|MEERKAT|KICKPLAN|AURA)-\d+`) → resolve via Linear MCP. Begin **Step 1**.
2. **`$ARGUMENTS` matches PR number / URL** → resolve via `gh pr view`. Begin **Step 1**.
3. **`$ARGUMENTS` is a research-doc path** (ends in `.md`, exists) → read it; begin Step 1 with input shape `research-doc`.
4. **`$ARGUMENTS` is free-form prose** → warn once that a ticket/PR makes a better spec, then proceed.
5. **`$ARGUMENTS` is empty**:
   ```
   I'll help you produce a Tech Spec — a durable design doc that explores 2–4 approaches (including adopt-OSS), picks one, critiques the draft, and syncs to Linear.

   Please provide one of:
     1. A Linear ticket ID:   /tech-spec ENG-1234
     2. A PR number or URL:   /tech-spec 567
     3. A research doc path:  /tech-spec research/2026-04-21-auth-migration.md
     4. Free-form topic:      /tech-spec "split billing out of the monolith"   (weaker — no ticket/PR scope)

   Tip: If no research doc exists yet, run `/research-codebase` first for a materially better spec.
   ```
   Then wait.

## The Context Principle (read this every invocation)

Every `AskUserQuestion` in this skill must follow the **Brief-then-Ask** pattern:

1. **Brief** (prose in chat, immediately before the question):
   - Name each option in full (no "option 1", "the first one", "that approach").
   - 1–3 sentences per option: *what it is*, *the key tradeoff*, *concrete numbers where relevant* (latency, LOC, migration rows, new services, weeks of effort, license type).
   - State shared assumptions once at the top.
2. **Ask** (`AskUserQuestion`):
   - Option `label` is the short name.
   - Option `description` restates the choice on one line — not just the label — so the user can decide from the option list alone.

**Anti-patterns to avoid**: "Approach A / Approach B / Approach C"; "Yes / No / Maybe"; pronouns referring to earlier chat; asking before briefing.

## Process Steps

The skill is heavy on subagent work to keep the main session focused on synthesis and decisions. Steps 1–3 and 4 spawn subagents; Steps 5–9 are main-session synthesis + user-facing decisions.

### Step 1: Resolve input & fetch context

Spawn the **input-resolver** subagent (`Task` tool). Prompt per [references/input-resolution.md](references/input-resolution.md). It returns the resolved bundle: `{ source, ticket_id, pr_number, problem_text, scope_signals, prior_art, warnings }`.

Surface the bundle's warnings in chat. If `warnings` contains "PR is merged" or "scope disagrees with ticket", pause and confirm via Brief-then-Ask before continuing.

If a prior tech spec on the same topic exists (`prior_art.prior_tech_specs` non-empty), read it fully. Note whether the new work supersedes or amends it — you'll act on this at Step 8.

**Record the `ticket_id`** even if the primary input was a PR — Linear sync at Step 9 depends on it.

### Step 1.5: Complexity triage (right-size the spec)

Not every ticket deserves the full heavy flow. Classify into **Light / Standard / Heavy** per [references/complexity-triage.md](references/complexity-triage.md), which carries the auto-classification signals and the per-size behavior table for Steps 2 / 4 / 5 / 6 / 7 / 8.

1. Run the auto-classifier against the Step 1 bundle — returns `auto_size` ∈ {light, standard, heavy}.
2. Brief-then-Ask to confirm or override:
   - **Brief** (prose): state the auto-size and the top 2–3 signals that drove it (e.g. *"Heavy — labels include `migration`, body mentions 'extract billing service', files span 3 packages"*). Then list what each size costs and produces (2–3 user turns / 5–7 / 10–15; 1-page spec / standard template / full template).
   - **Ask**: options are the three sizes + a `skip-spec` option (only for Light — hand off to `/create-plan` directly). See `complexity-triage.md` for exact option phrasing.
3. Record the chosen size in memory for the remaining steps. All downstream steps check this size before running subagents / questions.
4. Write `complexity`, `complexity_auto`, `complexity_overridden_by` into the artifact frontmatter at Step 8.

**Guardrail**: if a Light or Standard run starts ballooning (> 2 extra Brief-then-Ask turns beyond budget), stop and offer an upgrade via Brief-then-Ask. Mis-sized specs should be re-sized, not ground through.

### Step 2: Draft the Scoping Brief (subagent)

**Size-gated** per `references/complexity-triage.md`:

- **Light**: skip the subagent. Ask the user directly in a single Brief-then-Ask for three answers: *success metric* (A1), *scariest failure mode* (A7), *definition of done* (A10). Proceed to Step 4.
- **Standard**: spawn the subagent but scope to Sets A + C (skip Set B / Beck questions unless the problem clearly benefits). Target 6–8 answers.
- **Heavy**: full flow per below.

Spawn the **scoping-brief** subagent with the Step 1 bundle plus [references/framing-questions.md](references/framing-questions.md). Its prompt:

```
Task: using the input bundle, draft a Scoping Brief answering the Set A (engineering), Set B (Beck / learning posture), and Set C (buy-vs-build / prior art) questions in references/framing-questions.md.

You do NOT need to answer all 25 questions literally. Instead:
1. Triage per the rubric in framing-questions.md — which questions are load-bearing for THIS problem?
2. For each load-bearing question, draft an answer from the input bundle's problem_text, scope_signals, and prior_art. Mark confidence (high / med / low).
3. For each question you cannot answer, mark it as a GAP — with a one-line note explaining why the answer matters for the design.
4. For low-relevance questions, pre-fill a sensible default and flag if-wrong.

Return the brief in the structure given at the bottom of framing-questions.md.

Be compact. Each answer ≤ 2 sentences. Use numbers where possible.
```

### Step 3: Confirm scoping with the user (Brief-then-Ask)

Present the Scoping Brief in chat as the Brief. Then `AskUserQuestion`:

- Options:
  - `brief-is-correct` → "Confirm the brief; fill gaps with the defaults the subagent suggested"
  - `fill-gaps` → "I'll answer the GAP questions now" — then run a follow-up `AskUserQuestion` per gap (each gap gets its own Brief-then-Ask with the question's rationale inline)
  - `correct-drafts` → "Some drafted answers are wrong — I'll correct them"
  - `problem-is-different` → "Your framing missed the real problem — start over with my input"
  - `pause` → "I need to come back with more input"

Iterate until approved. **Do not proceed with an unapproved frame** — a wrong frame compounds into a wrong spec.

Persist the final scoping answers; they go into the artifact's `Scoping` section at Step 8.

### Step 4: Generate candidate approaches (parallel subagents)

**Size-gated** per `references/complexity-triage.md`:

- **Light**: 1 approach. **Skip all subagents.** Sketch the approach inline from user input + Step 1 bundle. If you can't sketch a clear approach in 2 sentences, stop and offer an upgrade to Standard.
- **Standard**: 2 approaches. Spawn **codebase-pattern-finder** only. Run the **OSS web search** only if the problem category matches a known primitive (queue, cache, search, workflow engine, feature flag, CDC, auth, scheduler, job runner, pub/sub, rate limiter, secrets). Otherwise skip it.
- **Heavy**: 2–4 approaches. Spawn all 4 subagents in parallel (below).

Subagents available (prompts in [references/candidate-generation.md](references/candidate-generation.md)):

- **codebase-pattern-finder** — prior solutions to analogous problems in this repo.
- **artifacts-analyzer** — prior research/specs/DDD artifacts bearing on this area.
- **web-search-researcher (prior art / OSS)** — always on for Heavy; conditional on category-match for Standard; skipped for Light. Produces adopt/fork/build-inspired candidates from OSS & SaaS landscape.
- **web-search-researcher (pattern)** — only if a named industry pattern applies (event sourcing, CQRS, SAGA, CDC, strangler fig, outbox, etc.).

Synthesize into **2–4 genuinely different candidates**, each with: name, 1-paragraph sketch, key tradeoff, effort (S/M/L/XL), risks, reversibility. Adopt-OSS candidates must include: license, scale evidence, custom delta, gotchas. See candidate-generation.md synthesis checklist.

If you can only produce one candidate, stop — either the problem is trivially constrained (spec one approach well) or the design space isn't understood yet (loop back to Step 3).

### Step 5: Pick an approach (Brief-then-Ask)

Present the candidate list in prose as the Brief (each candidate fully fleshed out — name, sketch, key tradeoff, effort, risks, reversibility, and for adopt candidates: license + custom delta).

`AskUserQuestion`:
- One option per candidate — `label` is the short name, `description` restates the tradeoff and effort in one line.
- Plus:
  - `combine` → "Mix elements from multiple approaches (I'll ask which)"
  - `need-more-info` → "Not enough info yet — I'll name what I need"
  - `more-options` → "None of these — generate more candidates"

Handle `combine` / `need-more-info` / `more-options` per Step 4 of the prior spec version (named fork-up questions via Brief-then-Ask, or loop back to Step 4).

### Step 6: High-level design of the chosen approach

Sketch — outline level, not phase level:

- **Components**: added/changed/deleted, 1 line each.
- **Data**: new entities/tables, schema shifts, migration *shape* (not SQL).
- **Interfaces**: API/event/CLI surface, named endpoints only.
- **Dependencies**: new libs/services/infra, version constraints if they matter.
- **Rollout shape**: dark-launch / flagged / big-bang / shadow-writes / incremental. One sentence.
- **Open questions**: each with **owner** and **forcing function** (e.g. "before Phase 2", "by 2026-05-01").

For each significant sub-decision (data store, sync vs async, library choice, tenancy), use Brief-then-Ask `AskUserQuestion`.

### Step 7: Self-critique

**Size-gated**:

- **Light**: skipped. (User can still invoke `/critique` manually if they want it.) Jump to Step 8.
- **Standard**: optional. Brief-then-Ask — default *run* if the spec has ≥ 2 approaches with a real design tradeoff; default *skip* if the spec is one approach with minor sub-decisions.
- **Heavy**: mandatory unless the user explicitly opts out.

When running, invoke `/critique` on the in-memory draft spec via the `Skill` tool. Follow [references/critique-integration.md](references/critique-integration.md):

1. Compose the full draft (Problem, Scope, Scoping answers, Candidates, Chosen, High-level design, Open questions) as a string.
2. `Skill(skill: "critique", args: "<draft>")`.
3. Parse findings into **Blockers / Material / Polish**.
4. Brief-then-Ask per critique-integration.md. Options: `address-all`, `address-blockers-only`, `skip-critique`, `rewind-to-step-4`.
5. Apply accepted findings, loop-guarded: a second critique that still returns blockers surfaces to the user — never infinite-loop.
6. Record `critique_run`, `critique_findings`, `critique_resolution` in frontmatter for Step 8.

Skip critique only if the user explicitly opts out OR the spec is trivially small (<2 candidates, 1-paragraph design).

### Step 8: Write the Tech Spec artifact

Path: `research/YYYY-MM-DD-techspec-<slug>.md` (durable — tech specs are kept for months/years).

Use [templates/tech-spec-template.md](templates/tech-spec-template.md), **size-scaled**:

- **Light**: 1-page spec. Sections: Problem / Chosen approach / Open questions / Handoff. Drop Scoping Brief long form, Candidates-considered, Critique resolution.
- **Standard**: full template except the Beck (Set B) section collapses to the 1–2 entries actually answered.
- **Heavy**: full template.

Always include frontmatter: `complexity`, `complexity_auto`, `complexity_overridden_by`.

The artifact must stand alone — a reader 3 months from now should understand the decision without chat history.

**Status**: `approved` if user confirmed at Step 5 and Step 7 resolved cleanly; `draft` if either is still iterating.

**Prior spec handling**:
- If Step 1 identified a prior spec and this one replaces it: edit the old spec's frontmatter (`status: superseded`, `superseded_by: <new-path>`) and add a one-line `Superseded by` note at its top.
- If this one amends a prior spec: link from this spec's frontmatter (`amends: <old-path>`) and leave the old one approved.

Write all work via the `Write-artifact` skill or direct `Write`. Only `Edit` the template file paths, never the artifact after the fact without updating `status` or `version`.

### Step 9: Handoff + Linear sync (mandatory when ticket detected)

1. Show the artifact path and a one-paragraph summary: chosen approach + top 2 tradeoffs + critique resolution.
2. Brief-then-Ask:
   - **Brief**: "The Tech Spec is at `<path>`. Chosen approach: **<name>** — <one line>. Next step is usually `/create-plan` to turn this into phased execution."
   - Options:
     - `invoke-create-plan` → "Invoke /create-plan now using this tech spec path"
     - `iterate` → "Revise the spec — I'll tell you what to change"
     - `stop-here` → "Stop; the spec is enough for now"
3. On `invoke-create-plan`: call `Skill(skill: "create-plan", args: "<spec-path>")`.
4. On `iterate`: amend and re-present.
5. On `stop-here`: proceed to Linear sync.

**Linear sync (mandatory if `ticket_id` is set)**:

Invoke `Skill(skill: "linear-ticket-status-sync", args: "<TICKET> tech-spec")`. This:
- Attaches the tech spec artifact to the Linear ticket.
- Advances the ticket status per the skill's workflow (typically from "Ready for Research" → "Ready for Plan" or the equivalent column).
- Posts a comment linking the spec.

Do NOT skip this when a ticket is present, even if the user chose `stop-here` or `iterate`. The sync reflects the decision the spec records. If the user wants to skip sync, they must say so explicitly — ask via Brief-then-Ask:
- Brief: "Ready to sync to Linear ticket `<TICKET>`? This attaches `<spec-path>` and advances status."
- Options: `sync-now` (default), `sync-later-manually`, `do-not-sync-reason-required` (followup: why?).

If no ticket was detected, skip sync silently.

## Guidelines

1. **Specs make decisions; plans execute them.** If you produce a phase list, stop and hand off to `/create-plan`.
2. **2–4 approaches, genuinely different.** Adopt-OSS must be on the slate when it's viable. Three variations of the same idea is one idea.
3. **Brief-then-Ask is non-negotiable.** See the Context Principle — every question carries substance.
4. **High-level outline, not implementation.** No code, no SQL, no function signatures. Named components and interfaces only.
5. **Tradeoffs are concrete.** "+2 services, +1 on-call rotation, +8 weeks" beats "more complex". Numbers wherever possible.
6. **Every open question has owner + forcing function.** Unowned, unbounded open questions rot.
7. **Buy-vs-build is explicit, not implied.** Step 4 always runs the prior-art / OSS search. If you end up building, the spec records *what OSS/SaaS was considered and why it lost*.
8. **Critique is mandatory.** Step 7 runs `/critique` unless user explicitly skips. Findings and their resolution are recorded in frontmatter so reviewers see the spec was examined.
9. **Durable location.** `research/` — tech specs are referenced months later. Never `thoughts/shared/`.
10. **Linear sync is the default, not a follow-up.** Step 9 runs `/linear-ticket-status-sync` unless the user explicitly opts out with a reason. A tech spec without a synced ticket tends to get forgotten.
11. **Subagents do the heavy work.** Input resolution, scoping draft, candidate generation, critique — all delegated. The main session synthesizes and talks to the user.

## Troubleshooting

- **User says "just pick one" at Step 5** → Brief-then-Ask once with your pick + two-sentence rationale. If they still want you to choose, record `chosen_by: claude` in frontmatter.
- **Only one approach is viable** → proceed with one; record rejected candidates in "Alternatives considered" with one-sentence rationale each.
- **User changes framing mid-spec** → stop, rerun Steps 2–3, regenerate candidates. Patching old candidates against a new frame produces incoherent specs.
- **`/critique` returns blockers after a second pass** → stop auto-applying; Brief-then-Ask options: *deviate from principle (document it)*, *rewind further*, *accept as known tech debt*.
- **PR is merged** → treat as retrospective context, not target. Confirm direction with user before proceeding.
- **Prior spec is approved but new work contradicts it** → Brief-then-Ask: *supersede old spec / amend old spec / treat as new scope*.
- **Linear MCP fails on fetch** → fall back to asking the user to paste the ticket body; still record `ticket_id` in frontmatter so Step 9 sync still runs.
