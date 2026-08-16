---
name: zellij-orchestrator
description: >-
  Coordinates multi-agent software engineering workflows across Zellij terminal panes using an
  asynchronous, file-backed task bus (.agent-bus/) and deterministic JSON completion receipts.
  Use when delegating implementation, test verification, or code review across multiple terminal workers.
---

# 🤖 Zellij Multi-Agent Orchestrator Runbook

This skill provides step-by-step procedures for the **Lead Orchestrator (Pane 0)** to decompose high-level requirements, dispatch task briefs to worker panes, monitor completion receipts, and coordinate multi-stage pipelines (`dev` ➔ `qa` ➔ `reviewer`).

---

## 🛠️ Step 1: Initialize the Agent Bus

Ensure the communication bus directories exist in the target project workspace:

```bash
mkdir -p .agent-bus/tasks .agent-bus/results .agent-bus/roles
```

If local role overrides are not present, populate `.agent-bus/roles/` with the base catalog from `./resources/roles/`.

---

## 📋 Step 2: Formulate the Task Brief

For each subtask, write a markdown brief at `.agent-bus/tasks/<task_id>.md`:

### Task Brief Template:
```markdown
# Task Brief: <task_id>

## Assigned Role
- **Role:** <dev | qa | devops | reviewer | docs>
- **Role Specification:** `.agent-bus/roles/<role>.md`

## Objective & Requirements
<Clear explanation of what needs to be implemented or verified>

## Allowed Scope & File Boundaries
- **Allowed Files:** `src/feature/*`, `tests/test_feature.py`
- **Forbidden Files:** `config/*`, `.agent-bus/roles/*`

## Acceptance Criteria
- [ ] Code compiles and passes all unit tests.
- [ ] No regression errors in existing test suite.
- [ ] Completion receipt written to `.agent-bus/results/<task_id>.json`.
```

---

## ⚡ Step 3: Trigger the Target Worker Pane

Dispatch the task to an available worker pane using `zellij action write-chars` and `send-keys`:

```bash
# Example dispatching to Worker 1 (Pane 2):
zellij action rename-pane --pane-id 2 "Worker 1 (dev)" && \
zellij action write-chars --pane-id 2 "Adopt role defined in .agent-bus/roles/dev.md. Execute instructions in .agent-bus/tasks/<task_id>.md and write summary to .agent-bus/results/<task_id>.json" && \
zellij action send-keys --pane-id 2 "Enter"
```

---

## 🧾 Step 4: Monitor Completion & Parse Receipts

1. Poll `.agent-bus/results/<task_id>.json` to check worker status.
2. The completion receipt format:
```json
{
  "taskId": "<task_id>",
  "role": "dev",
  "workerPaneId": "2",
  "timestamp": "2026-08-16T12:00:00Z",
  "status": "COMPLETED",
  "summary": "Implemented feature X with unit tests.",
  "filesCreated": ["src/feature/x.py"],
  "filesModified": [],
  "errorsOrWarnings": [],
  "payload": {
    "notesForQA": "Verify edge case Y",
    "verificationCommandRun": "pytest tests/test_x.py"
  }
}
```
3. **Handling Failures:** If `status` is `"FAIL"` or `"BLOCKED"`, formulate a remediation brief and dispatch back to `dev`.
4. **Advancing the Pipeline:** Upon success, formulate the QA brief and dispatch to Worker 2 (Pane 1).

---

## 🔍 Step 5: Worker Telemetry & Debugging

If a worker pane appears unresponsive or is taking longer than expected:
```bash
# Capture live terminal screen from worker pane:
zellij action dump-screen -p <PANE_ID>
```
