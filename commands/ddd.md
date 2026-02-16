---
description: Start or resume the DDD domain discovery workflow
---

Check for existing DDD artifacts at `research/ddd/0*.md` using Glob.

**If artifacts exist**, show the user what's already done:

```
Found existing DDD artifacts:
- research/ddd/01-alignment.md ✓
- research/ddd/02-event-catalog.md ✓
- (etc.)

Next incomplete step: Step N ([step name])
```

Then ask: "Resume from Step N, or start fresh?"

**Spawn the `ddd-architect` agent** with:
- Any file path or arguments the user provided
- If resuming, tell the agent which step to resume from
- If starting fresh, pass the PRD path
