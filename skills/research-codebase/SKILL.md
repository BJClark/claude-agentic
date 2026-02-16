---
name: research-codebase
description: Research codebase comprehensively by exploring components, patterns, and connections. Document what exists without evaluation.
model: opus
context: fork
allowed-tools: Read, Grep, Glob, Bash(git *), Task, AskUserQuestion, TodoWrite
argument-hint: [research-question]
---

# Research Codebase

Research the following topic: **$ARGUMENTS**

## Current Codebase Context

- **Branch**: !`git branch --show-current`
- **Last Commit**: !`git log -1 --oneline`
- **Modified Files**: !`git status --short`
- **Repository**: !`git rev-parse --show-toplevel`

## CRITICAL: Document What Exists

- DO NOT suggest improvements or changes unless explicitly asked
- DO NOT perform root cause analysis unless explicitly asked
- DO NOT propose enhancements unless explicitly asked
- DO NOT critique implementation or identify problems
- ONLY describe what exists, where it exists, how it works, and how components interact

You are creating technical documentation of the existing system.

## Research Process

### 1. Read Mentioned Files First
If user mentions specific files, read them FULLY (no limit/offset) before proceeding.

### 2. Decompose & Plan
- Break down query into research areas using TodoWrite
- Identify components, patterns, concepts to investigate
- Consider relevant directories and architectural patterns

### 3. Spawn Parallel Sub-Agents

Use the Task tool to spawn these sub-agent types in parallel:

**Codebase Research:**
- **codebase-locator**: Find WHERE files/components live
- **codebase-analyzer**: Understand HOW code works
- **codebase-pattern-finder**: Find similar patterns/examples

**Documentation** (if available):
- **thoughts-locator**: Find relevant documents
- **thoughts-analyzer**: Extract insights

**External** (if explicitly requested):
- **web-search-researcher**: External docs/resources

Run agents in parallel when investigating independent areas.

### 4. Synthesize Findings

- Wait for ALL sub-agents to complete
- Prioritize live codebase as primary source
- Connect findings across components
- Include specific file:line references
- Document patterns and architectural decisions

### 5. Generate Research Document

Create: `research/YYYY-MM-DD-[topic].md` or `thoughts/shared/research/YYYY-MM-DD-[topic].md`

Use the template in [templates/research-doc-template.md](templates/research-doc-template.md).

Include:
- YAML frontmatter with metadata
- Research question
- Summary of findings
- Detailed component analysis with file references
- Architecture documentation
- Open questions

### 6. GitHub Permalinks (Optional)

If on main/master or pushed commit:
```bash
gh repo view --json owner,name
# Create: https://github.com/{owner}/{repo}/blob/{commit}/{file}#L{line}
```

### 7. Present & Follow-up

- Present concise summary with key file references
- Ask if follow-up questions
- For follow-ups: append to same document, update frontmatter

### 8. Link to Linear Ticket (Optional)

After presenting findings, check if the research should be attached to a Linear ticket.

**8a. Detect ticket context**: If the $ARGUMENTS mention a ticket identifier (e.g., `ENG-1234`, `PLAT-567`), use that directly. Otherwise, get the decision using AskUserQuestion:
- **Linear ticket**: Should this research be attached to a Linear ticket?
- Options should cover: Yes with a specific ticket ID (ask for it next), No thanks

**8b. If attaching to a ticket**:

1. Determine the workspace from the ticket prefix or get it using AskUserQuestion:
   - **Workspace**: Which Linear workspace?
   - Options: Stellar, Kickplan, Meerkat

2. Fetch the ticket using `mcp__mise-tools__linear_{workspace}_get_issue` to confirm it exists and get current context.

3. Compose a concise research summary comment (~10 lines max):
   ```
   ## Research: [Topic]

   **Document**: `[path to research document]`

   **Key findings**:
   - [Finding 1]
   - [Finding 2]
   - [Finding 3]

   **Open questions**: [any unresolved items, or "None"]
   ```

4. Post the comment using `mcp__mise-tools__linear_{workspace}_create_comment`.

5. If the ticket is in "Ready for Research" or "In Research" status, suggest advancing it using AskUserQuestion:
   - **Status update**: This ticket is in [current status]. Move to Ready for Plan?
   - Options should cover: Yes move to Ready for Plan, Leave status as-is

   If yes, update using `mcp__mise-tools__linear_{workspace}_update_issue` with the appropriate stateId. See [linear references](../linear/references/ids.md) for state IDs per workspace and team.

6. Confirm what was posted: show the ticket identifier and a note that the research was linked.

## Important Notes

- Always use parallel Task agents for efficiency
- Run fresh codebase research - don't rely solely on existing docs
- Focus on concrete file:line references
- Document cross-component connections
- Each sub-agent prompt should be specific and read-only
- Keep main agent focused on synthesis, not deep file reading

## Agent Team Mode (Experimental)

For complex research requiring multiple perspectives, get team mode preference using AskUserQuestion:
- **Team mode**: This research could benefit from parallel exploration. Create an agent team?
- Options should include: Agent Team with note about parallel WHERE/HOW/EXAMPLES exploration (Recommended), Single Session with note about simpler/lower cost

Tailor the recommendation based on research complexity.

**If team mode selected**, create a team with this structure:

```
Lead: Research Coordinator (you)
├─ Teammate 1: Locator — find WHERE files/components live, map directory structure
├─ Teammate 2: Analyzer — understand HOW code works, trace data flows and dependencies
└─ Teammate 3: Pattern Finder — find EXAMPLES of similar patterns, usage conventions
```

**Coordination rules:**
- All 3 teammates start simultaneously (no dependencies between them)
- Each teammate gets the research question and project context
- Give each teammate their specific lens (location vs analysis vs patterns)
- Teammates should message each other when they find cross-cutting connections
- Lead synthesizes all findings into the final research document

**Task setup:**
1. Create 3 parallel tasks, one per teammate perspective
2. Spawn teammates with specific prompts for their lens
3. When all complete, synthesize findings into `research/YYYY-MM-DD-[topic].md`
4. Cross-reference discoveries between teammates for comprehensive coverage

**After team completes**, write the research document yourself using the template and all teammate findings.

Requires: `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` in settings or environment.
