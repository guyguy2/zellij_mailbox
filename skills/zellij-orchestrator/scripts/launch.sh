#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LAYOUT_FILE="$SKILL_ROOT/resources/layout.kdl"

# Verify dependencies
if ! command -v zellij &> /dev/null; then
    echo "❌ Error: 'zellij' executable not found in PATH. Install via 'brew install zellij'." >&2
    exit 1
fi

if ! command -v agy &> /dev/null; then
    echo "⚠️ Warning: 'agy' (Antigravity CLI) not found in PATH. Ensure agy is installed." >&2
fi

# Initialize agent bus in current directory
"$SCRIPT_DIR/init_bus.sh" .

echo "⚡ Starting Zellij Multi-Agent Orchestration Session..."
exec zellij --layout "$LAYOUT_FILE"
