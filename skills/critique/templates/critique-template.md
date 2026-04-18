---
date: <ISO-8601 timestamp>
target: <file-path | pr-url | branch-ref | approach-summary>
mode: <advise-on-file | advise-on-approach | review-pr | review-branch>
principles_version: 1
counts:
  must_fix: <N>
  should_fix: <M>
  consider: <K>
---

# Critique: <target>

## Summary

<One paragraph. What was reviewed, and the single headline finding. If there are no findings, say so plainly.>

## Strengths

- <Thing worth keeping. Prevents reviewer bias toward only-bad-news.>
- <Another, if applicable.>

## Findings

### Must-fix

- **id**: P<NN>-<short-slug>
  **location**: `path/to/file.rb:42` (or `<diff hunk>` / `<approach paragraph 2>`)
  **violation**: <1–2 sentences. What in the evidence trips this principle.>
  **desired shape**: <1–2 sentences. What "good" looks like — in prose, never as code.>

### Should-fix

- **id**: P<NN>-<short-slug>
  **location**: …
  **violation**: …
  **desired shape**: …

### Consider

- **id**: P<NN>-<short-slug>
  **location**: …
  **violation**: …
  **desired shape**: …

## Recommended next step

<One sentence. The single highest-leverage change, named — not a plan, just the headline. A downstream planning skill will expand this into a real plan.>
