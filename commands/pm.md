---
description: Start or resume the PM workspace build workflow
---

Check for existing artifacts using Glob:
- `.jeff/*STORY_MAP*.md` — story map (required)
- `research/pm/build-plan.md` — existing build plan (resume candidate)
- `research/ddd/0*.md` — DDD artifacts (optional enrichment)

**If a build plan exists**, read its YAML frontmatter to check status:

```
Found existing build plan:
- research/pm/build-plan.md (status: {status})
- {n} issues, {m} with Linear IDs

Story map: .jeff/{NAME}_STORY_MAP.md ✓
DDD artifacts: {count} found
```

Then ask: "Resume building, re-synthesize, or review the plan?"

**If no build plan but story map exists**:

```
Found artifacts:
- Story map: .jeff/{NAME}_STORY_MAP.md ✓
- DDD artifacts: {count} found
- No existing build plan

Ready to synthesize a Linear build plan from these artifacts.
```

**If no story map found**:

```
No story map found in .jeff/. Run /jeff-map first to create one.
```

Then stop.

**Spawn the `pm-architect` agent** with:
- Story map path
- Whether resuming from an existing build plan
- Any file path or arguments the user provided
