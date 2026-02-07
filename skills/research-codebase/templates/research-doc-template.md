---
date: [ISO format with timezone - e.g., 2025-02-07T10:30:00-08:00]
researcher: [Your name]
git_commit: [Commit hash from `git rev-parse HEAD`]
branch: [Branch name from `git branch --show-current`]
repository: [Repository name]
topic: "[Research Question/Topic]"
tags: [research, codebase, relevant-component-names]
status: complete
last_updated: [YYYY-MM-DD]
last_updated_by: [Your name]
---

# Research: [Research Question/Topic]

**Date**: [Current date/time with timezone]
**Researcher**: [Your name]
**Git Commit**: [Commit hash]
**Branch**: [Branch name]
**Repository**: [Repository name]

## Research Question

[Original user query - be specific]

## Summary

[2-3 paragraph high-level overview of findings]

Key discoveries:
- [Major finding 1]
- [Major finding 2]
- [Major finding 3]

## Detailed Findings

### [Component/Area 1]

**Location**: `path/to/file.ext:123-145`

**Purpose**: [What this component does]

**Implementation Details**:
- [Detail 1 with file:line reference]
- [Detail 2 with file:line reference]

**Connections**:
- Calls: `other/component.ext:67`
- Called by: `consumer/code.ext:34`
- Dependencies: [List key dependencies]

### [Component/Area 2]

[Similar structure...]

## Code References

Quick reference index of key files:

- `path/to/main-file.py:123` - Primary entry point
- `path/to/handler.py:45-67` - Core business logic
- `path/to/helper.ts:89` - Utility function
- `path/to/config.json` - Configuration

## Architecture Documentation

### Patterns Used

- **Pattern 1**: [Description with examples]
- **Pattern 2**: [Description with examples]

### Data Flow

```
Entry Point → Processing → Storage → Response
[file:line] → [file:line] → [file:line] → [file:line]
```

### Key Design Decisions

1. **[Decision 1]**: [Rationale found in code/comments]
2. **[Decision 2]**: [Rationale found in code/comments]

## Historical Context

[If relevant documents/tickets exist, reference them]

- `docs/adr/001-decision.md` - Architectural decision about X
- `notes/spike-report.md` - Exploration of Y approach
- Linear ticket ENG-123 - Original requirement

## Related Research

[Links to other research documents in this repository]

- `research/2025-01-15-related-topic.md`
- `thoughts/shared/research/2024-12-01-background.md`

## Open Questions

[Areas that need further investigation or couldn't be answered]

1. **[Question 1]**: [Why it couldn't be answered yet]
2. **[Question 2]**: [What additional research is needed]

## Follow-up Research [Timestamp]

[If follow-up research added later, use this section]

**Added**: [Date/time]
**Question**: [Follow-up question]

[Findings...]
