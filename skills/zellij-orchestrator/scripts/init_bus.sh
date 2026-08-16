#!/usr/bin/env bash
set -euo pipefail

# Determine script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TARGET_DIR="${1:-.}"

echo "🚀 Initializing Agent Bus in $TARGET_DIR/.agent-bus..."

mkdir -p "$TARGET_DIR/.agent-bus/tasks"
mkdir -p "$TARGET_DIR/.agent-bus/results"
mkdir -p "$TARGET_DIR/.agent-bus/roles"

# Copy base role catalog if not already present
if [ -d "$SKILL_ROOT/resources/roles" ]; then
  cp -n "$SKILL_ROOT/resources/roles"/*.md "$TARGET_DIR/.agent-bus/roles/" 2>/dev/null || true
fi

echo "✅ Agent Bus initialized successfully!"
echo "   - Tasks:   $TARGET_DIR/.agent-bus/tasks/"
echo "   - Results: $TARGET_DIR/.agent-bus/results/"
echo "   - Roles:   $TARGET_DIR/.agent-bus/roles/"
