# Debug Investigation Playbook

## Parallel Investigation Tasks

Spawn parallel Task agents for these investigation streams:

**Task 1 - Check Recent Logs**: Find and analyze the most recent logs for errors, stack traces, repeated issues.

**Task 2 - Database State** (if applicable): Check schema, query recent data, look for stuck states.

**Task 3 - Git and File State**: Check status, recent commits, uncommitted changes, file permissions.

## Debug Report Template

```markdown
## Debug Report

### What's Wrong
[Clear statement based on evidence]

### Evidence Found

**From Logs**:
- [Error/warning with timestamp]

**From Database** (if checked):
- [Finding]

**From Git/Files**:
- [Recent changes that might be related]

### Root Cause
[Most likely explanation]

### Next Steps

1. **Try This First**:
   [Specific command or action]

2. **If That Doesn't Work**:
   [Alternative approach]

### Outside My Reach
- Browser console errors
- External service state
- System-level issues

Would you like me to investigate something specific further?
```

## Agent Team Mode (Experimental)

For complex bugs with unclear root cause, offer competing hypothesis investigation:

Get team mode preference using AskUserQuestion:
- **Team mode**: This bug could have multiple root causes. Investigate with competing hypotheses?
- Options should include: Competing Hypotheses with note about parallel investigation (Recommended), Single Investigation with note about simpler/lower cost

Tailor the recommendation based on bug complexity.

**If team mode selected**, first formulate 3 hypotheses based on the problem description, then create a team:

```
Lead: Debug Coordinator (you)
├─ Teammate 1: Hypothesis A investigator
├─ Teammate 2: Hypothesis B investigator
└─ Teammate 3: Hypothesis C investigator
```

**Coordination rules:**
- Each teammate investigates one hypothesis exclusively
- Teammates should actively try to **disprove** each other's theories by messaging findings
- When a teammate finds evidence, they should share it with the team so others can evaluate
- The lead monitors the debate and converges on the most supported theory
- Read-only investigation — no file editing by teammates

**Task setup:**
1. Formulate 3 distinct hypotheses about the root cause
2. Create 3 parallel investigation tasks, one per hypothesis
3. Spawn teammates, each with their hypothesis and available evidence
4. As evidence accumulates, steer the investigation toward the strongest theory

**After team completes**, synthesize the debug report with:
- Which hypothesis was confirmed/denied and why
- Supporting evidence from each investigator
- Root cause and recommended fix

Requires: `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` in settings or environment.

## Environment Checks

**Logs** (if available):
- Application logs in project-standard locations
- Check for `.log` files or `logs/` directories

**Database** (if applicable):
- SQLite databases can be queried with `sqlite3`
- Check for `.db` files in project or home directory

**Git State**:
- Current branch, recent commits, uncommitted changes

**Service Status**:
- Check running processes relevant to the project
