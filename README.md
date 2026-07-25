# Claude Agentic Commands, Skills & Agents

A collection of specialized skills, commands, and agents for Claude Code to help with software development workflows including planning, research, implementation, and PR management.

## Overview

This toolkit provides:
- **Skills**: All workflows live here — orchestrating pipelines (DDD, PM, QRSPI), simple operations (commit, validate-plan), and specialized tools. Supports isolated execution, auto-approved tools, and inter-step gates via `AskUserQuestion`.
- **Agents**: Role-based sub-agents (developer, architect, qa-engineer, researcher, scout) and DDD Architect-family specialists. See `references/ROLES.md` for the full role taxonomy.
- **Commands**: Empty — all commands have been migrated to skills. The `commands/` directory is retained for structural compatibility but contains no active files.

## Installation

### Claude Code (CLI)

Claude Code uses a `.claude/` directory for skills and agents.

```bash
# Clone the repository
git clone https://github.com/your-org/claude-agentic.git

# Install globally for all projects (recommended)
bash claude-agentic/scripts/install.sh
```

Or copy manually:

```bash
mkdir -p ~/.claude
cp -r claude-agentic/agents ~/.claude/
cp -r claude-agentic/skills ~/.claude/
```

Skills are available immediately — use `/ddd`, `/pm`, `/create-plan`, `/research-codebase`, etc. All workflows live in `skills/`; `commands/` is empty.

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

After installation, verify skills are available:

```
/create-plan - Create implementation plans
/research-codebase - Research how code works
/describe-pr - Generate PR descriptions
/ddd - Full DDD discovery workflow (7 steps with gates)
/pm - PM workspace build workflow
/commit - Commit changes without Claude attribution
```

If skills don't appear, restart your editor/CLI to reload configurations.

## Available Skills

All workflows are skills (in `skills/`). The `commands/` directory is empty — all commands have been migrated to skills.

### Planning & Design
- **`/create-plan`** - Create detailed implementation plans through interactive research
- **`/iterate-plan`** - Update existing implementation plans based on feedback
- **`/validate-plan`** - Validate implementation plans against codebase reality (delegates to qa-engineer)
- **`/tech-spec`** - Interactive technical specification with the Architect persona

### DDD Discovery-to-Implementation
- **`/ddd`** - Complete end-to-end DDD workflow (all 7 steps with inline AskUserQuestion gates)
- **`/ddd-align`** - Step 1: Align & understand the business domain from a PRD
- **`/ddd-discover`** - Step 2: EventStorming — discover events, commands, actors, policies
- **`/ddd-decompose`** - Step 3: Decompose domain into sub-domains and bounded contexts
- **`/ddd-strategize`** - Step 4: Classify sub-domains on Core Domain Chart
- **`/ddd-connect`** - Step 5: Context mapping — define relationships between contexts
- **`/ddd-define`** - Step 6: Build Bounded Context and Aggregate Design Canvases
- **`/ddd-plan`** - Step 7: Convert DDD artifacts into `/implement-plan`-compatible plans

### PM Workflow
- **`/pm`** - Full PM workspace build workflow with gates (orchestrates pm-synthesize inline)
- **`/pm-synthesize`** - PM inline persona: synthesize story map + DDD into a Linear build plan

### Research & Analysis
- **`/research-codebase`** - Comprehensively research codebase using parallel agents
- **`/debug-issue`** - Debug issues with systematic investigation

### Implementation & Review
- **`/implement-plan`** - Execute implementation plans step by step (delegates to developer subagent)
- **`/local-review`** - Review code changes before committing
- **`/describe-pr`** - Generate comprehensive PR descriptions
- **`/critique`** - Forked code review against a checklist

### Git Workflows
- **`/commit`** - Create well-formatted git commits without Claude attribution (`disable-model-invocation: true`)

### Project-Specific (Optional)
- **`/linear`** - Manage Linear tickets (requires Linear MCP integration)

## Available Agents

These specialized agents are used by skills (or can be invoked directly via the Task tool). See `references/ROLES.md` for the full role taxonomy including model tiers and tool scopes.

### Core Roles
- **`developer`** (opus) - Implements a plan phase or applies a scoped fix; returns structured report
- **`architect`** (opus) - Batch design-it-twice worker: produces one alternative interface under a stated constraint
- **`qa-engineer`** (opus) - Thoroughly tests completed work through actual execution; surfaces findings
- **`researcher`** (sonnet) - Investigates code, prior artifacts, or the web; specify mode in prompt: `code-investigation`, `artifact-research`, or `web-research`
- **`scout`** (haiku) - Locates files, directories, and components by pattern; returns paths + line numbers only

### DDD Discovery (Architect-family)
- **`ddd-event-discoverer`** (opus) - Extracts domain building blocks (events, commands, actors, policies) from requirements
- **`ddd-context-analyzer`** (opus) - Identifies bounded context boundaries from language patterns
- **`ddd-canvas-builder`** (opus) - Synthesizes DDD artifacts into formal canvases with Mermaid diagrams

## Operating model

This repo is designed for **Sonnet as the default main-loop model**, with heavier models promoted only for the turns that need them.

### Session setup

Start every Claude Code session with:

```
/model sonnet
```

Sonnet is the cheap, fast orchestration layer. Expensive skills auto-promote the main loop for their turn only and then revert. Subagents always run their own role tier regardless of the main loop model.

### Role tiers

| Role | Model | Rationale |
|---|---|---|
| Developer | opus | Autonomous code editing — errors are hard to catch |
| Architect | opus | Interface/boundary design requires strong reasoning |
| QA Engineer | opus | Test execution and judgment on failure modes |
| DDD Specialists | opus | Domain modelling is nuanced, high-stakes |
| Researcher | sonnet | Broad investigation — quality-to-cost tradeoff is good |
| Scout | haiku | Mechanical grep/glob locate; no reasoning required |

### Inline vs. forked skills

- **Inline skills with `model: opus`** (`create-plan`, `tech-spec`, `grill-me`, `improve-codebase-architecture`) temporarily promote the whole main loop for that turn, then revert. Use these interactively — they need `AskUserQuestion` gates.
- **Forked skills (`context: fork`)** (`critique`) run in an isolated subagent; only a summary returns to main context. The main loop model is unaffected. Note: forked skills cannot use `AskUserQuestion` — callers must pass the target explicitly.

### Orchestrator model recommendations

| Scenario | Recommended model |
|---|---|
| Interactive session (human present at each gate) | Sonnet (`/model sonnet`) |
| Purely mechanical / polling (no judgment required) | Haiku — only if the session is stateless and mechanical |
| Unattended / auto-mode orchestrator (e.g. `babysit-pr` in cron/loop with no human gate) | **Opus** — autonomous routing, anti-loop judgment, and escalation decisions need the strong model |

Never run an unattended orchestrator (`babysit-pr`, `/qrspi` in fully-autonomous loop mode) on Haiku or Sonnet. Without a human gate catching bad calls, the model tier IS the safety net.

### QRSPI in loop mode

`/qrspi` is designed for interactive use (`model: sonnet`, gates present). If you run it via `/loop` or cron with no human at each gate, treat it as unattended and set `/model opus` before starting the loop.

## Configuration

### Optional Features

These commands adapt based on what's present in your project:

**Artifact directories**:
```
research/          # Date-prefixed research notes (YYYY-MM-DD-topic.md)
├── ddd/           # DDD step outputs (01-alignment.md, 02-events.md, ...)
└── pm/            # PM synthesis output (build-plan.md)
plans/             # Date-prefixed implementation plans
.jeff/             # Jeff Patton product discovery artifacts
```

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
User: /create-plan
Claude: I'll help you create a detailed implementation plan.
        Please provide: [...]

User: Add user authentication with JWT tokens
Claude: [Researches codebase, asks clarifying questions, creates plan]
```

### Research a Feature

```
User: /research-codebase
Claude: I'm ready to research the codebase. What would you like to know?

User: How does webhook processing work?
Claude: [Spawns parallel agents, synthesizes findings, creates research doc]
```

### DDD Discovery Workflow

```
User: /ddd path/to/prd.md
Claude: [Runs all 7 DDD steps interactively, with real AskUserQuestion gates between each]
```

Or run individual steps:

```
User: /ddd-align path/to/prd.md        → research/ddd/01-alignment.md
User: /ddd-discover                     → research/ddd/02-event-catalog.md
User: /ddd-decompose                    → research/ddd/03-sub-domains.md
User: /ddd-strategize                   → research/ddd/04-strategy.md
User: /ddd-connect                      → research/ddd/05-context-map.md
User: /ddd-define                       → research/ddd/06-canvases.md
User: /ddd-plan                         → plans/YYYY-MM-DD-ddd-*.md
User: /implement-plan plans/...         → code implementation
```

### Generate PR Description

```
User: /describe-pr
Claude: [Analyzes PR, runs verification commands, generates description]
```

## Skill Patterns

Most skills follow this pattern:

1. **Initial Setup** - Gather context and understand requirements
2. **Research** - Spawn parallel agents to investigate codebase
3. **Interactive Design** - Collaborate with user on approach (AskUserQuestion gates)
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

### Creating Custom Skills

1. Create a new directory in `skills/` (e.g., `skills/my-skill/`)
2. Create `skills/my-skill/SKILL.md` with frontmatter and body
3. Add `name:`, `description:`, `model:`, and `allowed-tools:` to frontmatter
4. Write skill instructions in markdown

Example:
```markdown
---
name: my-skill
description: Does something specific
model: sonnet
allowed-tools: Read, Grep, AskUserQuestion
---

# My Skill

Instructions for Claude on what to do...
```

**Key rule**: If your skill uses `AskUserQuestion` for gates, do NOT add `context: fork` — forked skills cannot use `AskUserQuestion`. Run inline instead.

### Creating Custom Agents

1. Create a new `.md` file in `agents/`
2. Define name, description, model, and tools in frontmatter
3. Write agent-specific instructions with a persona line first
4. Reference from skills using the agent name in Task calls

Example:
```markdown
---
name: my-custom-agent
description: Does something specific
tools: Read, Grep
model: sonnet
---

You are a senior specialist at [specific task].

[Sharp invocation contract here...]
```

### Chaining Skills

Skills can be chained for complex workflows:

```
/research-codebase → /create-plan → /implement-plan → /describe-pr
```

DDD discovery workflow (individual steps):

```
/ddd-align → /ddd-discover → /ddd-decompose → /ddd-strategize → /ddd-connect → /ddd-define → /ddd-plan → /implement-plan
```

Or use `/ddd` for the complete end-to-end chain with real AskUserQuestion confirmation gates.

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
