---
name: pm-synthesize
description: "Synthesize Jeff and DDD artifacts into a Linear build plan. Use when you have a story map and want to generate a structured plan for bulk Linear creation."
model: opus
context: fork
allowed-tools: Read, Grep, Glob, Write, Edit, AskUserQuestion, Task
argument-hint: [story-map-path]
---

# PM Synthesize: Artifacts to Build Plan

Ultrathink about how the story map structure maps to Linear's hierarchy. Consider how DDD artifacts enrich the stories with bounded context labels and domain language. Think about which stories have enough detail for which workflow states.

Reads Jeff product discovery artifacts and optional DDD domain artifacts, then produces a machine-readable build plan at `research/pm/build-plan.md` for the pm-architect agent to execute against Linear.

**Input**: $ARGUMENTS

## Current Context

- **Branch**: !`git branch --show-current`
- **Last Commit**: !`git log -1 --oneline`

## Initial Response

1. **If a story map path is provided**: Read it and begin synthesis
2. **If no parameters**: Glob for `.jeff/*STORY_MAP*.md` and present what's found
3. **If no story map exists**: Tell the user to run `/jeff-map` first and stop

## Process Steps

### Step 1: Discover Artifacts

Glob for all potential source artifacts:

```
.jeff/*STORY_MAP*.md          (required — primary driver)
.jeff/OPPORTUNITIES.md        (optional — enrichment)
.jeff/HYPOTHESES.md           (optional — enrichment)
.jeff/TASKS.md                (optional — BDD acceptance criteria)
.jeff/research/INSIGHTS.md    (optional — user research context)
.jeff/config.yaml             (optional — project name)
research/ddd/01-alignment.md  (optional — domain context)
research/ddd/02-event-catalog.md (optional — domain events)
research/ddd/03-sub-domains.md   (optional — bounded contexts for labels)
research/ddd/06-canvases.md      (optional — aggregate details)
```

Read every artifact that exists. Present a discovery summary:

```
## Artifact Discovery

| Artifact | Status | Impact |
|----------|--------|--------|
| Story Map | Found: .jeff/MUX_STORY_MAP.md | Primary structure |
| Opportunities | Found | Enriches descriptions |
| BDD Tasks | Not found | No acceptance criteria available |
| DDD Alignment | Found | Domain language enrichment |
| DDD Sub-domains | Found | Labels from bounded contexts |
| ... | ... | ... |
```

### Step 2: Parse Story Map Structure

Extract the hierarchical structure from the story map:

1. **Product name**: From `config.yaml` `project_name` or the story map `# Story Map: {name}` heading
2. **Backbone activities**: Column headers from the `## Backbone` table
3. **Walking skeleton stories**: Rows from the `## Walking Skeleton` table, mapped to their backbone activity
4. **Release stories**: Rows from each `### Release N` table under `## Ribs`, mapped to their backbone activity
5. **Future stories**: Rows from `### Future` section

Build the mapping:

```
Initiative: {product_name}
├── Project: Walking Skeleton (MVP)
│   ├── Milestone: {activity_1} MVP
│   │   └── Issues: walking skeleton stories for activity_1
│   └── Milestone: {activity_2} MVP
│       └── Issues: walking skeleton stories for activity_2
├── Project: Release 1
│   └── Issues: release 1 stories grouped by activity
├── Project: Release 2
│   └── Issues: release 2 stories grouped by activity
└── Project: Future
    └── Issues: future stories
```

### Step 3: Enrich with DDD (if available)

If DDD artifacts exist:

1. **Labels from bounded contexts**: Read `research/ddd/03-sub-domains.md` for sub-domain/bounded context names. Each becomes a label candidate.
2. **Domain language**: Read `research/ddd/01-alignment.md` for ubiquitous language terms. Use these for consistent naming in issue titles and descriptions.
3. **Event context**: Read `research/ddd/02-event-catalog.md` for domain events related to each story. Add relevant events to issue descriptions as technical context.
4. **Aggregate details**: Read `research/ddd/06-canvases.md` for aggregate design details. Reference in issue descriptions where relevant.

Map each story to its most relevant bounded context(s) for label assignment.

### Step 4: Enrich with BDD Tasks (if available)

If `.jeff/TASKS.md` exists:

1. Match BDD tasks to stories by their `Source: STORY_MAP.md > [Activity] > [Story]` reference
2. Extract acceptance criteria checkboxes from matched tasks
3. Append acceptance criteria to the issue description
4. Stories with BDD acceptance criteria get elevated to "Ready for Research" state

### Step 5: Enrich with Opportunities and Research (if available)

If `.jeff/OPPORTUNITIES.md` exists:
- Link opportunities to related stories in descriptions
- Add opportunity context ("supports opportunity: reduce onboarding friction")

If `.jeff/research/INSIGHTS.md` exists:
- Add user research context to relevant stories
- Reference specific insights that motivate the story

### Step 6: Assign Workflow States

For each issue, assign an initial workflow state based on detail richness:

| Detail Level | State | Criteria |
|---|---|---|
| Minimal | **Backlog** | Title only, or title + brief description. No acceptance criteria, no DDD context. |
| Moderate | **Todo** | Description with activity context from story map. May have opportunity linkage. No acceptance criteria. |
| Rich | **Ready for Research** | Has DDD enrichment (bounded context label, domain events) AND acceptance criteria from BDD tasks. Enough context to begin investigation. |

### Step 7: Interactive Review

Present the proposed hierarchy to the user for review.

Get synthesis feedback using AskUserQuestion:
- **Build plan review**: Does this hierarchy look correct?
- Options should cover: Looks good — write the build plan, Needs adjustments (I'll describe), Show me more detail on a specific section
- Tailor based on complexity of what was found

If adjustments needed, iterate until the user approves.

### Step 8: Write Build Plan

Create `research/pm/` directory if needed, then write `research/pm/build-plan.md` using the template structure from `skills/pm-synthesize/templates/build-plan-template.md`.

The build plan must include:

1. **YAML frontmatter** with source paths, counts, and status
2. **Initiative section** with product name and description
3. **Labels section** (from DDD bounded contexts, empty if no DDD)
4. **Projects section** — one per release, each containing:
   - Project metadata
   - Milestones table (walking skeleton milestones in MVP project, activity-based in others)
   - Issues table with columns: #, Title, Description, Activity, State, Labels, Milestone, Linear ID
5. **Artifact Sources section** listing all artifacts and whether they were used

Descriptions should be Linear-markdown formatted (headers, bullets, bold).

After writing, confirm:

```
Build plan written to `research/pm/build-plan.md`

Summary:
- 1 initiative: {name}
- {n} labels from DDD bounded contexts
- {n} projects (releases)
- {n} milestones
- {n} issues ({x} Backlog, {y} Todo, {z} Ready for Research)

Ready for the pm-architect agent to build in Linear.
```

## Guidelines

1. **Story map is the structural backbone**: Everything else enriches it
2. **DDD is optional enrichment**: The plan must work without DDD artifacts
3. **Preserve story map language**: Use the user's words from the story map, enriched with ubiquitous language from DDD
4. **One project per release**: Walking skeleton gets its own project, each numbered release gets one, future gets one
5. **Milestones are activity-scoped**: Within the MVP project, each backbone activity with walking skeleton stories gets a milestone
6. **State assignment is conservative**: When in doubt, use Backlog — it's better to start low than skip needed research
7. **Descriptions are rich**: Include activity context, DDD enrichment, acceptance criteria, and opportunity linkage — everything the engineer needs
8. **Machine-readable output**: The build plan must be parseable by the pm-architect agent — use consistent table formatting
