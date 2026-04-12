# Skill-to-Artifact-to-Status Map

This reference maps each skill to its output artifacts and the Linear status the ticket should advance to after that skill completes.

## Mapping

| Skill | Artifact Locations | Target Status | Comment Template |
|-------|-------------------|---------------|-----------------|
| `research-codebase` | `research/YYYY-MM-DD-*.md` (not qa-*) | Ready for Plan | Research summary + key findings |
| `create-plan` | `thoughts/shared/plans/YYYY-MM-DD-*.md`, `plans/YYYY-MM-DD-*.md` | In Plan | Plan summary + phase list |
| `implement-plan` | Plan file (updated checkboxes), code changes on branch | In Progress | Implementation progress + branch ref |
| `describe-pr` | `prs/*_description.md`, `thoughts/shared/prs/*_description.md` | In Review | PR link + summary |
| `qa` | `research/YYYY-MM-DD-qa-*.md` | Done (if all pass) or stays In Review (if failures) | QA verdict + issue list |
| `improve-issue` | (modifies ticket directly) | Ready for Research | (already synced) |
| `debug-issue` | Debug report | (no status change) | Debug findings summary |
| `ddd-*` | `research/ddd/*.md` | (no status change) | DDD artifact summary |

## Status Progression

```
Backlog -> Todo -> Ready for Research -> In Research -> Ready for Plan -> In Plan -> In Progress -> In Review -> Done
```

A skill should only advance the status forward, never backward. If the ticket is already at or past the target status, do not change it.

## Status Type Reference

- **backlog**: Backlog
- **unstarted**: Todo, Ready for Research, Ready for Plan
- **started**: In Research, In Plan, In Progress, In Review
- **completed**: Done
- **canceled**: Canceled, Duplicate

## Artifact Detection Heuristics

When auto-detecting which skill was last run (no explicit skill name provided):

1. Check files modified today (`git log --since="today" --name-only` or file modification dates)
2. Match against artifact location patterns above
3. If multiple matches, present options to user
4. If no matches, ask user which skill output to sync
