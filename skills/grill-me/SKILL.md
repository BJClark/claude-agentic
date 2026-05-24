---
name: grill-me
description: "Socratic stress-test of a plan, tech spec, ticket, or design. Walks the decision tree one question at a time, recommends an answer for each, explores the codebase instead of asking when the code already answers it, and grounds every question against the project's ubiquitous-language glossary, DDD canvases (research/ddd/), and Jeff Patton artifacts (.jeff/). Surfaces vocabulary drift and boundary-scenario edge cases as first-class decisions. Use to harden a draft before /create-plan, shake out hidden assumptions in a tech spec, or interrogate a ticket before /improve-issue. Triggers on 'grill me', 'grill this spec', 'stress-test my plan', 'poke holes in X', 'grill me on ENG-1234', 'interrogate this design'."
model: opus
user-invocable: true
allowed-tools: Read, Grep, Glob, Task, AskUserQuestion, TodoWrite, Skill, Bash(git *), Bash(gh *)
argument-hint: [artifact-path-or-ticket-or-pr]
---

# Grill Me

Ultrathink about what's *not yet decided*. A grill is not a critique — critique measures a draft against principles; a grill walks the decision tree and forces each un-made choice into the open. Your job is to find the branches the author hasn't resolved, ask about them one at a time, and — crucially — offer a recommended answer for every question. The recommendation is what turns interrogation into collaboration.

Before asking, prefer the codebase. If a question can be answered by reading files, reading it is free and waiting on the user isn't. Only ask when the code is genuinely silent.

**Input**: $ARGUMENTS — a path to an artifact (tech spec, plan, research doc, ticket body), a Linear ticket ID (e.g. `ENG-1234`), a PR number, or a free-form topic. Empty is valid when the user is grilling "the current thing we've been talking about."

## Current Context

- **Branch**: !`git branch --show-current`
- **Last Commit**: !`git log -1 --oneline`
- **Open PR on branch**: !`gh pr view --json number,title,url 2>/dev/null || echo "(none)"`
- **Recent drafts**: !`ls -t research/*.md plans/*.md 2>/dev/null | head -5 || echo "(none)"`

## Initial Response

Resolve `$ARGUMENTS` in this order:

1. **Matches Linear ticket ID** (`(?i)(ENG|PLAT|OPS|STELLAR|MEERKAT|KICKPLAN|AURA)-\d+`) → fetch via Linear MCP; treat the ticket body + comments as the artifact.
2. **Matches PR number or URL** → `gh pr view --json title,body,files`; treat PR description + changed files as the artifact.
3. **Ends in `.md` and exists** → read the file completely (no limit/offset). This is the artifact.
4. **Free-form prose** → the artifact is the conversation so far plus the prose; record that no durable artifact exists yet.
5. **Empty** — if a draft has been discussed in the current conversation, treat that as the artifact and announce so. Otherwise:
   ```
   I'll grill you on a plan, spec, ticket, or design until the decision tree is resolved.

   Provide one of:
     1. An artifact path:   /grill-me research/2026-04-21-auth-techspec.md
     2. A Linear ticket:    /grill-me ENG-1234
     3. A PR number:        /grill-me 567
     4. Free-form topic:    /grill-me "move billing out of the monolith"

   Or just describe the plan in chat and call /grill-me with no args.
   ```
   Then wait.

## The Brief-then-Ask Discipline (read every invocation)

Every `AskUserQuestion` call must carry substance. Pattern:

1. **Brief** (prose in chat, immediately before the question):
   - Name the decision in full — no "the thing we discussed," no pronouns.
   - 1–3 sentences explaining *why* this question is load-bearing for the artifact.
   - State your **recommended answer** with one-line rationale, and what the alternatives trade off.
2. **Ask** (`AskUserQuestion`):
   - Option `label` is the short name of the choice.
   - Option `description` restates the choice in one line so a reader of the option list alone can decide.
   - Always include a `defer` option ("Skip — leave this open in the artifact") so grilling can end gracefully.

**Anti-patterns**: "What do you think?", "Should we do X or Y?" without context, stacking 3 questions at once, asking a thing the codebase has already answered.

## Process Steps

### Step 1: Read the artifact completely

Read the resolved artifact in full (no limit/offset). If it's a Linear ticket or PR, also read any linked research/spec/plan docs. Write down — in chat, briefly — what the artifact *claims to decide* and what it *leaves open*. This is the seed of the decision tree.

If the artifact is a tech spec produced by `/tech-spec`, note its "Open questions" and "Alternatives considered" sections verbatim; those are pre-mapped branches.

### Step 1b: Load domain priors

Before building the decision tree, load whatever domain context the repo already has. These files are conventional — written by sibling skills — and may not all exist. Skip missing ones silently; *do not* create them here.

Glob and read (in this order, deferring to whichever exists):

- `research/ubiquitous-language.md` — the canonical glossary (authored by `/ubiquitous-language`). Treat as authoritative for term meanings.
- `research/ddd/**/*.md` — Bounded Context Canvases, Aggregate Design Canvases, Core Domain Chart, Event Storming output. These define context boundaries, aggregates, and Core/Supporting/Generic classification.
- `.jeff/STORY_MAP.md` — backbone, walking skeleton, and ribs. Tells you what slice is in scope.
- `.jeff/OPPORTUNITIES.md` — the active outcome and which opportunities are live.
- `.jeff/HYPOTHESES.md` — currently-running experiments and their thresholds.

Summarize in chat, in 4–6 lines: (a) the canonical terms relevant to this artifact, (b) which bounded context / aggregate it touches and its Core/Supporting/Generic classification, (c) the active outcome or opportunity it serves, (d) any open hypothesis it would settle or invalidate. This summary becomes the **domain frame** for the grill — every question in Step 3 is asked *inside* this frame.

If none of these files exist, say so in one line ("No DDD/Jeff/glossary priors found — grilling from artifact only") and continue. Do not block the grill on missing docs.

### Step 2: Build the decision tree (subagent + main-session merge)

Spawn an `Explore` subagent with the artifact text and this prompt:

```
Read the artifact below. Identify every decision that is:
  (a) named but not resolved ("TBD", "open question", "we should decide", hand-waved tradeoffs),
  (b) *implied* but not named (load-bearing assumption presented as given),
  (c) contradicted by the current codebase (claims something exists/works a certain way — verify),
  (d) uses a term that conflicts with or is absent from the glossary at research/ubiquitous-language.md (vocabulary drift — propose the canonical term),
  (e) makes a domain claim that conflicts with a Bounded Context Canvas, Aggregate Canvas, or Core Domain Chart in research/ddd/, or contradicts an active outcome/opportunity/hypothesis in .jeff/ (strategic drift),
  (f) sits on a boundary between aggregates or bounded contexts and the artifact doesn't say which side owns it — invent one concrete scenario (a specific user action, a specific event) that forces the boundary to be precise, and make *that* the question.

For each, return:
  - decision_id (short slug)
  - parent_decision (or root) — which earlier decision it depends on
  - question (specific, one sentence)
  - codebase_answerable: true|false — can grep/read settle it without asking the user?
  - evidence (file:line references if codebase_answerable)
  - recommended_answer (best guess with one-line rationale)
  - alternatives (at most 3, with trade-off in one line each)

Order the output as a tree (parents before children). Return as JSON.

[ARTIFACT TEXT]
```

Pass the domain frame from Step 1b into the subagent prompt so it can flag (d) and (e). Merge the returned tree with any "Open questions" the artifact already lists. Deduplicate. This is **the grill list**.

Create a `TodoWrite` todo for each decision in dependency order. Mark the codebase-answerable ones with a `(code)` suffix.

### Step 3: Grill loop

Walk the list **in dependency order, one decision at a time**.

For each decision:

1. **If `codebase_answerable: true`** — answer it yourself. Read the referenced files, state the finding in chat ("Looked at `src/auth/session.ts:42` — we already enforce rotation on refresh, so this branch is closed"). Mark the todo completed. Do **not** ask.
2. **Otherwise** — Brief-then-Ask. The Brief names the decision, explains why it matters for this artifact, and states your recommended answer. The `AskUserQuestion` options are the alternatives from the tree, plus `defer` ("Skip — record as open question").
3. Record the answer against the decision_id. Mark the todo completed.

**Drift handling**: if the user's answer invalidates a parent decision, stop the walk, surface the conflict in chat, and Brief-then-Ask whether to rewind (re-open the parent) or branch (record both as contingent). Never silently carry a stale tree.

**Codebase escape hatch**: mid-grill, if a user answer suggests the codebase already speaks to a later branch, drop a quick Read/Grep before asking. Every question you don't have to ask is a win.

**Vocabulary drift handling**: for any decision flagged (d), the Brief names the conflict explicitly — *"You wrote 'account' here; the glossary defines 'Customer' for the buying party and 'User' for the login identity. Which do you mean?"* — and the recommended answer is the canonical term. Record the resolution against a `pending_glossary_updates` list (term, chosen meaning, evidence) so Step 5 can offer to fold it into `/ubiquitous-language`.

**Boundary scenarios**: for any decision flagged (f), the Brief leads with the invented scenario in 1–2 sentences, names the two candidate owners (e.g. *"BillingContext emits one event vs. OrderContext emits two"*), and the recommendation picks the side most consistent with the Bounded Context Canvas. The scenario is what makes the question grippable — never ask "who owns X" abstractly when you can ask "when Alice partially refunds order #42, which context publishes the event."

### Step 4: Summarize outcomes

After the list is exhausted, print a summary in chat:

- **Resolved** — each decision_id with the chosen answer and (if code-answered) the file:line evidence.
- **Deferred** — anything the user chose to skip, one line each with *why* (per their notes) and a suggested forcing function ("before /create-plan", "by branch cut").
- **New open questions** — anything that surfaced during grilling but wasn't in the original tree. These are often the highest-value finds.
- **Vocabulary drift found** — each (term-in-artifact → canonical-term) pair from `pending_glossary_updates`, with one-line meaning. Omit the section entirely if empty.
- **Strategic conflicts** — any (e)-flagged decisions where the artifact contradicted a DDD canvas or active Jeff hypothesis, with the canvas/hypothesis cited. Omit if empty.

### Step 5: Handoff

**Standalone invocation** (user ran `/grill-me` directly):

Brief-then-Ask for what to do with the findings:
- `append-to-artifact` → if the artifact is a readable/writable file (tech spec, plan, research doc, ticket body-as-md), append a `## Grill Outcomes (YYYY-MM-DD)` section with Resolved / Deferred / New / Vocabulary drift / Strategic conflicts. For Linear tickets, post the section as a comment via the Linear MCP. For PRs, post as a PR comment. Confirm the target path before writing.
- `save-as-research` → write `research/YYYY-MM-DD-grill-<slug>.md` containing the full summary. Use this when the input was free-form or the artifact is read-only.
- `update-glossary` → only offered when `pending_glossary_updates` is non-empty. Invokes `/ubiquitous-language` with the pending terms so the canonical glossary absorbs the resolutions. Can be combined with one of the above (do the persist first, then hand off).
- `promote-to-techspec` → only offered when at least one deferred decision is **hard-to-reverse + surprising-without-context + a real trade-off** (Matt Pocock's three-prong ADR test, adapted). Suggests invoking `/tech-spec` on that subtree to durably capture the alternatives considered. List which decision(s) qualify.
- `stop` → print the summary to chat only; do not persist.

Default recommendation: `append-to-artifact` if writable else `save-as-research`; *additionally* recommend `update-glossary` if any vocabulary drift was found.

**Orchestrated invocation** (called via `Skill(skill: "grill-me", ...)` from another skill):

Do **not** Brief-then-Ask at the end. Return a structured findings block as the skill's final output:

```
## Grill findings for <artifact>

### Resolved (N)
- decision_id — chosen: <answer> (via user | via code: <file:line> | via glossary: <term> | via canvas: <canvas-path>)

### Deferred (N)
- decision_id — reason: <one line>, forcing function: <one line>

### New open questions (N)
- decision_id — <question>, recommended: <answer>

### Vocabulary drift (N)
- artifact-term → canonical-term — meaning: <one line>

### Strategic conflicts (N)
- decision_id — conflicts with: <canvas-path or hypothesis-id>, resolution: <one line>
```

The calling skill will merge these into its artifact. Do not write files in orchestrated mode unless the caller explicitly passes an output path.

## Guidelines

1. **One question at a time.** A stack of questions flattens the decision tree; the point is to walk it.
2. **Always recommend an answer.** Silent Socratic questioning is a failure mode — the user called you because they want a collaborator, not a quizmaster.
3. **Code beats chat.** If grep can answer it, grep answers it. Announce the finding and move on.
4. **Respect dependency order.** Settling a child before its parent produces whiplash when the parent answer invalidates the child.
5. **Defer is a valid outcome.** A grill's job is to surface decisions, not force them. Recording something as an open question with a forcing function is a win.
6. **Never invent structure.** If the artifact already lists open questions, use them verbatim — don't rewrite in your own words.
7. **Orchestrated mode returns, doesn't persist.** When `/tech-spec` or `/create-plan` calls you, return findings; let the caller own the artifact.
8. **Brief-then-Ask, always.** A bare `AskUserQuestion` in this skill is a bug.
9. **Glossary is authority, not suggestion.** When `research/ubiquitous-language.md` defines a term, that's what the term means in this grill. Don't accept artifact terminology that contradicts it without flagging — vocabulary drift is the most common silent failure in a long-running project.
10. **DDD canvases beat freshly-invented architecture.** If a Bounded Context Canvas or Aggregate Canvas exists for the area, defer to it. Grilling is for what *isn't* decided yet, not for relitigating what is.
11. **Scenarios over abstractions on boundaries.** When a question touches an aggregate or context boundary, invent the concrete scenario before asking. Abstract boundary questions get abstract answers.

## Troubleshooting

- **User says "just pick whatever you recommend"** → accept it. Record each deferred decision with `chosen_by: claude` in the summary so future readers see which answers weren't user-validated.
- **Decision tree explodes (>15 items)** → Brief-then-Ask once: *grill all / grill top-N by blast radius / pick a subtree by name*. Walking 30 decisions in one session exhausts the user; better to finish a subtree cleanly.
- **User contradicts a claim in the artifact** → stop the walk, surface the contradiction, and ask whether to amend the artifact before continuing. A grill on a wrong artifact produces wrong answers.
- **Artifact is a Linear ticket with no description** → don't grill the empty body; redirect to `/improve-issue` first. A grill needs material.
- **Called as a subagent but `AskUserQuestion` is unavailable** → abort with a clear error: "grill-me requires interactive questions; call it from the main session, not from a Task subagent." This is a documented limitation.
- **Glossary contradicts itself across DDD canvases** (e.g. `research/ubiquitous-language.md` says one thing, a Bounded Context Canvas in `research/ddd/` says another) → surface the contradiction in chat, *don't* pick a side mid-grill, and recommend the user run `/ubiquitous-language` to reconcile before continuing. Per its own skill description, `/ubiquitous-language` defers to BC canvases for authoritative terms inside a context — so the canvas usually wins, but the user should confirm.
- **Domain priors are huge** (large DDD repo with dozens of canvases) → don't read them all. In Step 1b, glob the filenames first and read only the canvases for the bounded context the artifact touches. If you can't tell which context, Brief-then-Ask which one before reading.
