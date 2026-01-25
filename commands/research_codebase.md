---
description: Research codebase comprehensively using parallel sub-agents
model: opus
---

# Research Codebase

Conduct comprehensive research across the codebase to answer user questions by spawning parallel sub-agents and synthesizing findings.

## CRITICAL: Document What Exists

- DO NOT suggest improvements or changes unless explicitly asked
- DO NOT perform root cause analysis unless explicitly asked
- DO NOT propose enhancements unless explicitly asked
- DO NOT critique implementation or identify problems
- ONLY describe what exists, where it exists, how it works, and how components interact
- You are creating technical documentation of the existing system

## Initial Setup

When invoked:
```
I'm ready to research the codebase. Please provide your research question or area of interest, and I'll analyze it thoroughly by exploring relevant components and connections.
```

Wait for user's research query.

## Steps After Receiving Query

### 1. Read Mentioned Files First

- If user mentions files (tickets, docs, JSON), read them FULLY first
- Use Read tool WITHOUT limit/offset parameters
- Read in main context BEFORE spawning sub-tasks
- Ensure full context before decomposing research

### 2. Analyze and Decompose

- Break down query into composable research areas
- Identify components, patterns, or concepts to investigate
- Create research plan using TodoWrite
- Consider relevant directories, files, or architectural patterns

### 3. Spawn Parallel Sub-Agent Tasks

Create multiple Task agents concurrently:

**For codebase research:**
- **codebase-locator**: Find WHERE files and components live
- **codebase-analyzer**: Understand HOW code works (without critiquing)
- **codebase-pattern-finder**: Find examples of existing patterns (without evaluating)

**For documentation** (if available):
- **thoughts-locator**: Discover what documents exist about topic
- **thoughts-analyzer**: Extract key insights from relevant documents

**For web research** (only if user explicitly asks):
- **web-search-researcher**: External documentation and resources
- Instruct to return LINKS, include in final report

**For tickets** (if relevant):
- **linear-ticket-reader**: Get full ticket details
- **linear-searcher**: Find related tickets or historical context

**Key points:**
- Start with locator agents to find what exists
- Then use analyzer agents on promising findings
- Run multiple agents in parallel for different searches
- Each agent knows its job - just tell it what to find
- Remind agents they are documenting, not evaluating

### 4. Synthesize Findings

- Wait for ALL sub-agents to complete
- Compile all results
- Prioritize live codebase as primary source of truth
- Use documentation as supplementary historical context
- Connect findings across components
- Include file paths and line numbers
- Highlight patterns, connections, architectural decisions
- Answer specific questions with concrete evidence

### 5. Generate Research Document

**Filename**: `research/YYYY-MM-DD-[TICKET-ID]-description.md` or `thoughts/shared/research/YYYY-MM-DD-[TICKET-ID]-description.md`
- Format: `YYYY-MM-DD-[TICKET-ID]-description.md`
- Examples: `2025-01-08-ENG-1478-parent-child-tracking.md` or `2025-01-08-authentication-flow.md`

**Structure with YAML frontmatter**:

```markdown
---
date: [ISO format with timezone]
researcher: [Name]
git_commit: [Commit hash]
branch: [Branch name]
repository: [Repo name]
topic: "[User's Question/Topic]"
tags: [research, codebase, relevant-components]
status: complete
last_updated: [YYYY-MM-DD]
last_updated_by: [Name]
---

# Research: [User's Question/Topic]

**Date**: [Current date/time with timezone]
**Researcher**: [Name]
**Git Commit**: [Commit hash]
**Branch**: [Branch name]
**Repository**: [Repo name]

## Research Question
[Original user query]

## Summary
[High-level documentation of findings - describe what exists]

## Detailed Findings

### [Component/Area 1]
- Description of what exists ([file.ext:line](link))
- How it connects to other components
- Current implementation details (without evaluation)

### [Component/Area 2]
...

## Code References
- `path/to/file.py:123` - Description
- `another/file.ts:45-67` - Description

## Architecture Documentation
[Current patterns, conventions, design implementations found]

## Historical Context
[Relevant insights from documentation with references]
- `docs/something.md` - Historical decision about X
- `notes/exploration.md` - Past exploration of Y

## Related Research
[Links to other research documents]

## Open Questions
[Areas needing further investigation]
```

### 6. Add GitHub Permalinks (if applicable)

- Check if on main branch or commit is pushed: `git branch --show-current && git status`
- If on main/master or pushed:
  - Get repo info: `gh repo view --json owner,name`
  - Create permalinks: `https://github.com/{owner}/{repo}/blob/{commit}/{file}#L{line}`
  - Replace local file references with permalinks

### 7. Present Findings

- Present concise summary to user
- Include key file references for navigation
- Ask if they have follow-up questions

### 8. Handle Follow-up Questions

- Append to same research document
- Update frontmatter: `last_updated`, `last_updated_by`
- Add: `last_updated_note: "Added follow-up research for [description]"`
- Add section: `## Follow-up Research [timestamp]`
- Spawn new sub-agents as needed
- Continue updating document

## Important Notes

- Always use parallel Task agents for efficiency
- Always run fresh codebase research - don't rely solely on existing docs
- Focus on concrete file paths and line numbers
- Research documents should be self-contained
- Each sub-agent prompt should be specific and read-only
- Document cross-component connections
- Include temporal context (when research conducted)
- Link to GitHub when possible
- Keep main agent focused on synthesis, not deep file reading
- Have sub-agents document examples and usage patterns as they exist
- **File reading**: Always read mentioned files FULLY (no limit/offset) before spawning sub-tasks
- **Critical ordering**: Follow numbered steps exactly
  - ALWAYS read mentioned files first (step 1)
  - ALWAYS wait for all sub-agents (step 4)
  - NEVER write research document with placeholder values
- **Path handling**: For searchable directories, remove ONLY "searchable/" - preserve all other subdirectories
  - Examples: `docs/searchable/shared/notes.md` → `docs/shared/notes.md`
  - NEVER change directory structure beyond removing "searchable/"
- **Frontmatter consistency**: Use snake_case for multi-word fields (`last_updated`, `git_commit`)
