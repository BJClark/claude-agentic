# Framing questions — scoping brief catalog

Referenced from `SKILL.md` Step 2 ("Draft the Scoping Brief"). The subagent drafts answers where inferable from the Linear ticket / PR / research doc, and surfaces gaps for the user.

**You do not have to answer all 20 questions literally.** Use them as a checklist. The subagent's job is to triage: *which of these questions actually matter for this specific problem?* Surface the top 5–8 that would change the design if answered differently; draft answers for the rest.

Split into two sets. Both should be consulted every time.

## Set A — Engineering scoping (the "classical" 10)

For each, name it, give a one-line prompt, and the kind of answer to look for.

1. **Success metric** — *"What does success look like as a measurable outcome?"*
   Not "it works." Specific metrics: latency p50/p99, throughput, error rate, cost per request, adoption %, MTTR. If you can't name a number, the design target is undefined.

2. **Scale** — *"What's the scale, in orders of magnitude?"*
   1K users ≠ 1M users ≠ 1B events/day. Record current scale, target scale, and what blows up between them.

3. **SLA / SLO** — *"How available does this need to be? What's the downtime tolerance?"*
   99% = ~3.65 days/yr. 99.9% = ~8.76 hr/yr. 99.99% = ~52 min/yr. Each additional nine ~10× the cost. Pick honestly.

4. **Consistency requirements** — *"Can we tolerate eventual consistency, or is strong consistency non-negotiable?"*
   This single answer eliminates half the solution space. Money → strong. Activity feeds → eventual. Don't default — ask.

5. **What already exists** — *"What systems, services, or data stores do we already have that could carry this?"*
   Don't build something you own. Don't build something you could buy. Record the reuse candidates even if rejected.

6. **Consumers** — *"Who calls this? Internal teams, external customers, third parties?"*
   Drives API shape, auth model, versioning, error verbosity, rate limits, backwards-compatibility bar.

7. **Scariest failure mode** — *"What failure mode are we most afraid of? Data loss, downtime, stale reads, security breach?"*
   Name the top 1–2. The design should be paranoid about these and tolerant of the rest.

8. **Timeline and team** — *"What's the timeline and who's building it?"*
   2-week spike / 1 eng ≠ 6-month roadmap / 4 eng. Scope must fit reality. Record both.

9. **12–18 month evolution** — *"How does this change in 12–18 months? What's likely to grow, fork, or get replaced?"*
   Guards against over-engineering for hypotheticals AND under-engineering into a corner.

10. **Definition of done for THIS phase** — *"Is this an MVP, a production-hardened system, or a proof of concept?"*
    Confusing these three is how projects fail. MVP ≠ production; PoC ≠ MVP.

## Set B — Learning / design posture (the Beck-style 10)

Less about numbers, more about posture. Beck's questions push back on over-engineering and big upfront bets.

1. **Smallest learning test** — *"What's the smallest thing we could build that would teach us if we're right?"*
2. **The real user** — *"Who actually has this problem — not a persona, a named person. Can we talk to them today?"*
3. **Name the fear** — *"What are we afraid of? Fear drives over-engineering. Say it out loud."*
4. **Simplest possible design** — *"What's the simplest design that could possibly work? Not elegant. Not scalable. Simple."*
5. **Test pass criteria** — *"How will we know when this test passes?"* (Everything is a test — features, architecture, all of it.)
6. **One-week ship** — *"What would we do if we had to ship this in a week?"* Forces brutal prioritization — reveals what actually matters.
7. **Unvalidated assumptions** — *"What are we assuming that we haven't validated?"* Treat assumptions as hypotheses, not facts.
8. **Feedback loop length** — *"Can we make the feedback loop shorter? Whatever the cycle is — make it faster."*
9. **What the code wants to be** — *"What does the code want to be?"* Listen to what the design is telling you, not what you want to impose.
10. **Team health** — *"Is this making the people building it feel good?"* Sustainable pace, safety, and team health are engineering concerns too.

## Set C — Buy vs build / prior art (the 5)

Before generating candidate approaches, ask whether this problem has already been solved by the industry. Most "hard" problems are actually well-known primitives with mature OSS or SaaS.

1. **One-sentence problem** — *"Can I describe the problem in one sentence?"*
   If yes, search that sentence verbatim on Google + HN + GitHub. Mature domains have mature solutions. If you can't articulate it in one sentence, you probably haven't found the right abstraction — loop back.

2. **Problem category** — *"What category of primitive is this?"*
   Queue, cache, search index, workflow engine, feature flag system, CDC pipeline, rate limiter, auth provider, job scheduler, pub/sub, object storage, vector DB, graph DB, time-series DB, CRDT, event store, outbox, saga orchestrator, approval workflow, secrets manager. Once named, the OSS landscape is obvious.

3. **What are peers at our scale doing?** — *"What have companies at our scale already shipped for this?"*
   Hacker News + engineering blogs (Stripe, Notion, Airbnb, Shopify, GitHub, Cloudflare, Figma, Linear, Discord, etc.) + Reddit r/devops, r/programming. Postmortems and architecture posts are gold — they surface tradeoffs intro docs hide.

4. **Custom delta** — *"What would we have to build that an OSS / SaaS solution wouldn't give us?"*
   List the delta. If the custom list is **short and boring** (auth wiring, config glue, our naming) → use the OSS. If it's **long and core to the business** → that's signal to build. This is the cleanest buy-vs-build filter.

5. **Cost of adopting vs cost of building** — *"What's the total cost of adopting vs building?"*
   OSS isn't free: integration cost, ops/on-call burden, upgrade risk, licensing gotchas (AGPL, Elastic, BSL). Building has all of those **plus** initial build + ongoing maintenance of the core. Make the comparison explicit with rough numbers — not assumed.

## Triage rubric

Before presenting to the user, the subagent ranks the 20 questions by **relevance to this problem**. Rough heuristics:

- **Always load-bearing**: Success metric (A1), Scale (A2), Scariest failure mode (A7), Definition of done (A10), Unvalidated assumptions (B7).
- **Load-bearing IF the problem class matches**:
  - Data / persistence / migration → Consistency (A4), Data loss fear (A7).
  - User-facing / public API → Consumers (A6), SLO (A3).
  - New system / greenfield → What already exists (A5), Simplest design (B4), One-week ship (B6).
  - Platform / long-lived infra → 12–18mo evolution (A9), Code wants to be (B9).
- **Often decisive**: Timeline/team (A8), Smallest learning test (B1), Feedback loop (B8).
- **Situational** but cheap to ask: the rest.
- **Set C (buy-vs-build) is always relevant** — even when the answer is "build," having explicitly checked OSS/SaaS makes the spec stronger. Run it every time.

The subagent picks the top 5–8 by this rubric, drafts answers from the input context (ticket body, PR diff, research doc), and marks gaps where the user must answer.

## Output shape

The Scoping Brief the subagent returns:

```
# Scoping Brief — <topic>

## Drafted from <source> (ticket / PR / research doc):
- A1 Success metric: <draft> [confidence: high/med/low]
- A2 Scale: <draft>
- ...

## Gaps — need user input:
- A4 Consistency: <the input doesn't say; ranked load-bearing because this is a persistence change>
- B3 Fear: <no signal>
- ...

## Noise — ranked low for this problem, pre-filled with defaults (flag if wrong):
- A9 12–18mo evolution: assumed stable
- B10 Team health: assumed green
```

This is what Step 3 of SKILL.md feeds into the Brief-then-Ask confirmation turn.
