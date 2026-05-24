---
name: ubiquitous-language
description: "Extract and maintain a living DDD-style domain glossary from the current conversation — opinionated canonical terms, flagged synonyms/ambiguities, example dialogue. Writes to research/ubiquitous-language.md, additive on re-run, defers to any DDD bounded-context canvases in research/ddd/ or .jeff/ rather than redefining authoritative terms. Use when names are drifting in a discussion, before /tech-spec or /create-plan to lock vocabulary, after /research-codebase to harden terminology, or any time the user mentions 'ubiquitous language', 'glossary', 'domain terms', or 'canonical names'. Triggers on 'build a glossary', 'ubiquitous language for X', 'we keep using different words for the same thing', 'harden the vocabulary'."
model: opus
user-invocable: true
allowed-tools: Read, Grep, Glob, Write, Edit, AskUserQuestion, TodoWrite
argument-hint: [optional-scope-name]
---

# Ubiquitous Language

Ultrathink about where terms are drifting. The job is not to document every noun in the conversation — it is to find the places where *the same word means two things* or *two words mean the same thing* and pin down a canonical choice. Everything else is decoration.

This skill is the **lightweight continuous glossary keeper**. It captures vocabulary drift as it happens. It does **not** replace the DDD skills — when `research/ddd/` or `.jeff/` contain authoritative bounded-context glossaries, the authoritative term wins and this glossary cross-references it rather than redefining it.

**Input**: $ARGUMENTS — optional scope name (e.g. `billing`, `auth`, `ingest`). When provided, the glossary is written under a scoped heading so multiple domains can coexist in one file. Empty means "general / current conversation."

## Current Context

- **Branch**: !`git branch --show-current`
- **Last Commit**: !`git log -1 --oneline`
- **Existing glossary**: !`ls research/ubiquitous-language.md 2>/dev/null || echo "(none yet)"`
- **DDD artifacts**: !`ls research/ddd/ 2>/dev/null | head -10 || echo "(none)"`
- **.jeff artifacts**: !`ls .jeff/ 2>/dev/null | head -10 || echo "(none)"`

## Initial Response

1. **If invoked with a scope**: begin Step 1 with `scope = $ARGUMENTS`.
2. **If invoked without a scope but the conversation has clear domain material**: begin Step 1 with `scope = general` (or, after Step 1, offer to rename).
3. **If the conversation is too thin to extract a glossary** (< ~6 domain-relevant sentences):
   ```
   I build and maintain a living domain glossary at research/ubiquitous-language.md
   from the current conversation.

   There isn't enough domain material in our chat yet. Tell me about the domain
   (the concepts, actors, lifecycle events, things that get created/moved/settled)
   and then call /ubiquitous-language — or pass a scope:

     /ubiquitous-language billing
   ```
   Then wait.

## Brief-then-Ask Discipline

Every `AskUserQuestion` in this skill must:

1. **Brief** — name the ambiguity in full, quote the conflicting usages (e.g. *"'account' was used to mean both the buyer organization and the login identity"*), and recommend a canonical choice with one-line rationale.
2. **Ask** — options are the actual candidate terms, each with a one-line description of what it would mean. Never generic yes/no.

## Process Steps

### Step 1: Load existing state

1. If `research/ubiquitous-language.md` exists, read it completely.
2. If `research/ddd/` exists, read any bounded-context-canvas / aggregate-canvas files (look for files matching `*bounded-context*`, `*aggregate*`, `*glossary*`). These carry **authoritative terms** — record them in memory as the "DDD-authoritative set."
3. If `.jeff/` exists, read `STORY_MAP.md`, `OPPORTUNITIES.md`, and `HYPOTHESES.md` if present. Names appearing repeatedly there are strong candidates for the glossary.
4. If none of the above exist, proceed silently — don't flag the absence or propose creating them.

### Step 2: Scan the conversation

Extract from the current conversation:

- **Nouns** — things created, modified, moved, counted, owned.
- **Verbs / lifecycle events** — transitions between states (e.g. *submitted*, *settled*, *fulfilled*, *voided*).
- **Actors** — people or systems that take action (e.g. *Customer*, *Reviewer*, *Scheduler*).
- **Relationships** — "an X has one/many Y", "an X produces a Y."

Skip generic programming concepts (array, function, endpoint, cache) unless they've taken on domain meaning.

Categorize each extracted term against the existing glossary + DDD-authoritative set:

- **New** — not in either source.
- **Confirmed** — matches an existing canonical term.
- **Drift** — matches an existing alias or is used in a way that conflicts with an authoritative term.
- **Ambiguity** — the same word was used for two different concepts in the conversation.
- **Synonymy** — two or more different words were used interchangeably for the same concept.

### Step 3: Resolve drift, ambiguity, synonymy

For each item in **Drift / Ambiguity / Synonymy**, Brief-then-Ask — one question per conflict, in order of blast radius (how often the term appeared in chat).

- **Drift**: *"`order` in chat seems to mean what `research/ddd/billing-bounded-context.md` calls `Purchase Request`. Recommend adopting the authoritative term `Purchase Request` and listing `order` as an alias to avoid."* Options: `adopt-authoritative`, `override-authoritative-with-reason`, `defer`.
- **Ambiguity**: *"`account` was used to mean both the buyer org (what places orders) and the login identity (what signs in). Recommend splitting into `Customer` (buyer org) and `User` (login identity)."* Options: the candidate split, a user-provided alternative via `Other`, or `defer`.
- **Synonymy**: *"`shipment`, `delivery`, and `dispatch` are all used for the same concept. Recommend `Shipment` (matches existing `research/ddd/fulfillment-bounded-context.md`)."* Options: each candidate, or `defer`.

Never autodecide a conflict — always ask. **Confirmed** and **New** terms don't require asking.

### Step 4: Write / update the glossary

Path: `research/ubiquitous-language.md` (single file, scoped by heading).

Structure (preserve existing content; update only the affected scope):

```markdown
# Ubiquitous Language

> Living domain glossary. Lightweight companion to DDD bounded-context canvases.
> When a term is defined authoritatively in `research/ddd/*` or `.jeff/*`, this file
> cross-references it rather than redefining it.

## <scope-name>

### Terms

| Term        | Definition                                  | Aliases to avoid         | Source                               |
| ----------- | ------------------------------------------- | ------------------------ | ------------------------------------ |
| **Customer** | Buyer organization that places orders      | account, client, buyer   | research/ddd/billing-bc.md (authoritative) |
| **User**    | Authentication identity in the system       | account, login           | this file                            |

### Relationships

- A **Customer** has one or more **Users**
- A **Purchase Request** belongs to exactly one **Customer**

### Example dialogue

> **Dev:** "..."
> **Domain expert:** "..."

### Flagged ambiguities

- `account` was used to mean both **Customer** and **User** — resolved 2026-04-24 as separate terms.

### History

- 2026-04-24 — initial extraction, split `account` into `Customer` / `User`, adopted `Purchase Request` from DDD canvas.
```

Rules:

1. **Opinionated** — pick one canonical term; list others as aliases. Never offer "either is fine."
2. **Tight definitions** — one sentence, what it **is** (not what it does).
3. **Source column** — either `this file` or a relative path to the authoritative DDD/jeff artifact. This is the main differentiator from a standalone glossary.
4. **Group into multiple tables only when natural clusters emerge** (by sub-scope, lifecycle, or actor). Don't force groupings.
5. **Skip module/class names** unless they carry domain meaning outside code.
6. **Example dialogue** — 3–5 exchanges showing the terms used precisely; rewrite it on each update so it incorporates new terms.
7. **Never delete history** — append to the History section; do not overwrite prior entries.

### Step 5: Summary

Print to chat:

- **Updated**: new terms added, aliases captured.
- **Resolved conflicts**: each ambiguity / synonymy resolution, one line each.
- **Deferred**: anything the user said skip on.
- **Cross-references**: any term now sourced from a DDD/jeff artifact rather than this file.

End with one-line pointer: "Glossary at `research/ubiquitous-language.md`. Re-run `/ubiquitous-language [scope]` any time the vocabulary drifts again."

## Guidelines

1. **Defer to DDD, don't compete with it.** If `research/ddd/` defines a term authoritatively, this file quotes it and links — it does not redefine.
2. **Opinionated over neutral.** Glossaries that list three equivalent names for one concept are failures; the whole point is to pick one.
3. **Flag, don't hide, conflicts.** Every ambiguity that was resolved belongs in the Flagged ambiguities section so future readers see the history.
4. **Additive on re-run.** Never drop an existing term; either confirm it or mark it as superseded with a pointer to the new term.
5. **Only domain-relevant.** "A file is a file" is not ubiquitous language. Skip it.
6. **One file, scoped by heading.** Multiple glossaries rot independently — a single durable file with sub-headings is easier to keep honest.
7. **Never autodecide a conflict.** Drift / ambiguity / synonymy each get a Brief-then-Ask. Silent resolution is how glossaries end up wrong.

## Troubleshooting

- **Conversation is a long research session with hundreds of terms** → Brief-then-Ask for scope: *"extract top-N by frequency / extract only flagged conflicts / extract everything"*. Default top-N.
- **DDD artifact says one thing, user says another in chat** → surface as Drift and ask explicitly: *"Override the authoritative definition, or adopt it here?"*. If override, record the reason in History.
- **Two scopes overlap (same term means different things in billing vs. ingest)** → keep both, each under its own scope heading. Mention the collision in Flagged ambiguities under both scopes.
- **User asks for a different output path** → honor it and record the chosen path in History. Prefer `research/` over `thoughts/shared/` — glossaries are durable.
