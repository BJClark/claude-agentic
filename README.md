# Claude Agentic Commands & Agents

A collection of specialized commands and agents for Claude to help with software development workflows including planning, research, implementation, and PR management.

## Overview

This toolkit provides:
- **Commands**: Interactive workflows for planning, research, debugging, and PR management
- **Agents**: Specialized sub-agents for codebase analysis, pattern finding, and web research

## Installation

### Claude Code (CLI)

Claude Code uses a `.claude/` directory for commands and agents.

```bash
# Clone the repository
git clone https://github.com/your-org/claude-agentic.git

# Copy to your project
mkdir -p .claude
cp -r claude-agentic/agents .claude/
cp -r claude-agentic/commands .claude/
```

Or install globally for all projects:

```bash
mkdir -p ~/.claude
cp -r claude-agentic/agents ~/.claude/
cp -r claude-agentic/commands ~/.claude/
```

Commands are available immediately - use `/create_plan`, `/research_codebase`, etc.

### Cursor

Cursor uses a `.cursor/` directory for custom prompts and rules.

```bash
# Clone the repository
git clone https://github.com/your-org/claude-agentic.git

# Copy to your project's Cursor directory
mkdir -p .cursor/prompts
cp -r claude-agentic/commands/* .cursor/prompts/
cp -r claude-agentic/agents/* .cursor/prompts/
```

Then in Cursor:
1. Open Command Palette (`Cmd+Shift+P` / `Ctrl+Shift+P`)
2. Search for prompts by name (e.g., "create_plan")
3. Or reference them in chat with `@prompts`

### Zed

Zed supports custom prompts in its configuration directory.

```bash
# Clone the repository
git clone https://github.com/your-org/claude-agentic.git

# Copy to Zed's prompt library
mkdir -p ~/.config/zed/prompts
cp -r claude-agentic/commands/* ~/.config/zed/prompts/
cp -r claude-agentic/agents/* ~/.config/zed/prompts/
```

Access prompts via the Assistant panel's prompt library (`/` in chat).

### Opencode

Opencode uses a `.opencode/` directory for agents and customization.

```bash
# Clone the repository
git clone https://github.com/your-org/claude-agentic.git

# Copy to your project
mkdir -p .opencode/agents
cp -r claude-agentic/agents/* .opencode/agents/
cp -r claude-agentic/commands/* .opencode/agents/
```

Or configure globally in `~/.config/opencode/agents/`.

Commands are available as `/command_name` in the Opencode interface.

### Conductor

Conductor loads agents from the `.conductor/` directory.

```bash
# Clone the repository
git clone https://github.com/your-org/claude-agentic.git

# Copy to your project
mkdir -p .conductor/agents .conductor/commands
cp -r claude-agentic/agents/* .conductor/agents/
cp -r claude-agentic/commands/* .conductor/commands/
```

Agents and commands are automatically discovered on startup.

### Verification

After installation, verify commands are available:

```
/create_plan - Create implementation plans
/research_codebase - Research how code works
/describe_pr - Generate PR descriptions
```

If commands don't appear, restart your editor/CLI to reload configurations.

## Available Commands

### Planning & Design
- **`/create_plan`** - Create detailed implementation plans through interactive research
- **`/iterate_plan`** - Update existing implementation plans based on feedback
- **`/validate_plan`** - Validate implementation plans against codebase reality

### DDD Discovery-to-Implementation
- **`/ddd_full`** - Complete end-to-end DDD workflow (all 7 steps with confirmation gates)
- **`/ddd_align`** - Step 1: Align & understand the business domain from a PRD
- **`/ddd_discover`** - Step 2: EventStorming — discover events, commands, actors, policies
- **`/ddd_decompose`** - Step 3: Decompose domain into sub-domains and bounded contexts
- **`/ddd_strategize`** - Step 4: Classify sub-domains on Core Domain Chart
- **`/ddd_connect`** - Step 5: Context mapping — define relationships between contexts
- **`/ddd_define`** - Step 7: Build Bounded Context and Aggregate Design Canvases
- **`/ddd_plan`** - Step 8: Convert DDD artifacts into `/implement_plan`-compatible plans

### Research & Analysis
- **`/research_codebase`** - Comprehensively research codebase using parallel agents
- **`/debug`** - Debug issues with systematic investigation

### Implementation & Review
- **`/implement_plan`** - Execute implementation plans step by step
- **`/local_review`** - Review code changes before committing
- **`/describe_pr`** - Generate comprehensive PR descriptions

### Git Workflows
- **`/commit`** - Create well-formatted git commits with co-authorship
- **`/ci_commit`** - Commit changes in CI/CD environments
- **`/create_worktree`** - Create and manage git worktrees

### Handoff & Collaboration
- **`/create_handoff`** - Create handoff documents for async collaboration
- **`/resume_handoff`** - Resume work from handoff documents

### Project-Specific (Optional)
- **`/linear`** - Manage Linear tickets (requires Linear MCP integration)

## Available Agents

These specialized agents are used by commands (or can be invoked directly):

### Codebase Analysis
- **`codebase-analyzer`** - Analyzes HOW code works, traces data flow
- **`codebase-locator`** - Finds WHERE code lives in the codebase
- **`codebase-pattern-finder`** - Finds similar implementations and patterns

### DDD Discovery
- **`ddd-event-discoverer`** - Extracts domain building blocks (events, commands, actors, policies) from requirements
- **`ddd-context-analyzer`** - Identifies bounded context boundaries from language patterns
- **`ddd-canvas-builder`** - Synthesizes DDD artifacts into formal canvases with Mermaid diagrams

### Research & Documentation
- **`web-search-researcher`** - Researches information from web sources
- **`thoughts-locator`** - Locates relevant documentation (if thoughts/ exists)
- **`thoughts-analyzer`** - Analyzes documentation for insights (if thoughts/ exists)

## Configuration

### Optional Features

These commands adapt based on what's present in your project:

**Thoughts Directory** (optional):
```
thoughts/
├── shared/
│   ├── plans/      # Implementation plans
│   ├── research/   # Research documents
│   └── tickets/    # Ticket files
```

If `thoughts/` doesn't exist, commands will use:
- `plans/` for implementation plans
- `research/` for research documents
- Root directory for other artifacts

**Linear Integration** (optional):
- Install Linear MCP server for `/linear` command
- Commands will check for Linear tools and adapt accordingly

**GitHub Integration** (optional):
- Commands use `gh` CLI if available
- Falls back to manual workflows if not installed

### Customization

You can customize commands by editing the `.md` files:

1. **Modify frontmatter** to change model, description, or tools
2. **Edit templates** in commands to match your workflow
3. **Adjust agent behavior** by modifying agent instructions

Example frontmatter:
```yaml
---
description: Your custom description
model: opus  # or sonnet, haiku
tools: Read, Grep, Glob  # Available tools
---
```

## Usage Examples

### Create an Implementation Plan

```
User: /create_plan
Claude: I'll help you create a detailed implementation plan.
        Please provide: [...]

User: Add user authentication with JWT tokens
Claude: [Researches codebase, asks clarifying questions, creates plan]
```

### Research a Feature

```
User: /research_codebase
Claude: I'm ready to research the codebase. What would you like to know?

User: How does webhook processing work?
Claude: [Spawns parallel agents, synthesizes findings, creates research doc]
```

### DDD Discovery Workflow

```
User: /ddd_full path/to/prd.md
Claude: [Runs all 7 DDD steps interactively, with confirmation gates between each]
```

Or run individual steps:

```
User: /ddd_align path/to/prd.md        → research/ddd/01-alignment.md
User: /ddd_discover                     → research/ddd/02-event-catalog.md
User: /ddd_decompose                    → research/ddd/03-sub-domains.md
User: /ddd_strategize                   → research/ddd/04-strategy.md
User: /ddd_connect                      → research/ddd/05-context-map.md
User: /ddd_define                       → research/ddd/06-canvases.md
User: /ddd_plan                         → plans/YYYY-MM-DD-ddd-*.md
User: /implement_plan plans/...         → code implementation
```

### Generate PR Description

```
User: /describe_pr
Claude: [Analyzes PR, runs verification commands, generates description]
```

## Command Patterns

Most commands follow this pattern:

1. **Initial Setup** - Gather context and understand requirements
2. **Research** - Spawn parallel agents to investigate codebase
3. **Interactive Design** - Collaborate with user on approach
4. **Execution** - Perform the task (write plan, create docs, etc.)
5. **Review** - Present results and iterate based on feedback

## Best Practices

### For Planning Commands
- Provide as much context as possible upfront
- Reference existing files/tickets when available
- Review and iterate on plans before implementation

### For Research Commands
- Be specific about what you want to understand
- Ask follow-up questions to deepen research
- Research documents are saved for future reference

### For Implementation Commands
- Ensure plans exist before implementing
- Run verification commands after each phase
- Pause for manual testing when needed

## Troubleshooting

### Commands not appearing
- Verify file paths in Claude configuration
- Check that `.md` files are valid markdown with frontmatter
- Restart Claude after adding new commands

### Agents not working
- Ensure agents directory is configured correctly
- Check that agent names in commands match agent filenames
- Verify tools listed in frontmatter are available

### Path issues
- Commands expect to run from project root
- Use absolute paths or configure working directory
- Check file permissions on command/agent files

## Advanced Usage

### Creating Custom Commands

1. Create a new `.md` file in `commands/`
2. Add frontmatter with description and model
3. Write command instructions in markdown
4. Reference existing agents or create new ones

Example:
```markdown
---
description: Your custom command
model: sonnet
---

# My Custom Command

Instructions for Claude on what to do...
```

### Creating Custom Agents

1. Create a new `.md` file in `agents/`
2. Define name, description, and tools in frontmatter
3. Write agent-specific instructions
4. Reference from commands using the agent name

Example:
```markdown
---
name: my-custom-agent
description: Does something specific
tools: Read, Grep
model: sonnet
---

You are a specialist at [specific task]...
```

### Chaining Commands

Commands can be chained for complex workflows:

```
/research_codebase → /create_plan → /implement_plan → /describe_pr
```

DDD discovery workflow:

```
/ddd_align → /ddd_discover → /ddd_decompose → /ddd_strategize → /ddd_connect → /ddd_define → /ddd_plan → /implement_plan
```

Or use `/ddd_full` for the complete end-to-end chain with confirmation gates.

## Contributing

To improve these commands and agents:

1. Keep instructions concise and token-efficient
2. Make commands fully generalized (no project-specific assumptions)
3. Provide clear examples in output format sections
4. Test with multiple project structures
5. Document any new dependencies or requirements

## Philosophy

These commands follow key principles:

- **Generalized**: Work across different projects and setups
- **Interactive**: Collaborate with users, don't assume
- **Thorough**: Research before acting, verify assumptions
- **Documented**: Create artifacts that persist beyond the session
- **Token-Efficient**: Concise instructions, maximum clarity

## License

These commands and agents are provided as-is for use in any project. Modify and adapt as needed for your workflows.

## Support

For issues or questions:
- Check command/agent markdown files for detailed instructions
- Verify your Claude configuration and paths
- Ensure optional dependencies (gh, Linear MCP) are installed if needed
- Review command output for specific error messages

---

**Version**: 1.0
**Last Updated**: 2025-01-25
