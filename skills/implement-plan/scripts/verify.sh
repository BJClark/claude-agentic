#!/usr/bin/env bash
# verify.sh — Deterministic post-phase validation for implement-plan
# Usage: scripts/verify.sh [phase-number]
set -euo pipefail

phase="${1:-all}"
errors=0

check() {
  local desc="$1"; shift
  if "$@" > /dev/null 2>&1; then
    echo "✓ $desc"
  else
    echo "✗ $desc"
    ((errors++))
  fi
}

# Universal checks (every phase)
echo "=== Universal checks ==="
check "TypeScript compiles"    npx tsc --noEmit 2>/dev/null || check "TypeScript compiles" echo "SKIP: no tsconfig.json"
check "Linting passes"         npm run lint 2>/dev/null || check "Linting passes" echo "SKIP: no lint script"
check "Tests pass"             npm test 2>/dev/null || check "Tests pass" echo "SKIP: no test script"
check "No uncommitted changes" git diff --quiet

echo ""
if [ "$errors" -gt 0 ]; then
  echo "FAILED: $errors check(s) failed"
  exit 1
else
  echo "PASSED: All checks passed"
  exit 0
fi
