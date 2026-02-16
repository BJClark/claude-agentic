---
status: draft
source_story_map: ""
source_ddd_artifacts: []
source_opportunities: ""
source_hypotheses: ""
source_tasks: ""
workspace: ""
team: ""
counts:
  initiatives: 0
  projects: 0
  milestones: 0
  issues: 0
  labels: 0
---

# Build Plan: {product_name}

Generated from Jeff and DDD artifacts. Empty `Linear ID` columns are populated during build phase.

## Initiative

| Field | Value | Linear ID |
|-------|-------|-----------|
| Name | {initiative_name} | |
| Description | {initiative_description} | |
| Status | planned | |

## Labels

Labels derived from DDD bounded contexts. Skipped if no DDD artifacts exist.

| Label | Description | Source | Linear ID |
|-------|-------------|--------|-----------|
| {context_name} | {context_description} | DDD bounded context | |

## Projects

One project per story map release.

### Project: {release_name}

| Field | Value | Linear ID |
|-------|-------|-----------|
| Name | {release_name} | |
| Description | {release_description} | |
| Status | planned | |

#### Milestones

| Milestone | Description | Target Date | Source | Linear ID |
|-----------|-------------|-------------|--------|-----------|
| {milestone_name} | {milestone_description} | | Walking skeleton / Activity | |

#### Issues

| # | Title | Description | Activity | State | Labels | Milestone | Linear ID |
|---|-------|-------------|----------|-------|--------|-----------|-----------|
| 1 | {story_title} | {story_description} | {activity_name} | Backlog | {labels} | {milestone} | |

<!--
State assignment criteria:
- Backlog: Title only or minimal description, needs research and planning
- Todo: Has description + activity context from story map, prioritized but needs research
- Ready for Research: Has DDD enrichment + acceptance criteria from BDD tasks
-->

## Artifact Sources

| Artifact | Path | Used |
|----------|------|------|
| Story Map | .jeff/{NAME}_STORY_MAP.md | Yes/No |
| Opportunities | .jeff/OPPORTUNITIES.md | Yes/No |
| Hypotheses | .jeff/HYPOTHESES.md | Yes/No |
| BDD Tasks | .jeff/TASKS.md | Yes/No |
| DDD Alignment | research/ddd/01-alignment.md | Yes/No |
| DDD Event Catalog | research/ddd/02-event-catalog.md | Yes/No |
| DDD Sub-domains | research/ddd/03-sub-domains.md | Yes/No |
| DDD Canvases | research/ddd/06-canvases.md | Yes/No |
| User Research | .jeff/research/INSIGHTS.md | Yes/No |
