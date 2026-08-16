#!/usr/bin/env bash
set -euo pipefail

PAYLOAD=$(cat)
WORKSPACE_ROOT=$(echo "$PAYLOAD" | jq -r '.workspacePaths[0] // "."' 2>/dev/null || echo ".")
if [ -d "$WORKSPACE_ROOT" ]; then
    cd "$WORKSPACE_ROOT"
fi

PANE_ID="${ZELLIJ_PANE_ID:-standalone}"

mkdir -p .agent-bus
echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] [Stop] Turn completion evaluated for Pane: $PANE_ID" >> .agent-bus/hooks.log 2>/dev/null || true

if [ "$PANE_ID" = "0" ] || [ "$PANE_ID" = "standalone" ] || [ ! -d ".agent-bus/tasks" ]; then
    echo "{}"
    exit 0
fi

# Determine worker identifier patterns for matching
# Pane 2 -> Worker 1 / dev; Pane 1 -> Worker 2 / qa
ROLE_PATTERN=""
case "$PANE_ID" in
    2) ROLE_PATTERN="Worker 1|dev|Pane 2" ;;
    1) ROLE_PATTERN="Worker 2|qa|Pane 1" ;;
    *) ROLE_PATTERN="Worker $PANE_ID|Pane $PANE_ID" ;;
esac

# Find all tasks sorted from newest to oldest
TASK_FILES=$(find .agent-bus/tasks -type f -name "*.md" 2>/dev/null | sort -r || true)

for TASK_PATH in $TASK_FILES; do
    [ -f "$TASK_PATH" ] || continue
    
    # Check if this task targets this worker/role
    if grep -Eqi "$ROLE_PATTERN" "$TASK_PATH"; then
        TASK_ID=$(basename "$TASK_PATH" .md)
        RECEIPT_FILE=".agent-bus/results/${TASK_ID}.json"
        
        # If the latest task assigned to this worker lacks a receipt, enforce completion
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
        
        # If the most recent task for this worker already has a receipt, we don't need to check older ones
        break
    fi
done

echo "{}"
