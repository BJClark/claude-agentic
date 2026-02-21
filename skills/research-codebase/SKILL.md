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

## Linear Ticket Detection

If the input references a Linear ticket (e.g. `ENG-1234`, `PLAT-56`, or a `thoughts/shared/tickets/*.md` file):
1. Note the ticket identifier for later use in Step 8 (automatic upload)
2. If a ticket file exists, read it fully for context
3. If only an identifier is provided, fetch ticket details using Linear MCP tools (see [Linear reference IDs](../linear/references/ids.md) for workspace and team IDs)
4. Use the ticket's title and description to inform the research question

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

### 8. Upload to Linear & Advance Status

After presenting findings, upload the research to Linear and advance the ticket status.

**If a Linear ticket was detected** (from the input):

1. Determine the workspace from the ticket identifier prefix or get it using AskUserQuestion:
   - **Workspace**: Which Linear workspace?
   - Options: Stellar, Kickplan, Meerkat

2. Use ToolSearch to load the needed MCP tools for the workspace: `get_issue`, `create_comment`, `update_issue`

3. Fetch the ticket using `mcp__mise-tools__linear_{workspace}_get_issue` to get current status and team.

4. Compose a research summary comment:
   ```
   ## Research: [Topic]

   **Document**: `[path to research document]`

   **Key findings**:
   - [Finding 1]
   - [Finding 2]
   - [Finding 3]

   **Open questions**: [any unresolved items, or "None"]
   ```

5. Post the comment using `mcp__mise-tools__linear_{workspace}_create_comment`.

6. Move the ticket to "Ready for Plan" if it's currently in an earlier state (Backlog, Todo, Ready for Research, In Research). Use the appropriate stateId from [linear references](../linear/references/ids.md) for the ticket's team and workspace. Update using `mcp__mise-tools__linear_{workspace}_update_issue`.

7. Confirm what was done:
   ```
   Linear sync complete:
   - Research comment posted to [TICKET-ID]
   - Ticket moved to "Ready for Plan"
   ```

**If no Linear ticket was detected**:

Get the decision using AskUserQuestion:
- **Linear ticket**: Should this research be attached to a Linear ticket?
- Options should cover: Yes (provide ticket ID), No thanks

If yes, follow steps 1-7 above with the provided ticket ID.

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
