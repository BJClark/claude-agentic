#!/bin/bash
# verify-artifact-exists.sh — TaskCompleted hook for DDD and review workflows
# Verifies that the teammate actually produced output artifacts before marking done.
# Exit 0 = allow completion, Exit 2 = block completion with feedback.

INPUT=$(cat)
TASK_SUBJECT=$(echo "$INPUT" | jq -r '.task_subject // empty')
TASK_DESC=$(echo "$INPUT" | jq -r '.task_description // empty')

# Extract expected output file from task description (look for file paths)
EXPECTED_FILE=$(echo "$TASK_DESC" | grep -oE '(research|plans|thoughts)/[^ ]+\.md' | head -1)

if [ -n "$EXPECTED_FILE" ] && [ ! -f "$EXPECTED_FILE" ]; then
  echo "Task '$TASK_SUBJECT' expects artifact at $EXPECTED_FILE but it doesn't exist yet." >&2
  exit 2
fi

exit 0
