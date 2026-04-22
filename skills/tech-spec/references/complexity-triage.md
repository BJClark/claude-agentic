# Complexity triage

Referenced from `SKILL.md` Step 1.5. Sizes the spec to the problem so the full heavy flow (25 framing questions, 4 parallel subagents, mandatory OSS search, mandatory `/critique`) only runs when it earns its keep.

One skill, three sizes: **Light / Standard / Heavy**. Auto-classify from the input bundle, then Brief-then-Ask to let the user override.

## Auto-classification signals

Input: the Step 1 bundle (`problem_text`, `scope_signals`, `prior_art`, plus `files_touched`, `labels`, `priority`, `size_hint`).

### Heavy (full flow)

Any ONE of these is sufficient:
- Labels contain any of: `architecture`, `migration`, `new-service`, `platform`, `cross-team`, `RFC`, `ADR`.
- Keywords in title/body: "new service", "extract", "replace", "migrate", "greenfield", "rewrite", "split the … monolith", "break up", "event-driven", "multi-tenant", "storage engine", "consistency model".
- `size_hint == XL` or Linear estimate ≥ 8 points.
- `files_touched` would span > 2 bounded contexts / top-level packages.
- Linked to a prior RFC / ADR / tech spec that this supersedes or amends.
- User explicitly said "tech spec", "design doc", "RFC", "compare approaches".

### Light (fast-path)

ALL of these must hold:
- `size_hint` in {`S`, `XS`} or Linear estimate ≤ 2 points.
- Labels contain any of: `bug`, `chore`, `ui-tweak`, `copy`, `polish`, `tiny`.
- No keywords from the Heavy list.
- No linked ADR / RFC.
- `files_touched` (if known) stays within one package / bounded context.

### Standard (default)

Everything else. Medium features, non-trivial refactors, single-context work that has real design choices but isn't architectural.

## Per-size behavior

| Step | Light | Standard | Heavy |
|---|---|---|---|
| **2. Scoping Brief** | 3 questions only: A1 success metric, A7 scariest failure, A10 definition of done. No subagent — ask the user directly in one Brief-then-Ask. | 6–8 questions from Sets A + C. Triaged by relevance. Subagent drafts, user confirms. | Full triage across A + B + C per `references/framing-questions.md`. Subagent drafts. |
| **4. Candidates** | 1 approach. Skip all subagents. If the user can't sketch a clear approach in 2 sentences, escalate to Standard. | 2 approaches. Spawn **codebase-pattern-finder** only. OSS search is optional (run only if the problem category matches a known primitive — queue, cache, search, workflow engine, feature flag, CDC, auth, scheduler, job runner, pub/sub). | 2–4 approaches. Spawn all 4 subagents in parallel (pattern-finder, artifacts-analyzer, OSS search ALWAYS, named-pattern search if applicable). |
| **5. Pick approach** | Skipped — there's one approach. Show it to the user for confirmation (Brief-then-Ask: *looks right* / *rethink* / *escalate to Standard*). | Brief-then-Ask between 2. | Full slate. |
| **6. High-level design** | 3-bullet sketch: what changes, what interfaces shift, rollout in one line. No sub-decision AskUserQuestion passes. | Components + data + interfaces + rollout. Sub-decisions via Brief-then-Ask as needed. | Full outline per SKILL.md Step 6. |
| **7. Critique** | Skipped. (User can still invoke `/critique` manually.) | Optional — Brief-then-Ask at Step 7: *run critique* / *skip*. Default is *run* if the spec has ≥ 2 approaches with a real design tradeoff. | Mandatory unless user explicitly skips. |
| **8. Artifact** | 1-page spec. Sections: Problem / Chosen approach / Open questions / Handoff. Skip Candidates-considered, Scoping Brief long form, Critique resolution if skipped. | Full template except Beck (Set B) section collapses to the 1–2 entries the user actually answered. | Full template. |
| **9. Linear sync** | Same as Standard/Heavy — mandatory when ticket detected. | Same. | Same. |
| **Typical total user turns** | 2–3 | 5–7 | 10–15 |
| **Typical wall time** | <5 min | 10–20 min | 30–60 min |

Linear sync rules (Step 9) do **not** size down. Every ticketed spec syncs.

## The Light escape hatch

At Step 1.5, if the triage returns **Light**, also offer:

- **Skip the spec entirely** → "This is small enough that a tech spec is overhead. Hand off to `/create-plan` now, or straight to `/implement-plan` if a plan already exists."

Brief-then-Ask:
- `light-spec` → "1-page spec: 3 scoping questions, 1 approach, no critique. ~5 min."
- `skip-spec` → "Skip tech-spec; invoke `/create-plan` directly (recommended for trivial work)."
- `upgrade-standard` → "I was wrong — this deserves a real spec. Go Standard."

For Standard and Heavy, offer downgrade / upgrade too:
- `downgrade-light` → "Smaller than you think; fast-path instead."
- `upgrade-heavy` → "Bigger than the signals suggest; run the full flow."

## Override recording

Whatever size runs — auto or user-chosen — record it in frontmatter:

```yaml
complexity: light | standard | heavy
complexity_auto: light | standard | heavy   # what the triage returned
complexity_overridden_by: user | claude | null
```

So reviewers can see the sizing decision.

## Guardrail

If a Light or Standard spec produces more than 2 rounds of AskUserQuestion beyond what its size budget allows, stop and offer an upgrade. Specs that sprawl beyond their size were mis-classified — the honest move is to upgrade, not grind out the cheap version.
