# 🚀 Master TDD Reconstruction Prompt: Zellij Orchestrator Plugin

You are an expert AI software architect and systems engineer. Your task is to build the complete, production-grade **`zellij-orchestrator`** plugin for Google DeepMind's Antigravity CLI (`agy`) and Gemini CLI from scratch using **Test-Driven Development (TDD)** and contract specifications.

This plugin coordinates specialized autonomous AI agents across dedicated terminal panes in [Zellij](https://zellij.dev/) using an asynchronous file-backed message bus (`.agent-bus/`), deterministic JSON receipts, progressive skill runbooks, and automated lifecycle hooks.

---

## 📂 Required Repository Structure

Create every file and directory specified in this tree:

```text
.
├── plugin.json
├── hooks.json
├── layout.kdl
├── .gitignore
├── GEMINI.md
├── README.md
├── rules/
│   └── AGENTS.md
├── skills/
│   └── zellij-orchestrator/
│       ├── SKILL.md
│       ├── resources/
│       │   ├── layout.kdl
│       │   └── roles/
│       │       ├── _BASE.md
│       │       ├── dev.md
│       │       ├── qa.md
│       │       ├── devops.md
│       │       ├── reviewer.md
│       │       └── docs.md
│       └── scripts/
│           ├── init_bus.sh
│           └── launch.sh
├── scripts/
│   ├── install.sh
│   ├── bus_status.sh
│   ├── guardrails.sh
│   ├── validate_receipt.sh
│   └── check_pending_receipt.sh
└── tests/
    ├── worker_hook_smoke.py
    ├── dev_check.py
    ├── test_qa_check.py
    ├── autowake_check.py
    ├── e2e_hook_test.py
    ├── worker1_math.py
    ├── worker2_anagram.py
    └── worker2_string.py
```

---

## 🛠️ Execution Pipeline (Test-Driven Development)

Follow this 5-stage TDD pipeline, running the verification commands at each step:

---

### 🧪 Stage 1: Build the Ground Truth Test Harness (`tests/`)

Write `tests/e2e_hook_test.py` to verify the 4 lifecycle hooks via `subprocess.run`:
1. `test_bus_status_hook`: Invokes `./scripts/bus_status.sh` with JSON input `{"workspacePaths": [...]}` and asserts valid JSON output.
2. `test_guardrails_blocks_destructive`: Sends `run_command` with `"CommandLine": "rm -rf /"` and asserts `{"decision": "deny"}`.
3. `test_guardrails_blocks_role_edit_for_workers`: Sends `write_to_file` targeting `.agent-bus/roles/dev.md` with env `ZELLIJ_PANE_ID=2` and asserts `{"decision": "deny"}`.
4. `test_check_pending_receipt_worker_isolation`: In an isolated temp workspace with Task A for Worker 1 (`dev`, Pane 2) and Task B for Worker 2 (`qa`, Pane 1):
   - When Worker 1 completes Task A, `./scripts/check_pending_receipt.sh` must return `{}` for Worker 1 even if Task B is incomplete.
   - For Worker 2, it must return `{"decision": "continue"}` due to missing receipt for Task B.

Also create unit test fixtures in `tests/`: `worker_hook_smoke.py`, `dev_check.py`, `test_qa_check.py`, `autowake_check.py`, `worker1_math.py`, `worker2_anagram.py`, `worker2_string.py`.

---

### 📦 Stage 2: Core Manifests, Rules & Layout

1. **`plugin.json`:**
   - Manifest for plugin `zellij-orchestrator` (v1.0.0, MIT, author "Antigravity Engineering", keywords for multi-agent, zellij, terminal, antigravity).
2. **`hooks.json`:**
   - `PreToolUse`: Matcher `run_command|write_to_file|replace_file_content` -> `./scripts/guardrails.sh` (timeout 5).
   - `PostToolUse`: Matcher `write_to_file|replace_file_content` -> `./scripts/validate_receipt.sh` (timeout 5).
   - `PreInvocation`: `./scripts/bus_status.sh` (timeout 3).
   - `Stop`: `./scripts/check_pending_receipt.sh` (timeout 5).
3. **`layout.kdl` & `skills/zellij-orchestrator/resources/layout.kdl`:**
   - Top tab-bar, bottom status-bar.
   - Left pane: `Orchestrator` (`agy` with initial prompt to determine identity and greet user).
   - Right panes (split horizontally): `Worker 2 (qa)` and `Worker 1 (dev)`.
4. **`rules/AGENTS.md`:**
   - Dynamic identity protocol reading `$ZELLIJ_PANE_ID`:
     - `0`: Lead Orchestrator (System Architect, task decomposition, no direct app code).
     - `2`: Worker 1 (`dev`, implementation specialist).
     - `1`: Worker 2 (`qa`, test & verification specialist).
     - Standby worker fallback for other panes.
     - Universal contract requiring all workers to write `.agent-bus/results/<task_id>.json`.
5. **`GEMINI.md` & `.gitignore`:**
   - Contributor guidelines, strict bash standards (`set -euo pipefail`, dynamic paths), `.agent-bus/` ignore.

---

### ⚙️ Stage 3: Implement Shell Scripts to Satisfy Tests

All bash scripts must use `set -euo pipefail`, resolve `SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"`, and handle JSON with `jq`:

1. **`scripts/guardrails.sh` (PreToolUse):**
   - Blocks dangerous commands (`zellij kill-all-sessions`, `git reset --hard HEAD~`, `rm -rf /`) with `decision: deny`.
   - Blocks worker panes (`$ZELLIJ_PANE_ID != "0"` and `!= "standalone"`) from modifying `.agent-bus/roles/*.md`.
2. **`scripts/validate_receipt.sh` (PostToolUse):**
   - Intercepts writes to `.agent-bus/results/*.json`.
   - Validates `.taskId`, `.status`, `.role`, `.summary`.
   - If valid and running in a worker pane, triggers auto-wake to Pane 0 via `zellij action write-chars --pane-id 0` and `send-keys "Enter"`.
3. **`scripts/check_pending_receipt.sh` (Stop Hook):**
   - If running in worker pane, checks the latest task in `.agent-bus/tasks/*.md` matching worker's role/pane pattern.
   - If matching task has no receipt in `.agent-bus/results/<taskId>.json`, outputs `{"decision": "continue", "reason": "..."}` to block early exit.
4. **`scripts/bus_status.sh` (PreInvocation):**
   - Outputs ephemeral message with active task count, completed receipt count, and current Pane ID.
5. **`skills/zellij-orchestrator/scripts/init_bus.sh` & `launch.sh`:**
   - `init_bus.sh`: Creates `.agent-bus/{tasks,results,roles}` and copies base role templates.
   - `launch.sh`: Checks `zellij` and `agy`, initializes bus, and execs `zellij --layout layout.kdl`.
6. **`scripts/install.sh`:**
   - Symlinks repo to `~/.gemini/config/plugins/zellij-orchestrator` and creates `~/.local/bin/agy-multi`.

**Iterate against `python3 tests/e2e_hook_test.py` until all tests pass.**

---

### 🎭 Stage 4: Skill Runbook & Role Catalog

1. **`skills/zellij-orchestrator/SKILL.md`:**
   - Orchestrator 5-step workflow: Init bus ➔ Formulate brief ➔ Trigger worker ➔ Monitor receipts & auto-wake ➔ Screen debug.
2. **`skills/zellij-orchestrator/resources/roles/_BASE.md`:**
   - Universal base worker protocol: deliberate engineering reasoning, scope isolation, non-interactive CLI execution.
   - Base JSON receipt envelope: `taskId`, `role`, `workerPaneId`, `timestamp`, `status`, `summary`, `filesCreated`, `filesModified`, `errorsOrWarnings`, `payload`.
3. **Role Specifications (`dev.md`, `qa.md`, `devops.md`, `reviewer.md`, `docs.md`):**
   - Inherit `_BASE.md`.
   - Define role-specific mindset, responsibilities, standards, and specialized `payload` JSON schemas.

---

### 📖 Stage 5: Documentation & Final Certification

1. **`README.md`:**
   - Complete project overview, architecture diagram, lifecycle hooks guide, installation instructions, sequence diagram, and MIT license.
2. **Execute Full Certification Suite:**
   ```bash
   chmod +x scripts/*.sh skills/zellij-orchestrator/scripts/*.sh
   jq . plugin.json >/dev/null
   jq . hooks.json >/dev/null
   for s in scripts/*.sh skills/zellij-orchestrator/scripts/*.sh; do bash -n "$s"; done
   python3 tests/worker_hook_smoke.py
   python3 tests/dev_check.py
   python3 tests/test_qa_check.py
   python3 tests/autowake_check.py
   python3 tests/e2e_hook_test.py
   python3 tests/worker1_math.py
   python3 tests/worker2_anagram.py
   python3 tests/worker2_string.py
   ```
