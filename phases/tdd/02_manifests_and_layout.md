# Phase 2: Manifests, Agent Rules & Zellij Layout

You are executing **Phase 2 of 5 (TDD Pipeline)** for reconstructing the **`zellij-orchestrator`** plugin repository.

## 🎯 Phase Objective
In this phase, you will establish the declarative plugin manifests, Zellij terminal layout, agent dynamic identity determination rules, and contributor guidelines.

---

## 📂 Deliverables for Phase 2

Create the following 6 files:

1. `plugin.json` (Plugin Manifest)
2. `hooks.json` (Lifecycle Automation Hooks)
3. `layout.kdl` & `skills/zellij-orchestrator/resources/layout.kdl` (Default Zellij Layout)
4. `rules/AGENTS.md` (Dynamic Identity Determination Protocol)
5. `GEMINI.md` (Architecture & Contributor Guidelines)
6. `.gitignore`

---

## 📋 File Specifications & Invariants

### 1. `plugin.json`
- **Name:** `zellij-orchestrator`
- **Version:** `1.0.0`
- **Description:** Multi-agent terminal orchestrator for Zellij using Antigravity CLI (`agy`) with asynchronous file-backed messaging bus and deterministic receipt contracts.
- **Keywords:** `["multi-agent", "orchestration", "zellij", "terminal", "antigravity", "gemini-cli", "agent-bus"]`

### 2. `hooks.json`
Define the `zellij-bus-gates` object mapping to 4 lifecycle triggers:
- **`PreToolUse`:** Matcher `run_command|write_to_file|replace_file_content` -> executes `./scripts/guardrails.sh` (timeout 5s).
- **`PostToolUse`:** Matcher `write_to_file|replace_file_content` -> executes `./scripts/validate_receipt.sh` (timeout 5s).
- **`PreInvocation`:** Executes `./scripts/bus_status.sh` (timeout 3s).
- **`Stop`:** Executes `./scripts/check_pending_receipt.sh` (timeout 5s).

### 3. `layout.kdl` & `skills/zellij-orchestrator/resources/layout.kdl`
Define a Zellij layout with:
- Top `tab-bar` (size 1)
- Vertical split containing:
  - Left pane: `name="Orchestrator" command="agy"` with args `-i "Determine your identity based on active rules/skills and greet the user with your role and purpose."`
  - Right pane (horizontal split):
    - Top: `name="Worker 2 (qa)" command="agy"` (same args)
    - Bottom: `name="Worker 1 (dev)" command="agy"` (same args)
- Bottom `status-bar` (size 1)

### 4. `rules/AGENTS.md`
Define identity determination based on `$ZELLIJ_PANE_ID`:
- **`$ZELLIJ_PANE_ID == 0` (or title Orchestrator):** Lead Orchestrator / Senior Architect. Breaks down goals, dispatches tasks, does not write app code directly. Startup greeting: *"Hello! I am the Lead Orchestrator..."*
- **`$ZELLIJ_PANE_ID == 2`:** Worker 1 (`dev`). Implements code, refactors, fixes bugs. Startup greeting: *"Hello! I am Worker 1 (dev)..."*
- **`$ZELLIJ_PANE_ID == 1`:** Worker 2 (`qa`). Writes tests, verifies quality. Startup greeting: *"Hello! I am Worker 2 (qa)..."*
- **Other Panes:** Base Worker in standby awaiting task briefs.
- **Universal Worker Contract:** Every worker modifying files must write `.agent-bus/results/<task_id>.json` before completing its turn.

### 5. `GEMINI.md` & `.gitignore`
- `GEMINI.md`: File map table, shell scripting standards (`set -euo pipefail`, dynamic `SCRIPT_DIR`), 4 hooks summary, role spec pointers.
- `.gitignore`: Excludes `.agent-bus/`, `*.log`, OS/editor temp files.

---

## 🔍 Phase 2 Verification Gate
```bash
jq . plugin.json >/dev/null && echo "✅ plugin.json valid"
jq . hooks.json >/dev/null && echo "✅ hooks.json valid"
test -f layout.kdl && test -f rules/AGENTS.md && test -f GEMINI.md && test -f .gitignore && echo "✅ All Phase 2 files present"
```
