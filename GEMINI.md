# Zellij Mailbox Plugin: Contributor & Architecture Guidelines

This repository implements the **`zellij-orchestrator`** plugin for Google DeepMind's Antigravity CLI (`agy`) and Gemini CLI.

When working on or modifying this codebase, follow these architectural principles and engineering guidelines:

---

## 🏛️ Plugin Architecture & File Map

| Directory / File | Description | Guidelines |
| :--- | :--- | :--- |
| [`plugin.json`](file:///Users/guy/dev/ai/ai-tools/zellij_mailbox/plugin.json) | Plugin manifest & metadata | Keep version, keywords, and description synchronized. |
| [`hooks.json`](file:///Users/guy/dev/ai/ai-tools/zellij_mailbox/hooks.json) | Lifecycle automation hooks | Defines triggers for `PreInvocation`, `PreToolUse`, `PostToolUse`, `Stop`. |
| [`rules/AGENTS.md`](file:///Users/guy/dev/ai/ai-tools/zellij_mailbox/rules/AGENTS.md) | Dynamic role binding rule | Binds `$ZELLIJ_PANE_ID` to agent roles (`Orchestrator`, `dev`, `qa`). |
| [`skills/zellij-orchestrator/SKILL.md`](file:///Users/guy/dev/ai/ai-tools/zellij_mailbox/skills/zellij-orchestrator/SKILL.md) | Orchestrator Runbook | Progressive disclosure skill for task decomposition & delegation. |
| [`skills/zellij-orchestrator/resources/roles/`](file:///Users/guy/dev/ai/ai-tools/zellij_mailbox/skills/zellij-orchestrator/resources/roles/) | Canonical role specifications | Base role contracts (`_BASE.md`, `dev.md`, `qa.md`, `devops.md`, `reviewer.md`, `docs.md`). |
| [`scripts/`](file:///Users/guy/dev/ai/ai-tools/zellij_mailbox/scripts/) | Hook scripts & installer | Shell scripts executed by hooks and setup utilities. |
| [`tests/`](file:///Users/guy/dev/ai/ai-tools/zellij_mailbox/tests/) | Smoke & verification test suite | Test scripts for verifying worker executions and hook integrity. |

---

## 🛠️ Shell Scripting Standards

All scripts in [`scripts/`](file:///Users/guy/dev/ai/ai-tools/zellij_mailbox/scripts/) and [`skills/zellij-orchestrator/scripts/`](file:///Users/guy/dev/ai/ai-tools/zellij_mailbox/skills/zellij-orchestrator/scripts/) must adhere to:

1. **Strict Error Handling:** Begin every bash script with `set -euo pipefail`.
2. **Deterministic Path Resolution:** Resolve script directories dynamically using:
   ```bash
   SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
   ```
3. **No Hardcoded Absolute Paths:** Never hardcode `/Users/...` or `/home/...`; use `$HOME` or relative directory resolution.
4. **JSON Processing:** Use `jq` safely with fallback defaults when parsing tool payloads or task receipts.
5. **Execution Permissions:** Ensure all `.sh` files maintain executable permissions (`chmod +x`).

---

## 🪝 Lifecycle Hooks & Guardrails Contract

The plugin leverages 4 core hooks defined in [`hooks.json`](file:///Users/guy/dev/ai/ai-tools/zellij_mailbox/hooks.json):

1. **`PreInvocation` ([`scripts/bus_status.sh`](file:///Users/guy/dev/ai/ai-tools/zellij_mailbox/scripts/bus_status.sh)):**
   - Injects non-intrusive live telemetry (pending tasks and receipt counts).
2. **`PreToolUse` ([`scripts/guardrails.sh`](file:///Users/guy/dev/ai/ai-tools/zellij_mailbox/scripts/guardrails.sh)):**
   - Blocks destructive shell commands (e.g. `rm -rf /`, `mkfs`).
3. **`PostToolUse` ([`scripts/validate_receipt.sh`](file:///Users/guy/dev/ai/ai-tools/zellij_mailbox/scripts/validate_receipt.sh)):**
   - Intercepts writes to `.agent-bus/results/*.json` and validates receipt schema adherence against `_BASE.md`.
4. **`Stop` ([`scripts/check_pending_receipt.sh`](file:///Users/guy/dev/ai/ai-tools/zellij_mailbox/scripts/check_pending_receipt.sh)):**
   - Prevents worker panes from terminating turn if an assigned task brief has not produced a matching completion receipt.

---

## 🎭 Role Specifications & Receipt Schema

- Any changes to role deliverables or communication protocol must be made in [`skills/zellij-orchestrator/resources/roles/`](file:///Users/guy/dev/ai/ai-tools/zellij_mailbox/skills/zellij-orchestrator/resources/roles/).
- All receipts produced by workers must follow the schema defined in [`skills/zellij-orchestrator/resources/roles/_BASE.md`](file:///Users/guy/dev/ai/ai-tools/zellij_mailbox/skills/zellij-orchestrator/resources/roles/_BASE.md).
