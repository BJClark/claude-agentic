---
topic: <short-slug>
date: YYYY-MM-DD
status: draft  # draft | approved | superseded
chosen_approach: <name>
chosen_by: user  # user | claude  (only "claude" if user said "just pick one")
ticket: <ID or null>
pr: <number or null>
research_doc: <path or null>
supersedes: <prior spec path or null>
superseded_by: <null until replaced>
amends: <prior spec path or null>
complexity: standard  # light | standard | heavy
complexity_auto: standard
complexity_overridden_by: null  # user | claude | null
critique_run: <ISO timestamp or null>
critique_findings: { blockers: 0, material: 0, polish: 0 }
critique_resolution: <one-line summary or null>
linear_synced: <ISO timestamp or null>
---

# Tech Spec: <Title>

> One-sentence elevator pitch for the chosen approach.

## Problem

One paragraph. What's broken / missing / needed and why it matters now.

## Scoping Brief

Summary of the framing questions answered (from `references/framing-questions.md`). Only include questions marked load-bearing or answered by the user — omit the noise tier.

### Engineering (Set A)
- **Success metric**: ...
- **Scale**: ...
- **SLA / SLO**: ...
- **Consistency**: ...
- **What already exists**: ...
- **Consumers**: ...
- **Scariest failure mode**: ...
- **Timeline / team**: ...
- **12–18mo evolution**: ...
- **Definition of done**: ...

### Learning posture (Set B — include only if answered)
- **Smallest learning test**: ...
- **Real user**: ...
- **Named fear**: ...
- **Simplest possible design**: ...
- **Unvalidated assumptions**: ...
- (others as relevant)

### Buy-vs-build (Set C)
- **One-sentence problem**: "..."
- **Problem category**: <named primitive>
- **Peers at our scale**: <links to 2–3 engineering blog posts>
- **Custom delta vs OSS**: <list>
- **Adopt vs build cost**: <short comparison with numbers>

## Scope

**In scope**
- ...

**Out of scope**
- ...

**Non-goals**
- things explicitly not being solved

## Constraints

- Deadline: ...
- Team / budget: ...
- Must keep working: ...
- Compliance / compatibility: ...

## Candidate approaches considered

For each candidate (2–4 of them). The chosen one is marked ✅.

### 1. <Name> ✅  *(if chosen)*

**Sketch**: one paragraph in plain terms.

**Key tradeoff**: the thing that makes it different from the others.

**Effort**: S / M / L / XL  (or weeks)

**Reversibility**: cheap / medium / hard — one line on backout.

**Risks**:
- ...
- ...

**Why (not) chosen**: one sentence.

### 2. <Name>

...

### 3. <Name>

...

## Chosen approach — high-level design

### Components
- **<name>** — what it does, 1 line.
- ...

### Data
- New entities / tables / schema shifts. Migration *shape* only (not SQL).

### Interfaces
- API / event / CLI surface changes. Named endpoints, not payloads.

### Dependencies
- New libraries, services, infra. Version constraints only if they matter.

### Rollout shape
One sentence: dark-launch / flagged / big-bang / shadow-writes / incremental cutover.

## Alternatives considered (brief rationale)

Short paragraph per rejected candidate — one sentence on why it lost. Links back to the Candidate section for detail.

## Open questions

Each must have **owner** and **forcing function** (e.g. "before Phase 2 of the plan", "before merge", "by 2026-05-01").

- [ ] Question ... — **owner**: @who — **by**: when
- [ ] ...

## Critique resolution

Populated from Step 7 (`references/critique-integration.md`). If critique was skipped, record that here with a reason.

- **Findings**: { blockers: N, material: N, polish: N }
- **Blockers**: (list with how each was resolved — addressed / overridden-with-rationale / accepted-as-tech-debt)
- **Material**: (list with how each was resolved)
- **Polish**: applied silently unless listed

## Handoff

Next step: `/create-plan <this-spec-path>`.

The plan should:
- Treat "Chosen approach — high-level design" as the target architecture.
- Turn each component/interface into phased work.
- Inherit the open questions as plan-level decisions to resolve.
