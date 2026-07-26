---
name: skill-builder
description: "Build or improve Claude Code skills for this repo using a Research → Plan → Implement workflow with interactive validation gates, including loop-aware design for skills meant to run repeatedly via /goal, /loop, or CronCreate. Use when creating a new slash command/skill or refactoring an existing one. Triggers on 'build a skill', 'create /foo skill', 'new skill for X', 'make this skill run on a loop'."
model: opus
allowed-tools: Read, Grep, Glob, Write, Edit, Task, AskUserQuestion, TodoWrite, Bash(git *)
argument-hint: [skill-name]
---

# Skill Builder

Ultrathink about what makes a great Claude Skill: clear triggering, progressive disclosure, interactive validation, and artifact-driven output. A skill is a set of instructions that Claude follows when a user invokes it — the quality of those instructions determines the quality of every future invocation.

Build new skills for this repository following established conventions and the best practices in [The Complete Guide to Building Skills for Claude](references/The-Complete-Guide-to-Building-Skill-for-Claude-3.pdf). Consult this reference for description formulas, use case categories, instruction patterns, testing approaches, and troubleshooting. If the skill is meant to run repeatedly over time rather than once — via `/goal`, `/loop`/`/schedule`, or a recurring `CronCreate` job — also consult [references/loop-design.md](references/loop-design.md) for stop-condition, state-tracking, and safety patterns before designing the workflow.

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

Then get cadence details using AskUserQuestion — this determines whether loop-design work is needed at all (see [The Complete Guide...](references/The-Complete-Guide-to-Building-Skill-for-Claude-3.pdf) for one-shot patterns; [references/loop-design.md](references/loop-design.md) for everything else):
- **Cadence**: How will this skill be invoked over time?
- Options should cover: One-shot (default — single invocation, completes within one session), Turn-based iterative (loops within one session until Claude judges the goal met or a refinement cap is hit, e.g. `grill-me`), Goal-driven via `/goal` (exits when a stated, verifiable condition is met or max turns reached), Recurring/unattended via `/loop`, `/schedule`, or `CronCreate` (fires repeatedly over time with no human present between fires, e.g. `babysit-pr`)

Default to One-shot unless the use case clearly spans time or requires repeated unattended observation — per the loop-engineering guidance, most tasks don't need loop machinery, and adding it unasked is scope creep. If the answer is anything but One-shot, read `references/loop-design.md` now; its requirements feed into 1c, 2a, and 3d below.

#### 1b. Research Conventions

Spawn a research task:

- **researcher** (code-investigation mode): Find skills similar to [skill-name] in `skills/` directory — read their SKILL.md files, note patterns for the same category; also analyze the frontmatter conventions, tool restrictions, and hook patterns across existing skills in `skills/`

#### 1c. Define Requirements

Work through these with the user:

1. **Trigger**: When should this skill activate? What input does it expect? Include 2-3 concrete use cases (guide, Ch.2: "Before writing any code, identify 2-3 concrete use cases")
2. **Workflow**: What are the 3-7 major steps? Choose the right pattern from the guide (Ch.5): Sequential orchestration, Multi-MCP coordination, Iterative refinement, Context-aware tool selection, or Domain-specific intelligence
3. **Tools needed**: Which tools does this skill require? (Read, Grep, Glob, Write, Edit, Task, AskUserQuestion, TodoWrite, Bash)
4. **Output**: What artifact does it produce? Where does it go?
5. **User interaction**: What decisions need user input?
6. **Success criteria** (guide, Ch.2): Define at least one quantitative metric (e.g., completes workflow in X tool calls) and one qualitative metric (e.g., workflows complete without user correction)
7. **Loop behavior** (only if Cadence ≠ One-shot, per `references/loop-design.md`): What's the precise stop condition? What state-tracking artifact persists progress across fires, and at what path? How does a fire detect "fresh start" vs "re-entering an existing run"? What runs unattended without `AskUserQuestion` (a whitelist), and what's explicitly forbidden? For cron-backed loops, what interval (off-minute, e.g. `*/17 * * * *`) and what triggers back-off?

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

## Cadence
[One-shot / Turn-based iterative / Goal-driven / Recurring-unattended]

## Requirements
- **Trigger**: [what activates it]
- **Input**: [what user provides]
- **Output**: [artifact path and format]
- **Tools**: [required tool list]
- **Interactions**: [user decision points]

## Loop Design (omit this section entirely if Cadence is One-shot)
- **Stop condition**: [precise, mechanically checkable]
- **State artifact**: [path + what it tracks]
- **Re-entry detection**: [how a fire knows fresh vs resuming]
- **Auto-run whitelist**: [what skips AskUserQuestion] / **Forbidden operations**: [hard nos]
- **Interval / trigger**: [cron expression or /loop cadence, if applicable]

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
- Pick the model tier for what the skill actually needs: `sonnet` is the default for most workflow/orchestration skills; reserve `opus` for skills doing genuinely open-ended judgment (interface design, architecture critique, multi-agent coordination). Do not default to `opus` for simple or mechanical skills — Opus is more prone to scope creep and over-verification, so use the cheaper tier unless the task needs Opus's judgment.
  - **Loop exception**: if Cadence is Goal-driven or Recurring/unattended *and* the skill writes autonomously (commits, pushes, merges, messages externally), default to `opus` regardless of task complexity. The cheap-orchestrator rule only holds when a human reviews every turn; once cycles fire unattended there's no gate to catch a bad call until the next check-in (see `references/loop-design.md` "Model tier for loop skills"; `babysit-pr` is the existing example). Turn-based iterative loops where a human reviews each round's output before the next (e.g. `iterate-plan`) can stay on `sonnet` — the human gate is intact, just spread across turns.
- **Do NOT set `context: fork`** if the skill uses `AskUserQuestion`. That tool is unavailable in subagents (see [Claude Code docs — Limitations](https://code.claude.com/docs/en/agent-sdk/user-input#limitations)). Leave `context` unset so the skill runs inline in the main session.
- `allowed-tools`: Only include tools the skill actually needs. Common patterns:
  - Research-only: `Read, Grep, Glob, Bash(git *), TodoWrite`
  - Research + interaction: `Read, Grep, Glob, Task, AskUserQuestion, TodoWrite`
  - Full implementation: `Read, Grep, Glob, Write, Edit, Task, AskUserQuestion, TodoWrite, Bash`
  - Recurring/unattended loop: add `Skill` (for `/goal`) and load `CronCreate`/`CronDelete`/`CronList` via `ToolSearch` inside the skill body rather than listing them in `allowed-tools` (they're deferred tools)
- `argument-hint`: Use brackets, e.g. `[ticket-id]`, `[file-path]`, `[description]`. For recurring loop skills, add a re-entry marker: `[id] [cycle?]` (see `babysit-pr`), so a scheduled fire can be distinguished from a fresh invocation.

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

If Cadence ≠ One-shot, the **Initial Response** step also needs mode detection: check `$ARGUMENTS`/context for the re-entry marker (or check whether the state artifact already exists) and branch — fresh invocations run onboarding (goal-setting, scope-freezing); re-entries jump straight to the cycle body. See `babysit-pr`'s Initial Response for the pattern.

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

Check the handful of items that are genuinely mechanical and easy to get wrong — don't re-derive or narrate a full pass over everything else you just wrote:

- [ ] Folder name is kebab-case; `name` field matches the folder name
- [ ] `description` follows guide formula (what/when/trigger phrases), under 1024 chars, no XML angle brackets
- [ ] `allowed-tools` is minimal — no unnecessary tools
- [ ] No `context: fork` alongside `AskUserQuestion`
- [ ] SKILL.md is under 5,000 words

If Cadence ≠ One-shot, also check (see `references/loop-design.md`):
- [ ] Stop condition is explicit and mechanically checkable — not "keep going until done"
- [ ] State-tracking artifact path is defined, with re-entry detection in Initial Response
- [ ] Auto-run whitelist and forbidden-operations list are both spelled out, not implied
- [ ] Cron-backed intervals (if any) are off-minute, with a defined back-off trigger
- [ ] Model is `opus` if the loop writes autonomously with no per-cycle human review

#### 3e. Present Result

Show the created files, line counts, and invocation syntax.

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
11. **Loop-Aware Design, Only When Earned**: Default every skill to one-shot. If Cadence (Phase 1a) is Turn-based, Goal-driven, or Recurring/unattended, apply `references/loop-design.md`'s patterns — explicit stop conditions, an idempotent cycle body, a persisted state artifact, scope freezes, whitelisted auto-actions with a forbidden-operations list, and `opus` for anything that writes with no per-cycle human review. Don't add any of this to a skill that finishes in one turn — that's the over-engineering the loop-engineering guidance explicitly warns against.

**Best Practices Reference**: For the full guide on description writing, instruction patterns, testing approaches, workflow patterns (sequential, multi-MCP, iterative refinement, context-aware, domain-specific), troubleshooting, and the complete quality checklist, consult [The Complete Guide to Building Skills for Claude](references/The-Complete-Guide-to-Building-Skill-for-Claude-3.pdf).
