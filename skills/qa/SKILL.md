---
name: qa
description: "Walk through acceptance criteria in the browser using Chrome integration to validate that a ticket's requirements actually work. Use when a feature is implemented and needs manual QA verification."
model: opus
context: fork
allowed-tools: Read, Grep, Glob, Bash, Task, AskUserQuestion, TodoWrite, mcp__claude-in-chrome__*
argument-hint: [ticket-id-or-url]
---

# QA Verification

Ultrathink about what it means to truly verify a feature works: not just that the code compiles or tests pass, but that a real user navigating a real browser would experience the intended behavior. Consider the acceptance criteria as a contract between the team and the user, and your job is to validate that contract.

Verify that a ticket's acceptance criteria actually work by walking through them in a live browser using Claude's Chrome integration. Fetch the issue, extract acceptance steps, navigate the app, validate each criterion, and produce a structured QA report.

**Input**: $ARGUMENTS

## Current Context

- **Branch**: !`git branch --show-current`
- **Last Commit**: !`git log -1 --oneline`
- **Modified Files**: !`git status --short`

## Prerequisites

This skill requires Claude's Chrome integration to be active. See [references/chrome-integration.md](references/chrome-integration.md) for setup details.

If Chrome is not connected, instruct the user:
```
Chrome integration is required for QA verification.

To connect:
1. Install the "Claude in Chrome" extension from the Chrome Web Store
2. Launch Claude Code with: claude --chrome
   (or run /chrome in an existing session)
3. Re-invoke /qa once connected
```

## Initial Response

1. **If a ticket identifier is provided**: Parse it and begin Step 1
2. **If no parameters**:
```
I'll help you QA-verify a feature by walking through its acceptance criteria in the browser.

Please provide:
1. A ticket identifier (e.g. ENG-1234, PLAT-56)
2. Or a path to a ticket file in thoughts/shared/tickets/

Tip: Invoke directly: /qa ENG-1234
```
Then wait for user input.

## Process Steps

### Step 1: Fetch Issue & Extract Acceptance Criteria

1. **Parse the input** to determine platform and identifier:
   - **Linear**: Input matches a ticket identifier pattern (e.g. `ENG-\d+`, `PLAT-\d+`)
   - **Ticket file**: Input is a path to a file in `thoughts/shared/tickets/`
   - **Ambiguous**: Get platform using AskUserQuestion:
     - **Platform**: Where is this ticket?
     - Options should cover: Linear (with workspace options), Local ticket file

2. **Fetch the ticket**:
   - **For Linear**: Use `mcp__mise-tools__linear_{workspace}_get_issue` to fetch the ticket. Determine workspace from the identifier prefix or ask. See [Linear reference IDs](../linear/references/ids.md) for workspace mappings.
   - **For ticket files**: Read the file completely (no limit/offset)

3. **Extract acceptance criteria**:
   - Look for sections labeled "Acceptance Criteria", "Done Criteria", "Success Criteria", "Definition of Done", or similar
   - Also check for checkbox lists (`- [ ]`) that describe expected behaviors
   - Parse each criterion into a discrete, testable step

4. **If no acceptance criteria found**:
   Get guidance using AskUserQuestion:
   - **No criteria**: This ticket doesn't have explicit acceptance criteria. How should I proceed?
   - Options should cover: I'll describe the acceptance steps now, Derive criteria from the ticket description (best-effort), Cancel QA

5. **Present the extracted criteria** for validation:
   ```
   ## Acceptance Criteria for [TICKET-ID]: [Title]

   I found [N] acceptance criteria to verify:

   1. [Criterion 1 — what to verify and expected outcome]
   2. [Criterion 2 — what to verify and expected outcome]
   ...

   **Target URL**: [inferred from ticket or TBD]
   ```

6. **Get confirmation** using AskUserQuestion:
   - **Criteria review**: Are these the right acceptance criteria to verify?
   - Options should cover: looks correct proceed, needs adjustments (let me edit), add more criteria, wrong ticket

### Step 2: Establish Test Environment

1. **Determine the target URL**:
   - Check if the ticket references a specific URL, route, or page
   - Check if there's a local dev server that should be running (e.g. `localhost:3000`)
   - If unclear, get the URL using AskUserQuestion:
     - **Target URL**: Where should I test this feature?
     - Options should cover: localhost with common ports, staging URL, production URL, other (I'll provide)

2. **Verify the environment is ready**:
   - Navigate to the target URL in Chrome
   - Confirm the page loads successfully
   - Check the browser console for any critical errors on load
   - If the page doesn't load, report the issue and ask the user to fix it before proceeding

3. **Check for authentication requirements**:
   - If the page requires login, pause and ask the user to authenticate
   - Chrome shares your browser's login state, so if the user is already logged in it should work
   - If a login page or CAPTCHA appears, tell the user to handle it manually

4. **Capture baseline state**:
   - Note the current page state (URL, key visible elements)
   - This provides a reference point for the QA report

### Step 3: Execute Acceptance Steps

For each acceptance criterion, follow this pattern:

1. **Announce the step**:
   ```
   ## Verifying Criterion [N]/[Total]: [Description]

   Expected: [What should happen]
   Action: [What I'm about to do in the browser]
   ```

2. **Perform the browser actions**:
   - Navigate to the relevant page or section
   - Interact with UI elements (click buttons, fill forms, trigger actions)
   - Wait for responses, animations, or page transitions
   - Read the resulting page state

3. **Evaluate the result**:
   - Compare what happened against the expected outcome
   - Check the browser console for errors that occurred during the action
   - Note any visual issues, unexpected behaviors, or edge cases

4. **Record the verdict**:
   - **PASS**: The criterion is met as specified
   - **FAIL**: The criterion is not met — describe what went wrong
   - **PARTIAL**: The criterion is partially met — describe what works and what doesn't
   - **BLOCKED**: Cannot verify — describe what's preventing verification (e.g. missing test data, broken dependency)
   - **SKIP**: Not applicable in current environment — explain why

5. **After each criterion**, get a quick check using AskUserQuestion:
   - **Step [N] result**: [Brief description of what happened]. Does this match your expectations?
   - Options should cover: yes that's correct, no that's wrong (explain what I should see), let me fix something and retry, skip this criterion

   Tailor options based on the specific result observed.

### Step 4: Edge Case Exploration (Optional)

After verifying all explicit criteria, get preference using AskUserQuestion:
- **Edge cases**: All [N] criteria have been checked. Want me to explore edge cases?
- Options should cover: yes check common edge cases, yes check specific scenarios (I'll describe), no skip to report

**If edge case testing selected**, check common patterns:
- Empty states (no data, empty inputs)
- Boundary values (very long text, special characters, zero/negative numbers)
- Error states (network errors, invalid inputs, unauthorized access)
- Browser-specific behavior (responsive layout, keyboard navigation)
- Concurrent actions (double-click, rapid navigation)

Record each edge case finding with the same PASS/FAIL/PARTIAL/BLOCKED/SKIP pattern.

### Step 5: Generate QA Report

Write the QA report to `research/YYYY-MM-DD-qa-[ticket-id].md` using the template in [templates/qa-report.md](templates/qa-report.md).

The report should include:
- Ticket reference and summary
- Environment details (URL, branch, browser)
- Each criterion with its verdict, evidence, and any screenshots/GIFs recorded
- Edge case findings (if tested)
- Summary verdict
- List of issues found (if any)

### Step 6: Present Results & Next Steps

Present a summary of findings:

```
## QA Verification Complete

**Ticket**: [TICKET-ID] — [Title]
**Overall**: [N] PASS / [N] FAIL / [N] PARTIAL / [N] BLOCKED

### Issues Found
- [Issue 1 with severity]
- [Issue 2 with severity]

### Report
Written to: research/YYYY-MM-DD-qa-[ticket-id].md
```

Get next steps using AskUserQuestion:
- **Next steps**: How would you like to proceed with these results?
- Options should cover: File bugs for failures (creates Linear tickets), Comment results on the original ticket, Re-test failed criteria (after fixes), Mark ticket as Done (all passed), Just keep the report

Tailor options based on the actual results. If everything passed, emphasize the "mark as Done" option. If there are failures, emphasize bug filing.

**If "File bugs for failures" selected**:
- For each FAIL or PARTIAL result, create a sub-issue on the original ticket using Linear MCP tools
- Include the specific failure description, expected vs actual behavior, and steps to reproduce

**If "Comment results on the original ticket" selected**:
- Post a concise QA summary as a comment on the Linear ticket
- Include the overall verdict and any issues found

**If "Mark ticket as Done" selected**:
- Update the Linear ticket status to "Done" using the correct workspace MCP tools
- Post a comment confirming QA verification passed

## Guidelines

1. **Chrome required**: This skill cannot function without Chrome integration. Check for it early and fail gracefully if not available
2. **User controls the browser**: When login, CAPTCHA, or sensitive actions are needed, always defer to the user. Never attempt to enter credentials
3. **One criterion at a time**: Verify each acceptance criterion individually. Don't batch them — failures in batched checks are hard to diagnose
4. **Evidence over assertion**: When reporting results, describe what you observed in the browser, not just whether it "passed". Include what was on screen, what the console said, what changed
5. **Conservative verdicts**: When in doubt between PASS and PARTIAL, choose PARTIAL. False positives are worse than false negatives in QA
6. **No code changes**: This skill is pure verification. If a fix is needed, report it and let the user decide how to proceed
7. **Console is your friend**: Always check the browser console after each action. Errors that don't manifest visually still matter
8. **Workspace-aware**: Always use the correct workspace-namespaced Linear MCP tools and matching IDs from references/ids.md
9. **Record when possible**: If GIF recording is available, offer to record complex interactions for the QA report
