---
name: SKILL_NAME
description: "WHAT_IT_DOES. Use when TRIGGER_CONDITIONS."
model: opus
context: fork
allowed-tools: TOOL_LIST
argument-hint: [ARGUMENT_HINT]
---

# SKILL_TITLE

Ultrathink about PROBLEM_SPACE_FRAMING.

BRIEF_DESCRIPTION_OF_SKILL_PURPOSE.

**Input**: $ARGUMENTS

## Current Context

- **Branch**: !`git branch --show-current`
- **Last Commit**: !`git log -1 --oneline`
- **Modified Files**: !`git status --short`

## Initial Response

1. **If parameters provided**: Read any referenced files completely (no limit/offset), then begin Step 1
2. **If no parameters**:
```
I'll help you BRIEF_ACTION_DESCRIPTION.

Please provide:
1. REQUIRED_INPUT_1
2. REQUIRED_INPUT_2

Tip: Invoke directly: `/SKILL_NAME [args]`
```
Then wait for user input.

## Process Steps

### Step 1: FIRST_ACTION_NAME

WHAT_THIS_STEP_DOES.

1. ACTION_1
2. ACTION_2
3. ACTION_3

### Step 2: SECOND_ACTION_NAME

WHAT_THIS_STEP_DOES.

Get user input using AskUserQuestion:
- **DECISION_LABEL**: QUESTION_TO_ASK
- Options should cover: OPTION_1 (with context), OPTION_2 (with context), OPTION_3 (with context)

Tailor options based on actual findings. Don't use generic options.

### Step 3: THIRD_ACTION_NAME

WHAT_THIS_STEP_DOES.

Write output to `OUTPUT_PATH/YYYY-MM-DD-description.md`

### Step 4: Review & Confirm

Present results and get confirmation using AskUserQuestion:
- **Confirm**: Ready to finalize?
- Options should cover: looks good, needs changes, cancel

## Guidelines

1. **GUIDELINE_1**: EXPLANATION
2. **GUIDELINE_2**: EXPLANATION
3. **GUIDELINE_3**: EXPLANATION
