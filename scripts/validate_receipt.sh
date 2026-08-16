#!/usr/bin/env bash
set -euo pipefail

PAYLOAD=$(cat)
TARGET_FILE=$(echo "$PAYLOAD" | jq -r '.toolCall.args.TargetFile // empty' 2>/dev/null || true)
PANE_ID="${ZELLIJ_PANE_ID:-standalone}"

mkdir -p .agent-bus

# Fast exit if not writing a receipt
if [[ "$TARGET_FILE" != *".agent-bus/results/"* ]] || [[ "$TARGET_FILE" != *".json" ]]; then
    echo "{}"
    exit 0
fi

# Validate JSON schema if file exists
if [ -f "$TARGET_FILE" ]; then
    if jq -e '.taskId and .status and .role and .summary' "$TARGET_FILE" >/dev/null 2>&1; then
        echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] [PostToolUse] Pane: $PANE_ID | VALID receipt: $TARGET_FILE" >> .agent-bus/hooks.log 2>/dev/null || true
        
        # Auto-wake Orchestrator (Pane 0) when worker delivers a valid receipt
        if [ "$PANE_ID" != "0" ] && [ "$PANE_ID" != "standalone" ]; then
            TASK_NAME=$(basename "$TARGET_FILE" .json)
            (
                sleep 1
                zellij action write-chars --pane-id 0 "Worker $PANE_ID completed task $TASK_NAME. Receipt verified at $TARGET_FILE." 2>/dev/null || true
                zellij action send-keys --pane-id 0 "Enter" 2>/dev/null || true
            ) &
            echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] [PostToolUse] Pane: $PANE_ID | DISPATCHED auto-wake signal to Pane 0 for $TASK_NAME" >> .agent-bus/hooks.log 2>/dev/null || true
        fi
    else
        echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] [PostToolUse] Pane: $PANE_ID | WARNING: Malformed receipt: $TARGET_FILE" >> .agent-bus/hooks.log 2>/dev/null || true
    fi
fi

echo "{}"
