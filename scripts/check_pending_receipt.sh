#!/usr/bin/env bash
set -euo pipefail

cat >/dev/null # Consume stdin

PANE_ID="${ZELLIJ_PANE_ID:-standalone}"

mkdir -p .agent-bus
echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] [Stop] Turn completion evaluated for Pane: $PANE_ID" >> .agent-bus/hooks.log 2>/dev/null || true

if [ "$PANE_ID" = "0" ] || [ "$PANE_ID" = "standalone" ] || [ ! -d ".agent-bus/tasks" ]; then
    echo "{}"
    exit 0
fi

LATEST_TASK=$(find .agent-bus/tasks -type f -name "*.md" 2>/dev/null | sort | tail -n 1)

if [ -n "$LATEST_TASK" ]; then
    TASK_ID=$(basename "$LATEST_TASK" .md)
    RECEIPT_FILE=".agent-bus/results/${TASK_ID}.json"

    if [ ! -f "$RECEIPT_FILE" ]; then
        echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] [Stop] INTERCEPTED exit for worker $PANE_ID: Missing receipt $RECEIPT_FILE" >> .agent-bus/hooks.log 2>/dev/null || true
        cat <<EOF
{
  "decision": "continue",
  "reason": "CRITICAL: You are running as Worker (Pane $PANE_ID) and have an assigned task '$TASK_ID', but have not yet written the completion receipt to '$RECEIPT_FILE'. You MUST output the completion receipt before completing your turn."
}
EOF
        exit 0
    fi
fi

echo "{}"
