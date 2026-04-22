# Candidate approach generation — subagent prompts

Referenced from `SKILL.md` Step 3. Use these prompts verbatim (with placeholders filled) when spawning `Task` subagents to surface candidate approaches.

## codebase-pattern-finder

```
Task: find prior solutions to problems analogous to "<problem statement>".

Context:
- Repo: <repo name>
- Area touched: <directories / modules>
- Research doc (if any): <path>

What to do:
1. Search for patterns in this repo that solved a similar class of problem — not the same feature, but the same shape (e.g. "background job with retries", "dual-write migration", "feature-flagged rollout", "per-tenant config").
2. For each pattern found, capture: file:line reference, one-line description of the pattern, which parts are reusable vs tied to the old context.
3. Return 2-5 patterns, or explicitly state "no analogous patterns in repo" if nothing matches.

Do NOT propose a design. Just surface prior art with file:line evidence.
```

## artifacts-analyzer

```
Task: mine research/, plans/, and .jeff/ for prior decisions adjacent to "<problem statement>".

Look for:
- Prior tech specs on the same or overlapping topics (especially `research/*techspec*.md`).
- DDD artifacts that name bounded contexts / aggregates this problem lives in.
- Plans that previously touched this area — even if abandoned.
- OPPORTUNITIES.md / HYPOTHESES.md entries referencing this area.

For each relevant artifact, return: path, date, one-line relevance, and the specific decision or finding that bears on the current problem.

Do NOT synthesize. Just collect and cite.
```

## web-search-researcher (pattern) — conditional

Only spawn this if the problem has a recognizable industry pattern (event sourcing, CQRS, SAGA, strangler fig, CDC, outbox, feature flagging, blue-green deploy, ship-of-theseus migration, etc.).

```
Task: find 2-3 authoritative references for "<named pattern>" as applied to "<problem statement>".

Prefer:
- Original source material (Fowler, Vernon, engineering blogs from companies that actually shipped the pattern).
- Post-mortems or "lessons learned" posts — these surface the tradeoffs better than intro articles.
- Published within the last 5 years unless the source is canonical.

For each source, return: URL, author, one-paragraph summary of what it says, and the 1-2 concrete tradeoffs it calls out that are relevant here.

Skip vendor marketing, intro-level blog posts that only describe the pattern abstractly, and AI-generated content farms.
```

## web-search-researcher (prior art / OSS) — ALWAYS RUN

This one runs every spec. Its job is to surface "someone already built this" candidates so **adopt-don't-build** becomes a first-class candidate on the slate, not an afterthought.

```
Task: for the problem "<problem statement, ideally one sentence>", find existing OSS projects and SaaS products that solve it, plus 2-3 engineering blog posts from companies that shipped a solution at comparable scale.

Inputs:
- Problem statement (one sentence if possible): <paste>
- Problem category (named primitive): <queue / cache / search index / workflow engine / feature flags / CDC / outbox / saga / rate limiter / auth / job scheduler / pub-sub / object store / vector DB / graph DB / time-series / CRDT / event store / approval workflow / secrets manager / ...>
- Target scale: <from framing A2>
- Hard constraints: <languages, clouds, licenses we cannot use>

Searches to run:
1. Exact-quote search of the one-sentence problem statement.
2. "<category> OSS comparison 2025" / "<category> vs <category>" to surface landscape posts.
3. site:news.ycombinator.com "<category>" — postmortem / architecture threads.
4. site:github.com/topics "<category>" — top-starred repos.
5. "how <well-known company> built <category>" — engineering blog patterns from Stripe, Notion, Airbnb, Shopify, GitHub, Cloudflare, Figma, Linear, Discord, Uber, etc.

For each hit, return:
- Name + URL
- Type: OSS project | SaaS product | engineering blog post
- License (for OSS): MIT / Apache-2 / BSL / AGPL / Elastic / other — flag anything that isn't MIT/Apache without consulting
- Scale evidence: what scale did it run at? (requests/sec, data volume, org size)
- What it gives you out of the box: bullet list
- What you'd still have to build to use it (the "custom delta" from framing C4)
- Obvious gotchas from issue tracker / HN comments

Explicitly include an "Adopt <top candidate>" option as a spec approach even if you think build is better — the tech spec's job is to force the comparison, not to smuggle in a conclusion.

Do NOT recommend. Just lay out the options with evidence.
```

Merge the result into candidates at Step 4 as:
- **Adopt <name>** — use the OSS/SaaS directly; custom delta = <short list>.
- **Fork <name>** — start from the OSS codebase but own it; flag licensing implications.
- **Build inspired by <name>** — steal the design, ship our own; flag NIH risk.

These sit alongside the "build from scratch" candidates. Buy-vs-build is decided by the user at Step 5 with the tradeoffs visible.

## Synthesis checklist

After subagents return, before presenting candidates to the user:

- [ ] Are the candidates **genuinely different**? (Not 3 variations of the same idea.)
- [ ] Does each candidate have a **clear key tradeoff** distinct from the others?
- [ ] Are effort estimates based on **concrete evidence** (lines of code touched, services added, migration row counts), not vibes?
- [ ] Are risks **specific** (named failure mode, named system) or generic ("complexity")?
- [ ] Is **reversibility** stated for each — can we back out if wrong?
- [ ] Have any candidates from the pattern-finder been **ruled out** without a reason? If so, either restore or write the reason.

If any checklist item fails, loop — better candidates beat faster candidates.
