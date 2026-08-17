# Phase 3: Lifecycle Hooks & Shell Scripts (TDD Implementation)

You are executing **Phase 3 of 5 (TDD Pipeline)** for reconstructing the **`zellij-orchestrator`** plugin repository.

## 🎯 Phase Objective
Implement the 7 shell scripts to satisfy all tests in `tests/e2e_hook_test.py` and pass syntax/permission checks.

---

## 📂 Deliverables for Phase 3

Implement the following 7 shell scripts:

1. `scripts/bus_status.sh` (PreInvocation Hook)
2. `scripts/guardrails.sh` (PreToolUse Hook)
3. `scripts/validate_receipt.sh` (PostToolUse Hook)
4. `scripts/check_pending_receipt.sh` (Stop Hook)
5. `scripts/install.sh` (Plugin & CLI Installer)
6. `skills/zellij-orchestrator/scripts/init_bus.sh` (Bus Initializer)
7. `skills/zellij-orchestrator/scripts/launch.sh` (Session Launcher)

---

## 🛠️ Shell Scripting Standards (Mandatory)
1. **Strict Mode:** Start every script with `#!/usr/bin/env bash` and `set -euo pipefail`.
2. **Dynamic Path Resolution:** Resolve directories with `SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"`. Never hardcode absolute user paths.
3. **Safe JSON Handling:** Read JSON payloads from `stdin` using `jq` with sensible defaults.
4. **Permissions:** Ensure all `.sh` scripts have executable permissions (`chmod +x`).

---

## 🪝 Behavioral Specifications

### 1. `scripts/bus_status.sh` (PreInvocation)
- Ingests JSON payload from stdin; extracts `.workspacePaths[0] // "."`.
- Resolves `$ZELLIJ_PANE_ID` (default `"standalone"`).
- Counts active `.md` tasks in `.agent-bus/tasks` and `.json` results in `.agent-bus/results`.
- If tasks > 0, outputs JSON with `{"injectSteps": [{"ephemeralMessage": "[Agent Bus Status] Active tasks: X | Completed receipts: Y | Current Pane: Z"}]}`. Otherwise outputs `{}`.

### 2. `scripts/guardrails.sh` (PreToolUse)
- Ingests JSON payload containing `.toolCall`.
- If `toolCall.name == "run_command"`, checks `CommandLine`:
  - If matches `zellij kill-all-sessions`, `git reset --hard HEAD~`, or `rm -rf /`, outputs `{"decision": "deny", "reason": "..."}` and exits 0.
- If `toolCall.name` is `write_to_file` or `replace_file_content`:
  - If `$ZELLIJ_PANE_ID` is not `"0"` and not `"standalone"` AND `TargetFile` contains `.agent-bus/roles/`, outputs `{"decision": "deny", "reason": "Scope violation..."}` and exits 0.
- Otherwise outputs `{"decision": "allow"}`.

### 3. `scripts/validate_receipt.sh` (PostToolUse)
- Checks if written `TargetFile` matches `.agent-bus/results/*.json`. If not, outputs `{}` and exits 0.
- Validates JSON schema: must contain `.taskId`, `.status`, `.role`, `.summary`.
- If valid and running in a worker pane (`$ZELLIJ_PANE_ID` is not 0 or standalone), sends an auto-wake command to Pane 0 via `zellij action write-chars --pane-id 0 "Worker $PANE_ID completed task $TASK_NAME. Receipt verified at $TARGET_FILE."` and `zellij action send-keys --pane-id 0 "Enter"`.
- Outputs `{}`.

### 4. `scripts/check_pending_receipt.sh` (Stop Hook)
- Bypasses check if `$ZELLIJ_PANE_ID` is `"0"` or `"standalone"`, or `.agent-bus/tasks` doesn't exist (outputs `{}`).
- Maps `$ZELLIJ_PANE_ID` to role patterns (Pane 2 -> `Worker 1|dev|Pane 2`, Pane 1 -> `Worker 2|qa|Pane 1`, else `Worker $PANE_ID|Pane $PANE_ID`).
- Checks the newest task in `.agent-bus/tasks/*.md` matching the worker's pattern:
  - If `.agent-bus/results/<taskId>.json` does not exist, intercepts exit: `{"decision": "continue", "reason": "CRITICAL: You are running as Worker..."}`.
- Otherwise outputs `{}`.

### 5. `skills/zellij-orchestrator/scripts/init_bus.sh` & `launch.sh`
- `init_bus.sh`: Creates `.agent-bus/tasks`, `.agent-bus/results`, `.agent-bus/roles` in target directory, copying roles from skill resources if present.
- `launch.sh`: Verifies `zellij` and `agy` in PATH, initializes bus via `init_bus.sh`, and runs `exec zellij --layout "$LAYOUT_FILE"`.

### 6. `scripts/install.sh`
- Grants `chmod +x` to all `.sh` scripts.
- Symlinks repository to `~/.gemini/config/plugins/zellij-orchestrator`.
- Creates executable global launcher at `~/.local/bin/agy-multi`.

---

## 🔍 Phase 3 TDD Verification Gate (Must be 100% Green)
```bash
# 1. Make all scripts executable
chmod +x scripts/*.sh skills/zellij-orchestrator/scripts/*.sh

# 2. Syntax check
for s in scripts/*.sh skills/zellij-orchestrator/scripts/*.sh; do bash -n "$s"; done

# 3. Run E2E test suite
python3 tests/e2e_hook_test.py
```
