# Interface Design

When the user wants to explore alternative interfaces for a chosen deepening candidate, use this parallel subagent pattern. Based on "Design It Twice" (Ousterhout) — your first idea is unlikely to be the best.

Uses the vocabulary in [LANGUAGE.md](LANGUAGE.md) — **module**, **interface**, **seam**, **adapter**, **leverage**, **depth**.

## When to invoke

From the main SKILL.md Step 4.5 only, and only after `/grill-me` has surfaced ≥2 real open questions about the interface shape. If grill-me closed out clean, the grilled interface is the answer — don't run this step for ceremony.

## Process

### 1. Frame the problem space

Before spawning subagents, write a user-facing explanation of the problem space for the chosen candidate:

- The constraints any new interface would need to satisfy (from the grill outcomes).
- The dependencies it would rely on, and which category they fall into (see [DEEPENING.md](DEEPENING.md)).
- A rough illustrative sketch (pseudocode or type stubs) to ground the constraints — not a proposal, just a way to make the constraints concrete.
- Any bounded-context or `research/ddd/` constraints that bind the interface.

Show this to the user, then immediately proceed to Step 2. The user reads and thinks while the subagents work in parallel.

### 2. Spawn subagents

Spawn exactly 3 subagents in parallel using the `Task` tool (4 only when dependency category is 3 or 4, per Agent 4 below) (`subagent_type: general-purpose` or `subagent_type: Plan`, per the design brief's shape). Each must produce a **radically different** interface for the deepened module.

Prompt each subagent with a separate technical brief (file paths, coupling details, dependency category from DEEPENING.md, what sits behind the seam). The brief is independent of the user-facing problem-space explanation in Step 1. Give each agent a different design constraint:

- **Agent 1** — *"Minimize the interface — aim for 1–3 entry points max. Maximise leverage per entry point. Callers may pay for flexibility by constructing richer inputs."*
- **Agent 2** — *"Maximise flexibility — support many use cases and extension. Accept that the interface is broader; justify every added entry point by a concrete caller."*
- **Agent 3** — *"Optimise for the most common caller — make the default case trivial. Advanced cases may require additional ceremony."*
- **Agent 4** (only when dependency category is 3 or 4) — *"Design around ports & adapters for the cross-seam dependency. Interface on our side of the port must be technology-agnostic."*

Each subagent's brief must include:
- The deep module's name (from the domain glossary at `research/ubiquitous-language.md`).
- The relevant `LANGUAGE.md` terms.
- The relevant `DEEPENING.md` dependency category.
- The grill outcomes (Resolved / Deferred / New) as context — so the subagent knows which constraints are firm vs open.
- An instruction to use the ubiquitous-language and LANGUAGE.md vocabulary verbatim in the output.

Each subagent outputs:

1. **Interface** (types, methods, params — plus invariants, ordering, error modes).
2. **Usage example** showing how the most common caller uses it, in pseudocode.
3. **What the implementation hides behind the seam** — bullet list.
4. **Dependency strategy and adapters** (see [DEEPENING.md](DEEPENING.md)).
5. **Trade-offs** — where leverage is high, where it's thin, what callers pay for the choice.
6. **What it rejects** — the other constraints it deliberately deprioritized.

### 3. Present and compare

Present designs **sequentially** so the user can absorb each one, then compare them in prose. Contrast by:

- **Depth** — leverage at the interface. Which design asks callers to learn the least per unit of behaviour?
- **Locality** — where change concentrates. Which design keeps the most maintenance in one place?
- **Seam placement** — at the module edge vs. inside the implementation. Which design matches the dependency category?
- **Risk** — what's most likely to go wrong, including "interface feels right but the implementation is undefined."

After comparing, give your own **opinionated recommendation** — which design you think is strongest and why. If elements from different designs would combine well, propose a hybrid (name the elements explicitly; don't hand-wave).

### 4. Brief-then-Ask to pick

- **Brief**: summarize the three-way comparison in one paragraph and restate your recommendation with one-line rationale.
- `AskUserQuestion` options: one per design (`label` = short name, `description` = the key trade-off), plus `hybrid-<A>+<B>` if you proposed one, plus `none-want-more` (loops back to Step 2 with different constraints).

Record the chosen interface in the ticket body produced by SKILL.md Step 6. The ticket should include:
- The chosen interface (signature + invariants).
- Why it beat the alternatives (one line each, from your comparison).
- What the implementation hides (from the winning subagent's output).

## Discipline

- **Three genuinely different designs, not three flavours of one.** If two of your subagents return near-identical interfaces, re-prompt with sharper constraints.
- **Be opinionated at Step 3.** The user wants a strong read, not a menu. Recommend one.
- **Don't over-run this step.** Two rounds of "design it twice" means the problem isn't ready for a ticket — kick it to `/tech-spec`.
- **Ground every design in `LANGUAGE.md` and the domain glossary.** A design that uses "boundary," "service," or a name absent from `research/ubiquitous-language.md` is a rewrite, not a design.
