---
name: skill-builder
description: "Build new Claude Skills using Context Engineering principles (Research, Plan, Implement). Use when creating or improving skills for this repo."
model: opus
context: fork
allowed-tools: Read, Grep, Glob, Write, Edit, Task, AskUserQuestion, TodoWrite, Bash(git *)
argument-hint: [skill-name]
---

# Skill Builder

Ultrathink about what makes a great Claude Skill: clear triggering, progressive disclosure, interactive validation, and artifact-driven output. A skill is a set of instructions that Claude follows when a user invokes it — the quality of those instructions determines the quality of every future invocation.

Build new skills for this repository following established conventions and Context Engineering principles.

**Input**: $ARGUMENTS

## Current Context

- **Branch**: !`git branch --show-current 2>/dev/null || echo "N/A"`
- **Last Commit**: !`git log -1 --oneline 2>/dev/null || echo "N/A"`
- **Existing Skills**: !`ls skills/ 2>/dev/null | head -20`

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

Get use case details using AskUserQuestion:
- **Category**: What type of skill is this?
- Options should cover: Workflow Automation (multi-step process), Research & Analysis (investigate and document), Document Creation (generate artifacts), MCP Enhancement (guide connector usage), Other

Then get scope details using AskUserQuestion:
- **Scope**: How complex is this skill?
- Options should cover: Simple (single workflow, ~50 lines), Medium (branching logic, templates, ~100 lines), Complex (parallel agents, multi-phase, ~200 lines)

#### 1b. Research Conventions

Spawn parallel research tasks:

- **codebase-pattern-finder**: Find skills similar to [skill-name] in `skills/` directory — read their SKILL.md files, note patterns for the same category
- **codebase-analyzer**: Analyze the frontmatter conventions, tool restrictions, and hook patterns across existing skills in `skills/`

#### 1c. Define Requirements

Work through these with the user:

1. **Trigger**: When should this skill activate? What input does it expect?
2. **Workflow**: What are the 3-7 major steps?
3. **Tools needed**: Which tools does this skill require? (Read, Grep, Glob, Write, Edit, Task, AskUserQuestion, TodoWrite, Bash)
4. **Output**: What artifact does it produce? Where does it go?
5. **User interaction**: What decisions need user input?

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

Draft the YAML frontmatter based on research:

```yaml
---
name: [kebab-case]
description: "[What it does]. Use when [trigger conditions]."
model: opus
context: fork
allowed-tools: [minimal set needed]
argument-hint: [what user provides]
---
```

Follow these conventions from existing skills:
- `model: opus` unless the skill is simple enough for a smaller model
- `context: fork` for skills that run as independent sessions
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

Key quality rules:
- Frontmatter has `---` delimiters on their own lines
- Description includes WHAT and WHEN
- Instructions are actionable (not vague)
- AskUserQuestion is used for all user decisions — never print questions as plain text
- Options in AskUserQuestion are tailored to the specific context, not generic
- Examples show realistic scenarios
- Error handling covers common failures
- File references use `file:line` format where applicable

#### 3b. Create Templates (if planned)

Write any template files to `skills/[skill-name]/templates/`.

#### 3c. Create References (if planned)

Write any reference files to `skills/[skill-name]/references/`.

#### 3d. Quality Checklist

Verify against this checklist:

- [ ] Folder name is kebab-case
- [ ] `SKILL.md` exists (exact spelling, exact case)
- [ ] YAML frontmatter has `---` delimiters
- [ ] `name` field matches folder name
- [ ] `description` includes what AND when
- [ ] `allowed-tools` is minimal (no unnecessary tools)
- [ ] `$ARGUMENTS` is referenced in the body
- [ ] Current Context block uses `!` backtick git commands
- [ ] Initial Response handles both with-params and no-params
- [ ] Process steps are numbered and clear
- [ ] AskUserQuestion is used for all decisions (not plain text questions)
- [ ] AskUserQuestion options are specific (not generic yes/no)
- [ ] Output paths follow existing conventions (`thoughts/shared/`, `research/`, etc.)
- [ ] Guidelines section exists with constraints
- [ ] No XML/HTML tags in content
- [ ] Templates referenced with relative paths

#### 3e. Present Result

Show the created files, line counts, invocation syntax, and completed quality checklist.

**Human Review Gate**: Get final approval using AskUserQuestion:
- **Final review**: Skill looks good?
- Options should cover: ship it, needs tweaks, major rework needed

If tweaks needed, iterate on the specific feedback.

## Guidelines

1. **Progressive Disclosure**: Keep SKILL.md focused on workflow. Put detailed docs in `references/`, structured output formats in `templates/`
2. **Minimal Tools**: Only grant the tools the skill actually needs. Over-permissioning is an anti-pattern
3. **Ultrathink First**: Every skill should start with an ultrathink prompt that frames the problem space
4. **Interactive Over Autonomous**: Use AskUserQuestion at every major decision point. Never assume user intent
5. **Artifact-Driven**: Skills should produce concrete artifacts at known paths, not just chat output
6. **Convention Over Configuration**: Follow the patterns established by existing skills (git context block, initial response pattern, etc.)
7. **No Vibe Coding**: Every instruction should be specific enough that following it produces consistent results
8. **Error Amplification Awareness**: Invest time in research and planning — a bad plan produces 10x bad implementation
