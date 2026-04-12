# Linear Quality Guidelines

## Comment Quality
When creating comments, focus on the most valuable information for a human reader:
- Key insights over summaries: What's the "aha" moment?
- Decisions and tradeoffs: What approach was chosen and what it enables/prevents
- Blockers resolved: What was preventing progress and how it was addressed
- State changes: What's different now and what it means for next steps
- Surprises or discoveries: Unexpected findings that affect the work

Avoid:
- Mechanical lists of changes without context
- Restating what's obvious from code diffs
- Generic summaries that don't add value

## Example: Thoughts Document -> Ticket

### From verbose thoughts:
"I've been thinking about how our resumed sessions don't inherit permissions properly.
This is causing issues where users have to re-specify everything..."

### To concise ticket:
Title: Fix resumed sessions to inherit all configuration from parent

Description:
## Problem to solve
Currently, resumed sessions only inherit Model and WorkingDir from parent sessions,
causing all other configuration to be lost.

## Solution
Store all session configuration in the database and automatically inherit it when
resuming sessions, with support for explicit overrides.
