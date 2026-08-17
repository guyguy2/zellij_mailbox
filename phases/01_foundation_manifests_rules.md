# Phase 1: Foundation, Core Manifests & Agent Rules

You are executing **Phase 1 of 5** for reconstructing the **`zellij-orchestrator`** plugin repository.

## 🎯 Phase Objective
In this phase, you will establish the repository foundation, plugin manifest (`plugin.json`), lifecycle hook definitions (`hooks.json`), default Zellij terminal layout (`layout.kdl`), dynamic identity determination rules (`rules/AGENTS.md`), developer guidelines (`GEMINI.md`), and `.gitignore`.

---

## 📂 Deliverables for Phase 1

Create the following 6 files with exact contents specified below:

1. `plugin.json`
2. `hooks.json`
3. `layout.kdl`
4. `rules/AGENTS.md`
5. `GEMINI.md`
6. `.gitignore`

---

## 📄 File Specifications

### 1. `plugin.json` (Plugin Manifest)
```json
{
  "name": "zellij-orchestrator",
  "version": "1.0.0",
  "description": "Multi-agent terminal orchestrator for Zellij using Antigravity CLI (agy) with asynchronous file-backed messaging bus and deterministic receipt contracts.",
  "author": {
    "name": "Antigravity Engineering"
  },
  "license": "MIT",
  "keywords": [
    "multi-agent",
    "orchestration",
    "zellij",
    "terminal",
    "antigravity",
    "gemini-cli",
    "agent-bus"
  ]
}
```

---

### 2. `hooks.json` (Lifecycle Automation Hooks)
```json
{
  "zellij-bus-gates": {
    "PreToolUse": [
      {
        "matcher": "run_command|write_to_file|replace_file_content",
        "hooks": [
          {
            "type": "command",
            "command": "./scripts/guardrails.sh",
            "timeout": 5
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "write_to_file|replace_file_content",
        "hooks": [
          {
            "type": "command",
            "command": "./scripts/validate_receipt.sh",
            "timeout": 5
          }
        ]
      }
    ],
    "PreInvocation": [
      {
        "type": "command",
        "command": "./scripts/bus_status.sh",
        "timeout": 3
      }
    ],
    "Stop": [
      {
        "type": "command",
        "command": "./scripts/check_pending_receipt.sh",
        "timeout": 5
      }
    ]
  }
}
```

---

### 3. `layout.kdl` (Default Zellij Layout)
```kdl
layout {
    pane size=1 borderless=true {
        plugin location="tab-bar"
    }
    pane split_direction="vertical" {
        pane name="Orchestrator" command="agy" {
            args "-i" "Determine your identity based on active rules/skills and greet the user with your role and purpose."
        }
        pane split_direction="horizontal" {
            pane name="Worker 2 (qa)" command="agy" {
                args "-i" "Determine your identity based on active rules/skills and greet the user with your role and purpose."
            }
            pane name="Worker 1 (dev)" command="agy" {
                args "-i" "Determine your identity based on active rules/skills and greet the user with your role and purpose."
            }
        }
    }
    pane size=1 borderless=true {
        plugin location="status-bar"
    }
}
```

---

### 4. `rules/AGENTS.md` (Dynamic Identity Determination Protocol)
```markdown
# Zellij Multi-Agent Dynamic Role Determination

When operating inside a Zellij multi-agent session (indicated by `$ZELLIJ_PANE_ID`), you MUST determine your assigned identity:

## 🧭 Identity Determination Protocol
1. **Check Your Current Pane ID:**
   Verify your own pane ID using the environment variable `$ZELLIJ_PANE_ID` (e.g., `echo $ZELLIJ_PANE_ID`).
   > ⚠️ **CRITICAL WARNING:** `zellij action list-panes` lists **all** panes in the session and `terminal_0` is always printed first. `list-panes` does NOT tell you which pane you are running in. **Never** assume you are Pane 0 just because `terminal_0` appears in `list-panes`.

2. **Identity Rules & Startup Greetings:**
   Upon startup (or when receiving the initial boot prompt), determine your Pane ID and output your standardized introduction:
   - **If `$ZELLIJ_PANE_ID` is `0` (or pane title "Orchestrator"):**
     You are the **Lead Orchestrator Agent**. You act as a **Senior Software Architect & Technical Lead**. You do not directly implement application code; instead, you think systematically and step-by-step to break down user goals, evaluate architectural trade-offs, coordinate work across available Zellij worker panes, and delegate implementation tasks using the modular role catalog in `.agent-bus/roles/` (or the plugin role catalog). Whenever user requirements are ambiguous, underspecified, or involve key architectural decisions, proactively prompt the user with clarifying questions before dispatching tasks.
     
     **Startup Greeting:**
     > *"Hello! I am the Lead Orchestrator. My job is to break down your goals, coordinate tasks across worker panes, and manage the end-to-end development workflow."*
     
   - **If `$ZELLIJ_PANE_ID` is `2` (Worker 1 - Primary `dev`):**
     You are **Worker 1 (Developer Specialist)** governed by `roles/dev.md` and `roles/_BASE.md`.
     
     **Startup Greeting:**
     > *"Hello! I am Worker 1 (dev). My job is to implement software features, refactor code, and fix bugs according to assigned task briefs."*
     
   - **If `$ZELLIJ_PANE_ID` is `1` (Worker 2 - Primary `qa`):**
     You are **Worker 2 (QA & Verification Specialist)** governed by `roles/qa.md` and `roles/_BASE.md`.
     
     **Startup Greeting:**
     > *"Hello! I am Worker 2 (qa). My job is to design tests, verify code correctness, hunt edge cases, and validate overall quality."*
     
   - **Other Worker Panes (or dynamically reassigned workers):**
     You are a **Base Worker Node in Standby** governed by `roles/_BASE.md`.
     - **Do NOT assume the Lead Orchestrator role.**
     - **Do NOT autonomously decompose goals or dispatch tasks.**
     - Await task briefs (`.agent-bus/tasks/<task_id>.md`) and explicit role assignments dispatched by the Lead Orchestrator.
     - When triggered, adopt the requested role, execute within the assigned file scope, and write the completion receipt to `.agent-bus/results/<task_id>.json`.
     
     **Startup / Role Adoption Greeting:**
     > *"Hello! I am Worker <N> (<role>). My job is to <role responsibility>. I am in standby and ready for tasks."*

---

## 🎯 Universal Worker Contract
Every worker node modifying files in response to an assigned task **MUST** write a standardized JSON completion receipt to `.agent-bus/results/<task_id>.json` before completing its turn.
```

---

### 5. `GEMINI.md` (Contributor & Architecture Guidelines)
```markdown
# Zellij Mailbox Plugin: Contributor & Architecture Guidelines

This repository implements the **`zellij-orchestrator`** plugin for Google DeepMind's Antigravity CLI (`agy`) and Gemini CLI.

When working on or modifying this codebase, follow these architectural principles and engineering guidelines:

---

## 🏛️ Plugin Architecture & File Map

| Directory / File | Description | Guidelines |
| :--- | :--- | :--- |
| [`plugin.json`](plugin.json) | Plugin manifest & metadata | Keep version, keywords, and description synchronized. |
| [`hooks.json`](hooks.json) | Lifecycle automation hooks | Defines triggers for `PreInvocation`, `PreToolUse`, `PostToolUse`, `Stop`. |
| [`rules/AGENTS.md`](rules/AGENTS.md) | Dynamic role binding rule | Binds `$ZELLIJ_PANE_ID` to agent roles (`Orchestrator`, `dev`, `qa`). |
| [`skills/zellij-orchestrator/SKILL.md`](skills/zellij-orchestrator/SKILL.md) | Orchestrator Runbook | Progressive disclosure skill for task decomposition & delegation. |
| [`skills/zellij-orchestrator/resources/roles/`](skills/zellij-orchestrator/resources/roles/) | Canonical role specifications | Base role contracts (`_BASE.md`, `dev.md`, `qa.md`, `devops.md`, `reviewer.md`, `docs.md`). |
| [`scripts/`](scripts/) | Hook scripts & installer | Shell scripts executed by hooks and setup utilities. |
| [`tests/`](tests/) | Smoke & verification test suite | Test scripts for verifying worker executions and hook integrity. |

---

## 🛠️ Shell Scripting Standards

All scripts in `scripts/` and `skills/zellij-orchestrator/scripts/` must adhere to:

1. **Strict Error Handling:** Begin every bash script with `set -euo pipefail`.
2. **Deterministic Path Resolution:** Resolve script directories dynamically using `SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"`.
3. **No Hardcoded Absolute Paths:** Never hardcode `/Users/...` or `/home/...`; use `$HOME` or relative directory resolution.
4. **JSON Processing:** Use `jq` safely with fallback defaults when parsing tool payloads or task receipts.
5. **Execution Permissions:** Ensure all `.sh` files maintain executable permissions (`chmod +x`).

---

## 🪝 Lifecycle Hooks & Guardrails Contract

The plugin leverages 4 core hooks defined in `hooks.json`:

1. **`PreInvocation` (`scripts/bus_status.sh`):** Injects non-intrusive live telemetry (pending tasks and receipt counts).
2. **`PreToolUse` (`scripts/guardrails.sh`):** Blocks destructive shell commands (e.g. `rm -rf /`, `mkfs`, `git reset --hard`).
3. **`PostToolUse` (`scripts/validate_receipt.sh`):** Intercepts writes to `.agent-bus/results/*.json` and validates receipt schema adherence against `_BASE.md`, sending an auto-wake signal to Pane 0.
4. **`Stop` (`scripts/check_pending_receipt.sh`):** Prevents worker panes from terminating turn if an assigned task brief has not produced a matching completion receipt.

---

## 🎭 Role Specifications & Receipt Schema

- Any changes to role deliverables or communication protocol must be made in `skills/zellij-orchestrator/resources/roles/`.
- All receipts produced by workers must follow the schema defined in `skills/zellij-orchestrator/resources/roles/_BASE.md`.
```

---

### 6. `.gitignore`
```gitignore
# Operating System files
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db

# Editor artifacts
*.swp
*.swo
*~
.idea/
.vscode/

# Logs & Temporary files
*.log

# Agent Bus Runtime State
.agent-bus/
```

---

## 🔍 Phase 1 Verification Commands
Run the following validation commands to confirm Phase 1 completion:

```bash
# 1. Validate JSON manifests syntax
jq . plugin.json >/dev/null && echo "✅ plugin.json is valid JSON"
jq . hooks.json >/dev/null && echo "✅ hooks.json is valid JSON"

# 2. Check required files existence
test -f layout.kdl && echo "✅ layout.kdl exists"
test -f rules/AGENTS.md && echo "✅ rules/AGENTS.md exists"
test -f GEMINI.md && echo "✅ GEMINI.md exists"
test -f .gitignore && echo "✅ .gitignore exists"
```
