# Universal Base Worker Protocol

This is the **Universal Base Contract** for all workers operating in the multi-agent orchestration architecture. Every specialized role inherits all rules, workflows, and output contracts defined here.

---

## 🔄 Universal Operational Workflow

When triggered by the Orchestrator:

### 1. Ingest Task Brief & Role Definition
- Determine your pane ID via `$ZELLIJ_PANE_ID`.
- When first booted or when adopting a new role, greet the user with:
  `"Hello! I am Worker <N> (<role>). My job is to <role mission>."`
- Read your assigned role file at `.agent-bus/roles/<role>.md`.
- Read the assigned task brief at `.agent-bus/tasks/<task_id>.md`.
- Verify the task objective, scope, allowed/forbidden files, and acceptance criteria.
- Adhere strictly to the boundaries and instructions specified.
- Verify that your pane title reflects your assigned role (e.g., `Worker 1 (dev)`, `Worker 2 (qa)`).

### 2. Execution & Autonomy
- Execute the task autonomously according to your role's standards.
- Run all CLI commands with **non-interactive flags** (e.g. `--ci`, `--no-watch`, `--batch`, `-y`).
- Never make speculative or breaking changes to files outside the assigned scope.

### 3. Generate Completion Receipt
Upon finishing your work, you **MUST** write a JSON receipt to `.agent-bus/results/<task_id>.json`.

Every receipt must adhere to this standardized base envelope:

```json
{
  "taskId": "<task_id>",
  "role": "<role_name>",
  "workerPaneId": "$ZELLIJ_PANE_ID", // Value from $ZELLIJ_PANE_ID env variable
  "timestamp": "<ISO-8601 Timestamp>",
  "status": "COMPLETED", // Allowed: "COMPLETED" | "PASS" | "FAIL" | "BLOCKED"
  "summary": "High-level summary of work performed and outcome",
  "filesCreated": [],
  "filesModified": [],
  "errorsOrWarnings": [],
  "payload": {
    // Role-specific payload schema defined in .agent-bus/roles/<role>.md
  }
}
```

---

## 🛡️ Universal Guardrails
1. **Scope Containment:** Never modify files marked as forbidden or outside your assigned task scope.
2. **Never Ignore Failures:** If a task cannot be completed, tests fail, or a blocker is encountered, set `"status": "FAIL"` or `"status": "BLOCKED"` and document the exact reason in `"summary"` and `"errorsOrWarnings"`.
3. **Deterministic Output:** Always write the completion receipt to `.agent-bus/results/<task_id>.json` as your final action so the Orchestrator can immediately detect completion.
