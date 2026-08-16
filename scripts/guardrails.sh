#!/usr/bin/env bash
set -euo pipefail

PAYLOAD=$(cat)
WORKSPACE_ROOT=$(echo "$PAYLOAD" | jq -r '.workspacePaths[0] // "."' 2>/dev/null || echo ".")
if [ -d "$WORKSPACE_ROOT" ]; then
    cd "$WORKSPACE_ROOT"
fi

TOOL_NAME=$(echo "$PAYLOAD" | jq -r '.toolCall.name // empty')
PANE_ID="${ZELLIJ_PANE_ID:-standalone}"

mkdir -p .agent-bus
echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] [PreToolUse] Pane: $PANE_ID | Tool: $TOOL_NAME" >> .agent-bus/hooks.log 2>/dev/null || true

# 1. Guard against destructive shell commands
if [ "$TOOL_NAME" = "run_command" ]; then
    CMD=$(echo "$PAYLOAD" | jq -r '.toolCall.args.CommandLine // empty')
    
    if echo "$CMD" | grep -Eq 'zellij kill-all-sessions|git reset --hard HEAD~|rm -rf /'; then
        echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] [PreToolUse] BLOCKED destructive command: $CMD" >> .agent-bus/hooks.log 2>/dev/null || true
        cat <<EOF
{
  "decision": "deny",
  "reason": "Destructive command blocked by multi-agent safety gate: $CMD"
}
EOF
        exit 0
    fi
fi

# 2. Guard against worker edits to protected role definitions
if [ "$TOOL_NAME" = "write_to_file" ] || [ "$TOOL_NAME" = "replace_file_content" ]; then
    TARGET_FILE=$(echo "$PAYLOAD" | jq -r '.toolCall.args.TargetFile // empty')
    
    if [ "$PANE_ID" != "0" ] && [ "$PANE_ID" != "standalone" ] && [[ "$TARGET_FILE" == *".agent-bus/roles/"* ]]; then
        echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] [PreToolUse] BLOCKED role edit by worker $PANE_ID: $TARGET_FILE" >> .agent-bus/hooks.log 2>/dev/null || true
        cat <<EOF
{
  "decision": "deny",
  "reason": "Scope violation: Worker panes cannot modify protected role specifications in .agent-bus/roles/."
}
EOF
        exit 0
    fi
fi

cat <<EOF
{
  "decision": "allow"
}
EOF
