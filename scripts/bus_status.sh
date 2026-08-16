#!/usr/bin/env bash
set -euo pipefail

PAYLOAD=$(cat)
WORKSPACE_ROOT=$(echo "$PAYLOAD" | jq -r '.workspacePaths[0] // "."' 2>/dev/null || echo ".")
if [ -d "$WORKSPACE_ROOT" ]; then
    cd "$WORKSPACE_ROOT"
fi

PANE_ID="${ZELLIJ_PANE_ID:-standalone}"

mkdir -p .agent-bus
echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] [PreInvocation] Triggered for Pane: $PANE_ID" >> .agent-bus/hooks.log 2>/dev/null || true

if [ ! -d ".agent-bus/tasks" ]; then
    echo "{}"
    exit 0
fi

TOTAL_TASKS=$(find .agent-bus/tasks -type f -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
TOTAL_RESULTS=$(find .agent-bus/results -type f -name "*.json" 2>/dev/null | wc -l | tr -d ' ')

if [ "$TOTAL_TASKS" -gt 0 ]; then
    cat <<EOF
{
  "injectSteps": [
    {
      "ephemeralMessage": "[Agent Bus Status] Active tasks: $TOTAL_TASKS | Completed receipts: $TOTAL_RESULTS | Current Pane: $PANE_ID"
    }
  ]
}
EOF
else
    echo "{}"
fi
