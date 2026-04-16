---
name: skill-builder
description: "Build or improve Claude Code skills for this repo using a Research → Plan → Implement workflow with interactive validation gates. Use when creating a new slash command/skill or refactoring an existing one. Triggers on 'build a skill', 'create /foo skill', 'new skill for X'."
model: opus
allowed-tools: Read, Grep, Glob, Write, Edit, Task, AskUserQuestion, TodoWrite, Bash(git *)
argument-hint: [skill-name]
---

# Skill Builder

Ultrathink about what makes a great Claude Skill: clear triggering, progressive disclosure, interactive validation, and artifact-driven output. A skill is a set of instructions that Claude follows when a user invokes it — the quality of those instructions determines the quality of every future invocation.

Build new skills for this repository following established conventions and the best practices in [The Complete Guide to Building Skills for Claude](references/The-Complete-Guide-to-Building-Skill-for-Claude-3.pdf). Consult this reference for description formulas, use case categories, instruction patterns, testing approaches, and troubleshooting.

**Input**: $ARGUMENTS

## Current Context

- **Branch**: !`git branch --show-current`
- **Last Commit**: !`git log -1 --oneline`
- **Existing Skills**: !`ls skills/`

## Initial Response

1. **If a skill name is provided**: Begin Phase 1 (Research)
2. **If no parameters**:
```
I'll help you build a new skill for this repo.

Please provide:
1. A skill name (kebab-case, e.g. `deploy-preview`)
2. A brief description of what the skill should do

Tip: Invoke directly: `/skill-builder my-skill-name`
```
Then wait for user input.

## Process Steps

### Phase 1: Research & Requirements (~200 lines of context)

Goal: Understand what this skill needs to do and how it fits into existing conventions.

#### 1a. Understand the Skill

Determine the skill's **framing** (from the guide, Ch.5 "Problem-first vs tool-first"):
- **Problem-first**: User describes an outcome ("I need to set up a project workspace") — the skill orchestrates the right tools in the right sequence
- **Tool-first**: User has tools connected ("I have Notion MCP connected") — the skill teaches optimal workflows and best practices

Get use case details using AskUserQuestion:
- **Category**: What type of skill is this? (from the guide, Ch.2 "Common skill use case categories")
- Options should cover: Document & Asset Creation (consistent high-quality output using templates, style guides, quality checklists), Workflow Automation (multi-step process with validation gates, templates, refinement loops), MCP Enhancement (workflow guidance on top of MCP tool access, error handling for common MCP issues), Research & Analysis (investigate and document), Other

Then get scope details using AskUserQuestion:
- **Scope**: How complex is this skill?
- Options should cover: Simple (single workflow, ~50 lines), Medium (branching logic, templates, ~100 lines), Complex (parallel agents, multi-phase, ~200 lines)

#### 1b. Research Conventions

Spawn parallel research tasks:

- **codebase-pattern-finder**: Find skills similar to [skill-name] in `skills/` directory — read their SKILL.md files, note patterns for the same category
- **codebase-analyzer**: Analyze the frontmatter conventions, tool restrictions, and hook patterns across existing skills in `skills/`

#### 1c. Define Requirements

Work through these with the user:

1. **Trigger**: When should this skill activate? What input does it expect? Include 2-3 concrete use cases (guide, Ch.2: "Before writing any code, identify 2-3 concrete use cases")
2. **Workflow**: What are the 3-7 major steps? Choose the right pattern from the guide (Ch.5): Sequential orchestration, Multi-MCP coordination, Iterative refinement, Context-aware tool selection, or Domain-specific intelligence
3. **Tools needed**: Which tools does this skill require? (Read, Grep, Glob, Write, Edit, Task, AskUserQuestion, TodoWrite, Bash)
4. **Output**: What artifact does it produce? Where does it go?
5. **User interaction**: What decisions need user input?
6. **Success criteria** (guide, Ch.2): Define at least one quantitative metric (e.g., completes workflow in X tool calls) and one qualitative metric (e.g., workflows complete without user correction)

Get validation using AskUserQuestion:
- **Requirements check**: Do these requirements capture your intent?
- Options should cover: yes proceed to planning, needs adjustments, start over

#### 1d. Write Research Artifact

Create: `research/YYYY-MM-DD-skill-builder-[skill-name].md`

```markdown
# Skill Research: [skill-name]

## Use Cases
1. [Primary use case with example trigger phrases]
2. [Secondary use case]
3. [Edge case or anti-pattern to avoid]

## Category
[Workflow/Research/Document/MCP Enhancement]

## Requirements
- **Trigger**: [what activates it]
- **Input**: [what user provides]
- **Output**: [artifact path and format]
- **Tools**: [required tool list]
- **Interactions**: [user decision points]

## Similar Skills
- [skill-name]: [what pattern to borrow]
- [skill-name]: [what to differentiate from]

## Conventions to Follow
- [Frontmatter pattern]
- [Template pattern]
- [Output path pattern]
```

**Human Review Gate**: Present the research summary and wait for approval before proceeding.

---

### Phase 2: Plan & Design (~200 lines of context)

Goal: Design the complete skill structure before writing it.

#### 2a. Design Frontmatter

Draft the YAML frontmatter based on research. Use the guide's description formula (Ch.2 "Writing effective skills"):

```
[What it does] + [When to use it] + [Key capabilities]
```

```yaml
---
name: [kebab-case]
description: "[What it does]. Use when [trigger conditions]. Triggers on '[phrase 1]', '[phrase 2]'."
model: opus
allowed-tools: [minimal set needed]
argument-hint: [what user provides]
---
```

The description is the most important field — it determines whether Claude loads the skill (guide, Ch.2). It must be specific and actionable, include trigger phrases users would actually say, and stay under 1024 characters. Avoid vague descriptions like "Helps with projects" or purely technical descriptions like "Implements the Project entity model."

Follow these conventions from existing skills:
- `model: opus` unless the skill is simple enough for a smaller model
- **Do NOT set `context: fork`** if the skill uses `AskUserQuestion`. That tool is unavailable in subagents (see [Claude Code docs — Limitations](https://code.claude.com/docs/en/agent-sdk/user-input#limitations)). Leave `context` unset so the skill runs inline in the main session.
- `allowed-tools`: Only include tools the skill actually needs. Common patterns:
  - Research-only: `Read, Grep, Glob, Bash(git *), TodoWrite`
  - Research + interaction: `Read, Grep, Glob, Task, AskUserQuestion, TodoWrite`
  - Full implementation: `Read, Grep, Glob, Write, Edit, Task, AskUserQuestion, TodoWrite, Bash`
- `argument-hint`: Use brackets, e.g. `[ticket-id]`, `[file-path]`, `[description]`

#### 2b. Design Instruction Flow

Outline the skill's instruction structure:

1. **Header**: Title + ultrathink guidance
2. **Input**: `$ARGUMENTS` declaration
3. **Current Context**: Git status block (use `!` backtick commands)
4. **Initial Response**: With-params vs no-params behavior
5. **Process Steps**: Numbered workflow sections
6. **Guidelines**: Constraints and best practices

For each process step, define:
- What tools to use
- What user decisions are needed (via AskUserQuestion)
- What artifacts to produce
- Error handling

#### 2c. Design Templates (if needed)

If the skill produces structured artifacts, design a template:
- File path: `skills/[skill-name]/templates/[template-name].md`
- Include YAML frontmatter for metadata
- Use placeholder sections

#### 2d. Design References (if needed)

If the skill needs detailed documentation that would bloat SKILL.md:
- File path: `skills/[skill-name]/references/[topic].md`
- Keep SKILL.md focused on workflow, put details in references

#### 2e. Present Plan

Present the complete plan including directory structure, frontmatter, instruction flow, user interaction points, and output artifacts.

**Human Review Gate**: Get plan approval using AskUserQuestion:
- **Plan review**: Ready to implement this skill?
- Options should cover: looks good implement it, needs changes, go back to research

---

### Phase 3: Implement & Validate

Goal: Create the skill files and verify quality.

#### 3a. Create SKILL.md

Write the skill to `skills/[skill-name]/SKILL.md` following the plan.

Use the template in [templates/skill-template.md](templates/skill-template.md) as a starting scaffold, then customize based on the plan.

Key quality rules (from the guide, Ch.2 "Best Practices for Instructions"):
- Frontmatter has `---` delimiters on their own lines
- Description includes WHAT, WHEN, and trigger phrases
- Instructions are specific and actionable — not vague ("Validate the data before proceeding" is bad; explicit validation steps with expected formats is good)
- Reference bundled resources clearly (e.g., "Consult `references/api-patterns.md` for rate limiting guidance")
- Use progressive disclosure: keep SKILL.md focused on core workflow, move detailed docs to `references/` (guide Ch.1: three-level system)
- AskUserQuestion is used for all user decisions — never print questions as plain text
- Options in AskUserQuestion are tailored to the specific context, not generic
- Examples show realistic scenarios with expected inputs and outputs
- Error handling covers common failures with specific solutions
- Include troubleshooting section for common error scenarios (guide, Ch.5)
- Keep SKILL.md under 5,000 words to avoid context bloat (guide, Ch.5 "Large context issues")
- File references use `file:line` format where applicable

#### 3b. Create Templates (if planned)

Write any template files to `skills/[skill-name]/templates/`.

#### 3c. Create References (if planned)

Write any reference files to `skills/[skill-name]/references/`.

#### 3d. Quality Checklist

Verify against this checklist (combines repo conventions + guide Reference A):

**Before you start** (guide, Ref A):
- [ ] 2-3 concrete use cases identified
- [ ] Tools identified (built-in or MCP)
- [ ] Reviewed the guide and similar existing skills
- [ ] Planned folder structure

**During development**:
- [ ] Folder name is kebab-case (no spaces, underscores, or capitals)
- [ ] `SKILL.md` exists (exact spelling, exact case — no README.md inside skill folder)
- [ ] YAML frontmatter has `---` delimiters
- [ ] `name` field matches folder name
- [ ] `description` follows guide formula: [What it does] + [When to use it] + trigger phrases (under 1024 chars)
- [ ] `description` has no XML angle brackets (security restriction)
- [ ] `allowed-tools` is minimal (no unnecessary tools)
- [ ] `$ARGUMENTS` is referenced in the body
- [ ] Current Context block uses `!` backtick git commands
- [ ] Initial Response handles both with-params and no-params
- [ ] Process steps are numbered and clear
- [ ] Instructions are specific and actionable (not ambiguous)
- [ ] AskUserQuestion is used for all decisions (not plain text questions)
- [ ] AskUserQuestion options are specific (not generic yes/no)
- [ ] Output paths follow existing conventions (`thoughts/shared/`, `research/`, etc.)
- [ ] Error handling included with specific solutions
- [ ] References clearly linked from SKILL.md
- [ ] Guidelines section exists with constraints
- [ ] No XML/HTML tags in content
- [ ] Templates referenced with relative paths
- [ ] SKILL.md is under 5,000 words

**Before shipping** (guide, Ref A):
- [ ] Tested triggering on obvious tasks (skill loads when expected)
- [ ] Tested triggering on paraphrased requests
- [ ] Verified doesn't trigger on unrelated topics
- [ ] Functional tests pass (valid outputs, error cases covered)

#### 3e. Present Result

Show the created files, line counts, invocation syntax, and completed quality checklist.

**Human Review Gate**: Get final approval using AskUserQuestion:
- **Final review**: Skill looks good?
- Options should cover: ship it, needs tweaks, major rework needed

If tweaks needed, iterate on the specific feedback.

## Guidelines

1. **Progressive Disclosure** (guide, Ch.1): Three-level system — frontmatter (always loaded), SKILL.md body (loaded when relevant), linked files in `references/` and `templates/` (loaded on demand). Keep SKILL.md under 5,000 words.
2. **Description is King** (guide, Ch.2): The description field determines whether Claude loads the skill. Use the formula: [What it does] + [When to use it] + [trigger phrases]. Test for under/over-triggering.
3. **Be Specific and Actionable** (guide, Ch.2): "Run `python scripts/validate.py --input {filename}`" beats "Validate the data before proceeding." Ambiguous instructions produce inconsistent results.
4. **Minimal Tools**: Only grant the tools the skill actually needs. Over-permissioning is an anti-pattern.
5. **Ultrathink First**: Every skill should start with an ultrathink prompt that frames the problem space.
6. **Interactive Over Autonomous**: Use AskUserQuestion at every major decision point. Never assume user intent.
7. **Artifact-Driven**: Skills should produce concrete artifacts at known paths, not just chat output.
8. **Convention Over Configuration**: Follow the patterns established by existing skills (git context block, initial response pattern, etc.)
9. **Iterate on a Single Task** (guide, Ch.3): Build and test on one challenging use case first, then expand. This leverages in-context learning and provides faster signal than broad testing.
10. **Error Amplification Awareness**: Invest time in research and planning — a bad plan produces 10x bad implementation.

**Best Practices Reference**: For the full guide on description writing, instruction patterns, testing approaches, workflow patterns (sequential, multi-MCP, iterative refinement, context-aware, domain-specific), troubleshooting, and the complete quality checklist, consult [The Complete Guide to Building Skills for Claude](references/The-Complete-Guide-to-Building-Skill-for-Claude-3.pdf).
