# Phase 3: Lifecycle Hooks & Shell Scripts

You are executing **Phase 3 of 5** for reconstructing the **`zellij-orchestrator`** plugin repository.

## 🎯 Phase Objective
In this phase, you will implement all 4 Antigravity/Gemini lifecycle hook scripts (`scripts/guardrails.sh`, `scripts/validate_receipt.sh`, `scripts/bus_status.sh`, `scripts/check_pending_receipt.sh`), skill helper scripts (`skills/zellij-orchestrator/scripts/init_bus.sh`, `skills/zellij-orchestrator/scripts/launch.sh`), and the automated global installer (`scripts/install.sh`).

---

## 📂 Deliverables for Phase 3

Create the following 7 shell script files with exact contents specified below:

1. `skills/zellij-orchestrator/scripts/init_bus.sh`
2. `skills/zellij-orchestrator/scripts/launch.sh`
3. `scripts/bus_status.sh`
4. `scripts/guardrails.sh`
5. `scripts/validate_receipt.sh`
6. `scripts/check_pending_receipt.sh`
7. `scripts/install.sh`

---

## 📄 File Specifications

### 1. `skills/zellij-orchestrator/scripts/init_bus.sh`
```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TARGET_DIR="${1:-.}"

echo "🚀 Initializing Agent Bus in $TARGET_DIR/.agent-bus..."

mkdir -p "$TARGET_DIR/.agent-bus/tasks"
mkdir -p "$TARGET_DIR/.agent-bus/results"
mkdir -p "$TARGET_DIR/.agent-bus/roles"

if [ -d "$SKILL_ROOT/resources/roles" ]; then
  cp -n "$SKILL_ROOT/resources/roles"/*.md "$TARGET_DIR/.agent-bus/roles/" 2>/dev/null || true
fi

echo "✅ Agent Bus initialized successfully!"
echo "   - Tasks:   $TARGET_DIR/.agent-bus/tasks/"
echo "   - Results: $TARGET_DIR/.agent-bus/results/"
echo "   - Roles:   $TARGET_DIR/.agent-bus/roles/"
```

---

### 2. `skills/zellij-orchestrator/scripts/launch.sh`
```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LAYOUT_FILE="$SKILL_ROOT/resources/layout.kdl"

if ! command -v zellij &> /dev/null; then
    echo "❌ Error: 'zellij' executable not found in PATH. Install via 'brew install zellij'." >&2
    exit 1
fi

if ! command -v agy &> /dev/null; then
    echo "⚠️ Warning: 'agy' (Antigravity CLI) not found in PATH. Ensure agy is installed." >&2
fi

"$SCRIPT_DIR/init_bus.sh" .

echo "⚡ Starting Zellij Multi-Agent Orchestration Session..."
exec zellij --layout "$LAYOUT_FILE"
```

---

### 3. `scripts/bus_status.sh` (PreInvocation Hook)
```bash
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
```

---

### 4. `scripts/guardrails.sh` (PreToolUse Hook)
```bash
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
```

---

### 5. `scripts/validate_receipt.sh` (PostToolUse Hook)
```bash
#!/usr/bin/env bash
set -euo pipefail

PAYLOAD=$(cat)
WORKSPACE_ROOT=$(echo "$PAYLOAD" | jq -r '.workspacePaths[0] // "."' 2>/dev/null || echo ".")
if [ -d "$WORKSPACE_ROOT" ]; then
    cd "$WORKSPACE_ROOT"
fi

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
            ZELLIJ_SESSION_ARGS=()
            if [ -n "${ZELLIJ_SESSION_NAME:-}" ]; then
                ZELLIJ_SESSION_ARGS=("--session" "$ZELLIJ_SESSION_NAME")
            fi
            (
                sleep 1
                zellij "${ZELLIJ_SESSION_ARGS[@]}" action write-chars --pane-id 0 "Worker $PANE_ID completed task $TASK_NAME. Receipt verified at $TARGET_FILE." 2>/dev/null || true
                zellij "${ZELLIJ_SESSION_ARGS[@]}" action send-keys --pane-id 0 "Enter" 2>/dev/null || true
            ) &
            echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] [PostToolUse] Pane: $PANE_ID | DISPATCHED auto-wake signal to Pane 0 for $TASK_NAME" >> .agent-bus/hooks.log 2>/dev/null || true
        fi
    else
        echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] [PostToolUse] Pane: $PANE_ID | WARNING: Malformed receipt: $TARGET_FILE" >> .agent-bus/hooks.log 2>/dev/null || true
    fi
fi

echo "{}"
```

---

### 6. `scripts/check_pending_receipt.sh` (Stop Hook)
```bash
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
```

---

### 7. `scripts/install.sh` (Automated Installer)
```bash
#!/usr/bin/env bash
set -euo pipefail

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET_GLOBAL_DIR="$HOME/.gemini/config/plugins/zellij-orchestrator"
BIN_DIR="$HOME/.local/bin"

echo "📦 Installing Zellij Orchestrator Plugin..."

# Make all scripts executable
chmod +x "$PLUGIN_DIR"/scripts/*.sh "$PLUGIN_DIR"/skills/zellij-orchestrator/scripts/*.sh

# Create target global plugin directory
mkdir -p "$HOME/.gemini/config/plugins"

# Remove existing symlink/directory if present
rm -rf "$TARGET_GLOBAL_DIR"

# Symlink this repo to global plugins for automatic updates
ln -s "$PLUGIN_DIR" "$TARGET_GLOBAL_DIR"
echo "✅ Symlinked plugin to: $TARGET_GLOBAL_DIR"

# Install global agy-multi command if bin dir exists or create it
mkdir -p "$BIN_DIR"
cat <<'EOF' > "$BIN_DIR/agy-multi"
#!/usr/bin/env bash
exec "$HOME/.gemini/config/plugins/zellij-orchestrator/skills/zellij-orchestrator/scripts/launch.sh" "$@"
EOF
chmod +x "$BIN_DIR/agy-multi"

echo "✅ Created global CLI command: $BIN_DIR/agy-multi"
echo ""
echo "🎉 Installation Complete!"
echo "You can now run 'agy-multi' from any project directory to launch a multi-agent orchestration session."
```

---

## 🔍 Phase 3 Verification Commands
Run the following validation commands to confirm Phase 3 completion:

```bash
# 1. Ensure all shell scripts are executable
chmod +x scripts/*.sh skills/zellij-orchestrator/scripts/*.sh

# 2. Syntax check all bash scripts using bash -n
for script in scripts/*.sh skills/zellij-orchestrator/scripts/*.sh; do
    bash -n "$script" && echo "✅ Syntax OK: $script"
done
```
