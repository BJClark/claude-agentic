#!/bin/bash
# lint-on-save.sh — Auto-detect and run project linter on saved files
# Used as a PostToolUse hook for Write|Edit in implement-plan skill
#
# Reads JSON input from stdin to get the file path that was written/edited.
# Detects the project's linter from common config files and runs it.
# Exit 0 = success (proceed), Exit 2 = blocking error (lint failed).

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Skip non-source files
case "$FILE_PATH" in
  *.md|*.txt|*.json|*.yaml|*.yml|*.toml|*.lock|*.log)
    exit 0
    ;;
esac

# Skip if no file path
if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# Detect linter based on project config files
if [ -f "Makefile" ] && grep -q "^lint:" Makefile 2>/dev/null; then
  make lint 2>&1 || { echo "Lint failed. Fix issues before continuing." >&2; exit 2; }
elif [ -f "pyproject.toml" ] && command -v ruff &>/dev/null; then
  ruff check "$FILE_PATH" 2>&1 || { echo "Ruff lint failed for $FILE_PATH" >&2; exit 2; }
elif [ -f "package.json" ] && command -v npx &>/dev/null; then
  if [ -f ".eslintrc.js" ] || [ -f ".eslintrc.json" ] || [ -f "eslint.config.js" ] || [ -f "eslint.config.mjs" ]; then
    npx eslint "$FILE_PATH" 2>&1 || { echo "ESLint failed for $FILE_PATH" >&2; exit 2; }
  fi
elif [ -f "go.mod" ] && command -v golangci-lint &>/dev/null; then
  golangci-lint run "$FILE_PATH" 2>&1 || { echo "golangci-lint failed for $FILE_PATH" >&2; exit 2; }
fi

exit 0
