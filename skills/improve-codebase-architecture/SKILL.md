---
name: improve-codebase-architecture
description: "Find 'deepening opportunities' — places where shallow modules should be consolidated into deep ones with small interfaces over leveraged implementations — and feed them into the QRSPI flow as Linear tickets. Reads prior research/, .jeff/, and research/ddd/ to ground in existing decisions; walks the codebase with an Explore subagent; presents numbered candidates using the Module/Interface/Seam/Adapter vocabulary in references/LANGUAGE.md; drops into /grill-me on the chosen candidate; hands off to /improve-issue to create the ticket. Optionally runs a 'design it twice' parallel-subagent pass for alternative interfaces. Use when the user wants an architecture review, refactoring opportunities, testability improvements, or mentions 'shallow modules', 'deep modules', 'too many small files', 'hard to test'. Triggers on 'improve architecture', 'find refactoring opportunities', 'architecture review', 'what's shallow in this codebase', 'deepen X'."
model: opus
user-invocable: true
allowed-tools: Read, Grep, Glob, Task, AskUserQuestion, TodoWrite, Skill, Write, Edit, Bash(git *), Bash(gh *)
argument-hint: [optional-scope-path]
---

You are operating in **Architect mode** — your role is to find deepening opportunities in the codebase and guide restructuring.

# Improve Codebase Architecture

Ultrathink about leverage. Most refactoring opportunities are framed as "split this up" when the real win is the opposite: **merge a cluster of shallow modules behind a small interface over a richer implementation**. The aim is not tidiness. It is *leverage* (more behaviour per unit of interface a caller learns) and *locality* (bugs, changes, and tests concentrated at one place). This skill finds those candidates, grills the user on the best one, and turns the outcome into a Linear ticket at the top of the QRSPI flow.

**Input**: $ARGUMENTS — optional scope path (e.g. `src/billing/`, `packages/auth`). Empty means "walk the whole repo" (slower, broader).

## Required reading (consult before Step 2)

Use the exact vocabulary in [references/LANGUAGE.md](references/LANGUAGE.md) in every suggestion. **Module**, **Interface**, **Seam**, **Adapter**, **Depth**, **Leverage**, **Locality** — don't drift to "component," "service," "API," or "boundary." Consistency of language is the point.

- [references/LANGUAGE.md](references/LANGUAGE.md) — architecture vocabulary + deletion test + key principles.
- [references/DEEPENING.md](references/DEEPENING.md) — dependency taxonomy and testing strategy for a deepened module.
- [references/INTERFACE-DESIGN.md](references/INTERFACE-DESIGN.md) — "design it twice" parallel-subagent pattern for alternative interfaces.

## Current Context

- **Branch**: !`git branch --show-current`
- **Last Commit**: !`git log -1 --oneline`
- **Recent research**: !`ls -t research/*.md 2>/dev/null | head -5 || echo "(none)"`
- **DDD artifacts**: !`ls research/ddd/ 2>/dev/null | head -10 || echo "(none)"`
- **jeff artifacts**: !`ls .jeff/ 2>/dev/null | head -10 || echo "(none)"`
- **Glossary**: !`ls research/ubiquitous-language.md 2>/dev/null || echo "(none)"`

## Initial Response

1. **Scope provided**: begin Step 1 with that scope.
2. **No scope**:
   ```
   I'll find deepening opportunities — places where shallow modules should be consolidated
   into deep ones — and turn the most promising into a Linear ticket.

   Optionally scope the walk to speed it up:
     /improve-codebase-architecture src/billing
     /improve-codebase-architecture packages/ingest

   Empty means whole-repo (slower). Proceed with whole-repo?
   ```
   Brief-then-Ask: `whole-repo`, `narrow-to-<path>` (Other), `cancel`.

## Brief-then-Ask Discipline

Every `AskUserQuestion` in this skill must brief in prose first with file paths, concrete numbers, and a recommendation — then ask. Option descriptions restate the choice on one line so the user can decide from the option list alone. See `references/LANGUAGE.md` for the vocabulary that briefs must use.

## Process Steps

### Step 1: Read prior decisions

Goal: don't re-litigate things the team has already decided.

1. Read `research/ubiquitous-language.md` if it exists — you'll use these terms when naming candidates.
2. Read any `research/ddd/` bounded-context or aggregate canvases — they define *where good seams should live*. A candidate that fights the bounded-context boundary is suspect.
3. Skim recent `research/*.md` and `.jeff/OPPORTUNITIES.md`, `.jeff/HYPOTHESES.md` for architecture-bearing content. Record any decisions that look load-bearing (e.g. "we chose Postgres over DynamoDB because…").
4. If none of these exist, proceed silently — don't flag their absence or propose creating them up front.

Note: this repo does not use a `docs/adr/` directory. Research docs in `research/` serve the same role; treat them as decision history.

### Step 2: Walk the codebase (Explore subagent)

Spawn an `Explore` subagent with thoroughness `very thorough` if no scope was given, `medium` if a scope path was given. Prompt:

```
Walk the codebase [under <scope> | repo-wide]. Do not follow rigid heuristics —
explore organically and note places where you experience friction.

Look for deepening opportunities (use references/LANGUAGE.md vocabulary verbatim):

1. Clusters of SHALLOW modules — interface nearly as complex as implementation.
   Apply the deletion test: if deleted, does complexity vanish (pass-through), or
   reappear across N callers (was earning its keep)? The former is a candidate.

2. Pure functions extracted purely for testability, but real bugs hide in how
   they're called — LOCALITY is lost.

3. Tightly-coupled modules that leak across their seams.

4. Modules that are untested or hard to test through their current interface.

5. Places where understanding one concept requires bouncing between many files.

For each candidate return:
  - name (use CONTEXT/glossary vocabulary if we have it)
  - files (paths + rough line counts)
  - current_shape (how many modules, what the interfaces look like)
  - proposed_shape (single deep module with what interface)
  - dependency_category (one of: in-process | local-substitutable |
    ports-and-adapters | true-external — per references/DEEPENING.md)
  - strength (one of: strong | worth-exploring | speculative — how confident
    you are this is a real deepening, not just tidiness)
  - wins (3–6 bullets, ≤6 words each, named in glossary terms —
    e.g. "locality: bugs concentrate in one module", "two adapters justify
    the seam", "interface shrinks; implementation absorbs wrappers".
    Do NOT write "easier to maintain" or "cleaner code".)
  - before_mermaid (a `flowchart LR` block showing the shallow cluster
    with leakage edges marked, suitable for embedding in Linear markdown)
  - after_mermaid (a `flowchart LR` block showing the single deep module
    with its interface and what sits behind the seam)
  - risk (what could go wrong; reversibility)
  - effort (S / M / L / XL)
  - bounded_context_conflict (null, or the names of the contexts crossed)

Return JSON. Cap at 8 candidates, ranked by (leverage × frequency-of-change) / effort.
```

If the subagent returns zero candidates, surface that honestly and stop — "This codebase doesn't have obvious deepening opportunities in the walked scope." Don't manufacture candidates.

### Step 3: Present candidates + pick one (Brief-then-Ask)

Brief in chat: for each candidate, restate its `name / strength / files / current_shape / proposed_shape / dependency_category / wins / risk / effort / bounded_context_conflict`. Use the glossary's domain vocabulary (not file names) where possible — "the Order intake module" not "the FooBarHandler." Skip the Mermaid diagrams in the chat brief — they're for the ticket body.

End the brief with a **Top recommendation** line: which one candidate you'd tackle first and why, in one sentence. Be opinionated — the user wants a strong read, not a menu.

`AskUserQuestion`:
- One option per candidate. `label` = candidate name. `description` = one line: *"[strength] collapse X/Y/Z into a deep `<Name>` module — {top win}, {effort} effort, {dependency_category}"*. Prefix with the strength tag so the user can scan it.
- Plus:
  - `want-more-candidates` → "None of these; walk again with different constraints."
  - `explain-in-depth-<N>` → pick one for a deeper read before committing (loop back with an extended explanation).
  - `cancel` → end the skill.

### Step 4: Grill the chosen candidate

Draft a short brief (3–5 paragraphs) of the chosen candidate: the proposed deep module, its interface sketch, what sits behind the seam, the dependency category, and known open questions (what to put behind the seam, what to leave out, ordering of extraction, how tests will change).

Invoke `Skill(skill: "grill-me", args: "<in-memory brief>")` — grill-me returns structured findings (Resolved / Deferred / New). Do not ask the user separately; grill-me owns the interrogation.

After grill-me returns, merge its findings into the candidate brief. If grill-me surfaced a blocker the user deferred, mark the candidate status as `needs-more-design` and offer to loop into Step 4.5 (interface design).

### Step 4.5 (optional): Design the interface twice

Brief-then-Ask whether to explore alternative interfaces:
- **Brief**: *"grill-me surfaced 2 real open questions on the interface shape. 'Design it twice' runs 3 parallel subagents with different constraints (minimize surface / maximize flexibility / optimize common case) and compares. Worth ~5 min of wall time; produces a clearly-motivated interface."*
- Options: `design-twice`, `skip-use-grilled-sketch`.

If `design-twice`: follow [references/INTERFACE-DESIGN.md](references/INTERFACE-DESIGN.md) exactly. Spawn 3+ parallel Task subagents with different constraints, each producing a full interface proposal. Present sequentially, then compare by depth / locality / seam placement. Give your own opinionated recommendation. Brief-then-Ask to pick one (or propose a hybrid).

### Step 5: Side effects (inline)

Handle these inline as they come up during Steps 3–4.5:

- **New domain term surfaced while naming the deep module?** Brief-then-Ask: *"`<term>` isn't in research/ubiquitous-language.md. Run /ubiquitous-language to add it?"* Options: `run-ubiquitous-language-now`, `add-inline-ill-run-later`, `skip`. If inline, add the term yourself with a one-line definition.
- **User rejects a candidate with a load-bearing reason?** Offer to persist the reason so future architecture reviews don't re-suggest it: *"Record this rejection in `research/YYYY-MM-DD-arch-rejected-<slug>.md` so we don't re-propose it?"* Options: `record-rejection`, `skip`. Only offer when the reason would actually be needed by a future explorer — skip ephemeral ("not now") or self-evident reasons. Since this repo doesn't use `docs/adr/`, a dated research doc plays the ADR role.
- **Bounded-context conflict flagged by the subagent?** Don't silently override — Brief-then-Ask: *"This candidate crosses `<context-A>` and `<context-B>` per research/ddd/. Options: (a) reshape candidate to stay inside one context, (b) proceed and amend the context boundary, (c) drop the candidate."*

### Step 6: Handoff — create the Linear ticket

Default handoff for QRSPI: the chosen candidate becomes a Linear ticket via `/improve-issue`.

1. Compose a ticket body:
   - **Title**: verb-first, uses the deep module's name (e.g. *"Deepen order-intake module — collapse IntakeHandler/OrderBuilder/OrderValidator behind a single interface"*).
   - **Problem**: current shallow shape, with file paths.
   - **Before / After**: embed the candidate's `before_mermaid` and `after_mermaid` blocks as side-by-side `flowchart LR` diagrams. Linear renders Mermaid in markdown. The diagrams carry the weight — keep surrounding prose to one sentence each.
   - **Proposed shape**: the deep module's interface (names only, not types).
   - **Dependency category** and **testing strategy** (per `references/DEEPENING.md`).
   - **Wins**: the candidate's `wins` bullets verbatim — ≤6 words each, in glossary terms. Do not pad with prose.
   - **Risk & reversibility**.
   - **Grill outcomes**: summary table from Step 4 (Resolved / Deferred / New).
   - **Referenced artifacts**: paths to DDD canvases, glossary, any rejection docs.

2. Apply Linear labels to the created issue:
   - **Strength**: one of `arch:strong`, `arch:worth-exploring`, `arch:speculative` (from the candidate's `strength`).
   - **Dependency category**: one of `dep:in-process`, `dep:local-substitutable`, `dep:ports-adapters`, `dep:true-external`.
   - Create the labels if they don't exist. These let the arch backlog be filtered later.

3. Brief-then-Ask what to do next:
   - **Brief**: *"Candidate ready. Default: create a Linear ticket and run /improve-issue to enrich it. Alternative: skip ticketing and go straight to /tech-spec if the design still has load-bearing open questions."*
   - Options:
     - `create-ticket-and-enrich` (default) → create Linear issue via Linear MCP, then invoke `Skill(skill: "improve-issue", args: "<ticket-id>")`.
     - `go-to-tech-spec` → invoke `Skill(skill: "tech-spec", args: "<ticket-id or draft path>")` directly. Use when grilling left ≥2 open design branches.
     - `save-draft-research` → write `research/YYYY-MM-DD-arch-<slug>.md` with the ticket body + grill outcomes; no Linear. Use when the user wants to sit on it.
     - `stop` → end the skill with a summary in chat only.

4. If a ticket was created, print the ticket URL + a one-paragraph summary and end.

## Guidelines

1. **Deepen, don't split.** The default architectural move in this skill is consolidation. Splits are rare — and when they occur, they're in service of deepening a sibling.
2. **Vocabulary discipline.** Use `references/LANGUAGE.md` terms in every suggestion; use `research/ubiquitous-language.md` terms for domain names. Never drift.
3. **Deletion test before proposing.** If deleting a module doesn't concentrate complexity, proposing to merge it is premature.
4. **One adapter = hypothetical seam. Two = real.** Don't propose a port when there's no second adapter in sight.
5. **Respect DDD boundaries.** Candidates that cross bounded contexts need explicit user confirmation before proceeding.
6. **Grill before ticketing.** A ticket produced from an un-grilled candidate has fake resolution; grilling is what makes the "Open questions" section honest.
7. **Default handoff is the ticket.** This skill feeds the top of QRSPI; `/improve-issue` and `/tech-spec` exist to carry the idea further.
8. **Never auto-write code.** This skill proposes and hands off. Implementation happens under `/create-plan` and `/implement-plan`.
9. **Don't re-litigate decisions.** Prior `research/*.md` rejections are honored unless the user explicitly reopens them.

## Troubleshooting

- **Subagent returns zero candidates** → state it plainly, don't invent. Offer to narrow or broaden the scope.
- **Every candidate looks the same** → your walk is too narrow. Broaden scope or spawn a second Explore with `very thorough`.
- **User disagrees with the vocabulary** (*"we don't call it a 'module' here"*) → don't fold. Explain the vocabulary is deliberate (for consistency across architecture reviews) and offer to cross-reference their preferred term in the ticket body. If they insist, record in `research/ubiquitous-language.md` via `/ubiquitous-language` and continue.
- **Grill-me surfaces a blocker that invalidates the candidate** → drop back to Step 3 and pick a different candidate. Don't push a broken candidate into a ticket.
- **Linear MCP fails** → fall back to `save-draft-research`; print the ticket body for the user to paste manually, with the file path to the saved draft.
- **Repo has no prior research/DDD/jeff artifacts** → proceed; just rely on codebase signals and use generic vocabulary. Offer once at the end to seed `research/ubiquitous-language.md` with the terms the walk surfaced.
