#!/usr/bin/env bash
set -euo pipefail
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CLAUDE_DIR="$HOME/.claude"

echo "Syncing skills..."
rsync -av --delete "$REPO_DIR/skills/" "$CLAUDE_DIR/skills/"

echo "Syncing commands..."
rsync -av "$REPO_DIR/commands/" "$CLAUDE_DIR/commands/"

echo "Syncing agents..."
rsync -av --delete "$REPO_DIR/agents/" "$CLAUDE_DIR/agents/"

echo "Done."
