---
date: 2026-02-07T12:00:00-08:00
researcher: claude
git_commit: 51d492f7a622f889b43c765cf463ffe5c156d536
branch: main
repository: claude-agentic
topic: "Linear MCP gap analysis: current skill vs Feb 2026 announcement"
tags: [research, linear, mcp, product-management]
status: complete
last_updated: 2026-02-07
last_updated_by: claude
---

# Research: Linear Skill vs Linear MCP for Product Management Announcement

**Date**: 2026-02-07
**Researcher**: claude
**Git Commit**: 51d492f
**Branch**: main
**Repository**: claude-agentic

## Research Question

Review the linear skill and compare it against the Linear MCP announcement from 2026-02-05. What does our linear prompt support and what is it missing?

**Source**: https://linear.app/changelog/2026-02-05-linear-mcp-for-product-management

## Summary

Our `/linear` skill (`commands/linear.md`) is strong on issue/ticket lifecycle management with a 12-stage workflow, automated label assignment, comment quality guidelines, and ralph agent integration. The Feb 5 2026 Linear MCP announcement adds product management capabilities (initiatives, project milestones, project updates) that our skill does not currently address. These target a strategic planning layer above individual issues.

## Detailed Findings

### What Our Linear Skill Currently Supports

The skill at `commands/linear.md` (388 lines) uses 7 MCP tools:

| Tool | Used For |
|------|----------|
| `mcp__linear__list_teams` | Get workspace teams |
| `mcp__linear__list_projects` | List projects for a team |
| `mcp__linear__create_issue` | Create tickets |
| `mcp__linear__get_issue` | Fetch ticket details |
| `mcp__linear__update_issue` | Update properties, status, links |
| `mcp__linear__create_comment` | Add comments to tickets |
| `mcp__linear__list_issues` | Search/filter tickets |

**Key capabilities:**
- Issue CRUD with structured workflow (12 statuses from Triage → Done)
- Comment creation with quality guidelines (key insights over summaries)
- Link attachment via `links` parameter
- Automatic label assignment (hld, wui, meta, bug)
- Ticket creation from thoughts documents with interactive refinement
- Search and filtering by query, team, project, status
- Team and project listing
- Hardcoded IDs for team, labels, workflow states, and users

**Integrated workflows:**
- `ralph_research.md` — fetches tickets in "research needed" status
- `ralph_plan.md` — fetches tickets in "ready for spec" status
- `ralph_impl.md` — fetches tickets in "ready for dev" status
- `founder_mode.md` — creates tickets retroactively for experimental features

### What the Feb 5 2026 Announcement Adds

Linear expanded its MCP server with product management tools:

| New Capability | Description |
|----------------|-------------|
| **Initiatives** | Create and edit initiatives (strategic containers above projects) |
| **Initiative Updates** | Create and edit initiative status updates |
| **Project Milestones** | Create and edit milestones within projects |
| **Project Updates** | Create and edit periodic project progress reports |
| **Project Labels** | Manage project-level labels (distinct from issue labels) |
| **Image Loading** | Support for loading images in MCP context |
| **URL Resource Loading** | Load arbitrary Linear resources via URL |
| **Performance** | Reduced token usage through improved tool documentation |
| **Transport Change** | SSE deprecated; endpoint changing from `/sse` to `/mcp` (2-month rollout) |

### Gap Analysis

#### Missing from our skill — new capabilities

1. **Initiatives**: No support for creating/editing initiatives or initiative updates. These are higher-level strategic containers above projects that enable product managers to track goals.

2. **Project Milestones**: No support for creating/editing milestones within projects. Our skill assigns issues to projects but cannot manage the project's milestone structure.

3. **Project Updates**: No support for creating/editing project status updates. These are periodic progress reports on projects — useful for communicating status to stakeholders.

4. **Project Labels**: No management of project-level labels (distinct from the issue labels we do support via `labelIds`).

5. **Image Loading**: Not referenced in our skill.

6. **URL Resource Loading**: Our skill doesn't leverage the ability to load arbitrary Linear resources by URL.

#### Infrastructure concern

7. **SSE → MCP Transport**: If our MCP server config uses the old `https://mcp.linear.app/sse` endpoint, it will need updating to `https://mcp.linear.app/mcp` before the deprecation completes.

#### Already well-covered

- Issue lifecycle management (create, read, update, search)
- Comments with quality guidelines
- Status workflow with 12 stages and automated progression
- Label assignment automation
- Link management
- Integration with ralph agent pipeline (research → plan → implementation)
- Ticket creation from thoughts documents

## Code References

- `commands/linear.md` — Primary linear skill definition (388 lines)
- `commands/ralph_research.md` — Research workflow using Linear tickets
- `commands/ralph_plan.md` — Planning workflow using Linear tickets
- `commands/ralph_impl.md` — Implementation workflow using Linear tickets
- `commands/founder_mode.md` — Retroactive ticket creation
- `.claude/settings.local.json` — Local settings (MCP server config not present here)

## Open Questions

- Where is the Linear MCP server endpoint configured? Need to verify if it uses `/sse` or `/mcp` transport.
- Would initiative/milestone support be valuable for the team's workflow, or is the issue-level focus sufficient?
- Are there new MCP tool names (e.g. `mcp__linear__create_initiative`) that we should test for availability?
