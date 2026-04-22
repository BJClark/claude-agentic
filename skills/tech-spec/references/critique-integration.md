# Critique integration

Referenced from `SKILL.md` Step 7 ("Self-critique"). Before the Tech Spec artifact is written, the draft goes through `/critique` so obvious issues don't ship into the durable artifact.

## When to run

- **Always** run critique after Step 6 (High-level design) and before Step 8 (Write artifact).
- **Skip only if**: the user explicitly says "skip critique" at the Step 7 Brief-then-Ask, OR the spec has fewer than two candidate approaches and a 1-paragraph chosen design (nothing substantial to critique).

## How to invoke

Use the `Skill` tool:

```
Skill(skill: "critique", args: "<path-or-inline>")
```

Two calling modes:

### Mode A — inline (preferred for drafts)

Draft the spec content in memory (not yet written to disk). Compose a single string containing:

```
# Draft Tech Spec: <title>

<all sections: Problem, Scope, Constraints, Candidate approaches, Chosen approach, High-level design, Open questions>
```

Invoke `critique` with this string as the argument. It will return a structured report of principle-level findings (convention, domain language, DDD, structure, coupling, testing, etc. — 31 principles per the skill).

### Mode B — file (if the draft is long or binary-ish)

Write the draft to a temp path under `thoughts/shared/` first, then pass the path to critique. Delete the temp file after the critique report is consumed and accepted changes applied.

## Interpreting critique output

`/critique` returns findings ranked by severity. Classify each:

- **Blocker** — design-level issue that invalidates the chosen approach (e.g. "this violates the tenancy boundary that ADR-007 established", "this aggregates two bounded contexts that must stay separate"). **Must** be surfaced to the user — do not silently apply.
- **Material** — would change the spec content if accepted (e.g. "you named a component 'Manager' — name it by its responsibility", "consistency requirement is under-specified").
- **Polish** — wording, formatting, cross-ref links. Apply silently.

## Brief-then-Ask at Step 7

After critique returns, follow the Context Principle:

**Brief** (prose):
> Critique flagged **N findings** on the draft spec. Here they are, grouped by how much they'd change the spec:
>
> **Blockers (1)** — these challenge the chosen approach:
> - *[C1]* The chosen approach dual-writes to the `billing` and `invoicing` stores, but ADR-007 (Nov 2025) established that cross-boundary writes must go through the outbox. → Either switch to the outbox pattern (re-run Step 4), or document why this spec overrides ADR-007.
>
> **Material (3)** — would change spec content:
> - *[M1]* Success metric A1 is "improve performance" — not measurable. Needs a number (p99 target or %-reduction).
> - *[M2]* Component "SessionManager" — rename to its responsibility (e.g. "SessionRenewer" if it refreshes sessions, "SessionStore" if it persists them).
> - *[M3]* Rollout shape says "incremental" but doesn't name the shard / cohort / flag mechanism.
>
> **Polish (5)** — wording and link fixes; I'll apply these silently if you don't object.

**Ask** (`AskUserQuestion`):
- Option `address-all` → "Address blockers + material findings before writing the spec; apply polish silently"
- Option `address-blockers-only` → "Address blockers; defer material findings to the Open Questions section; apply polish silently"
- Option `skip-critique` → "Write the spec as-is; record critique findings verbatim in an Appendix for later"
- Option `rewind-to-step-4` → "Critique broke the approach — re-pick an approach from scratch"

## What "address" means

- **Blocker addressed by rewinding**: go back to Step 4 (pick approach) with the critique context added to the Brief.
- **Blocker addressed by overriding**: add an explicit "Deviates from <ADR / precedent>" section to the spec with the user's stated reason.
- **Material addressed**: edit the in-memory draft before Step 8 writes it.
- **Polish addressed**: apply inline; no user surface.

## Loop guard

If a second critique pass after address-all still returns blockers, **stop applying automatically** — surface to the user via Brief-then-Ask with options: *deviate from the principle (document it)* / *rewind further* / *accept the blocker as known tech debt*. Never infinite-loop between draft → critique → fix → critique.

## Artifact trace

The final Tech Spec's frontmatter should include:

```yaml
critique_run: 2026-04-21T14:33:00
critique_findings: { blockers: 1, material: 3, polish: 5 }
critique_resolution: "blockers addressed by rewinding to Step 4; M1–M3 applied; polish applied silently"
```

So a reader can see the spec went through critique and understand what was resolved.
