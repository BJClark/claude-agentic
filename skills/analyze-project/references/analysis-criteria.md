# Project Analysis Criteria

## Story Assessment Checklist

Evaluate every story against this project-level checklist:

| Criterion | What to look for |
|-----------|-----------------|
| **Problem statement** | Clear description of what this story addresses and why it matters for the project |
| **Acceptance criteria** | How do we know this story is done? What does success look like? |
| **Scope clarity** | Is it clear what's in and out of scope for this story? |
| **Dependencies** | Are upstream/downstream dependencies on other stories or projects identified? |
| **Fits the narrative** | Does this story clearly contribute to getting from start state to end state? |

Classify each story:
- **Ready** — clear enough for an engineer to begin research
- **Needs improvement** — has specific, identifiable gaps
- **Unclear** — fundamentally unclear purpose or scope within the project

## Gap Analysis Dimensions

With the full picture of all stories and the confirmed scope, identify:

1. **Missing stories** — work needed to get from start state to end state that no existing story covers. Think about what an engineer would need to build that isn't captured.
2. **Overlap** — stories that seem to duplicate effort or cover the same ground
3. **Ordering concerns** — stories that imply a sequence but don't express dependencies
4. **Scope creep** — stories that don't clearly serve the project's end state
5. **Cross-project gaps** — work that falls between this project and sibling projects in the initiative

## Triage Report Template

```
## Project Triage Report

### Scope
**Start state**: [what exists today]
**End state**: [what the project delivers]

### Story Assessment

**Ready** ([N] stories):
- [ID] — [Title]

**Needs Improvement** ([N] stories):
| Story | Issues |
|-------|--------|
| [ID] — [Title] | [specific gaps: missing AC, unclear scope, etc.] |

**Unclear** ([N] stories):
| Story | Issues |
|-------|--------|
| [ID] — [Title] | [why it's unclear] |

### Gaps Identified
1. **[Gap name]** — [description of missing work]
2. **[Gap name]** — [description of missing work]

### Overlaps & Concerns
- [Any overlaps, ordering issues, scope creep, cross-project gaps]

### Proposed Actions
- Improve [N] existing stories (fill gaps in descriptions/AC)
- Create [N] new stories (cover identified gaps)
- Flag [N] stories for discussion (unclear purpose or possible scope creep)
```

## Story Improvement Process

### Improving Existing Stories

For stories classified as "Needs improvement":

1. Draft the updated description for each story, filling identified gaps
2. Present changes in batches of up to 5 stories
3. Get batch approval using AskUserQuestion:
   - **Batch [N]**: Apply these updates?
   - Options should cover: Apply all, Skip some, Edit before applying
4. For approved updates:
   - Fetch current description via `get_issue`
   - Append new sections (never overwrite original content)
   - Update via `update_issue`
   - Add comment: "Story enriched during project analysis: [brief note of what was added]"
5. Report progress every 5 items

### Creating New Stories

For gaps that need new stories:

1. Draft each new story with: Title, Description with problem statement, Acceptance criteria, Workstream, Why it's needed
2. Present all new stories for approval
3. Get approval using AskUserQuestion:
   - **New stories**: Create these stories?
   - Options should cover: Create all, Let me pick which ones, Edit before creating
4. Create approved stories via `create_issue` with the project's team ID, appropriate labels, and project link

### Handling Flagged Stories

For stories flagged for discussion, present each and get a decision using AskUserQuestion:
- **[ID] — [Title]**: This story [reason for flag]. What should we do?
- Options should cover: Keep as-is, Rewrite it, Remove from project, Merge with another story

## Status Transition

After all improvements:

1. Fetch the current list of all stories in the project (including newly created ones)
2. Identify which stories are NOT already at or past "Ready for Research"
3. Look up the correct "Ready for Research" state ID from `skills/linear/references/ids.md`
4. Present the transition plan and get confirmation using AskUserQuestion
5. Execute approved transitions via `update_issue`
