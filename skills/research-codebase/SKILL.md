---
name: research-codebase
description: Research codebase comprehensively by exploring components, patterns, and connections. Document what exists without evaluation.
model: opus
context: fork
allowed-tools: Read, Grep, Glob, Bash(git *), TodoWrite
argument-hint: [research-question]
---

# Research Codebase

Research the following topic: **$ARGUMENTS**

## Current Codebase Context

- **Branch**: !`git branch --show-current`
- **Last Commit**: !`git log -1 --oneline`
- **Modified Files**: !`git status --short | head -10`
- **Repository**: !`basename $(git rev-parse --show-toplevel)`

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

## Important Notes

- Always use parallel Task agents for efficiency
- Run fresh codebase research - don't rely solely on existing docs
- Focus on concrete file:line references
- Document cross-component connections
- Each sub-agent prompt should be specific and read-only
- Keep main agent focused on synthesis, not deep file reading

## Agent Team Mode (Experimental)

For complex research requiring multiple perspectives, you can optionally spawn an agent team:

- Lead: Research coordinator
- Teammate 1: codebase-locator (WHERE)
- Teammate 2: codebase-analyzer (HOW)
- Teammate 3: codebase-pattern-finder (EXAMPLES)
- Teammate 4: Historical context (docs/tickets)

Enable with: `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`

To use team mode, ask user first:

```
This research could benefit from parallel exploration. Create an agent team with 4 teammates?
- Yes (Faster, more thorough)
- No (Simpler, single session)
```
