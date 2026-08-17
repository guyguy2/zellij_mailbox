# Phase 4: Skill Runbook & Modular Role Catalog

You are executing **Phase 4 of 5 (TDD Pipeline)** for reconstructing the **`zellij-orchestrator`** plugin repository.

## 🎯 Phase Objective
In this phase, you build the progressive disclosure skill runbook (`skills/zellij-orchestrator/SKILL.md`) and the 6-file modular role catalog in `skills/zellij-orchestrator/resources/roles/`.

---

## 📂 Deliverables for Phase 4

Create the following 7 files:

1. `skills/zellij-orchestrator/SKILL.md` (Orchestrator Runbook)
2. `skills/zellij-orchestrator/resources/roles/_BASE.md` (Universal Base Worker Contract)
3. `skills/zellij-orchestrator/resources/roles/dev.md` (Developer Specialist)
4. `skills/zellij-orchestrator/resources/roles/qa.md` (QA & Verification Specialist)
5. `skills/zellij-orchestrator/resources/roles/devops.md` (DevOps & GKE Specialist)
6. `skills/zellij-orchestrator/resources/roles/reviewer.md` (Code Review Specialist)
7. `skills/zellij-orchestrator/resources/roles/docs.md` (Documentation Specialist)

---

## 📋 Specifications & Role Contracts

### 1. `skills/zellij-orchestrator/SKILL.md`
- **Frontmatter:** `name: zellij-orchestrator`, description explaining multi-agent coordination across Zellij panes using `.agent-bus/` and JSON receipts.
- **5-Step Workflow:**
  1. *Initialize Bus:* Ensure `.agent-bus/{tasks,results,roles}` exist.
  2. *Formulate Brief:* Create `.agent-bus/tasks/<task_id>.md` specifying role, objective, scope, acceptance criteria.
  3. *Trigger Target Worker:* Inject `zellij action write-chars --pane-id <ID>` and `send-keys --pane-id <ID> "Enter"`.
  4. *Monitor Receipts & Auto-wake:* Yield turn, await hook auto-wake, parse `.agent-bus/results/<task_id>.json`.
  5. *Telemetry & Debugging:* Use `zellij action dump-screen -p <ID>` if worker is unresponsive.

### 2. Universal Base Role Contract (`_BASE.md`)
- Mindset: Senior engineering rigor, deliberate step-by-step reasoning, clarify rather than guess.
- Workflow: Ingest brief, determine pane ID, execute non-interactively within scope boundaries, generate JSON receipt upon completion.
- **Base Receipt Envelope (`.agent-bus/results/<task_id>.json`):**
  ```json
  {
    "taskId": "<task_id>",
    "role": "<role_name>",
    "workerPaneId": "$ZELLIJ_PANE_ID",
    "timestamp": "<ISO-8601 Timestamp>",
    "status": "COMPLETED",
    "summary": "<summary of work>",
    "filesCreated": [],
    "filesModified": [],
    "errorsOrWarnings": [],
    "payload": {}
  }
  ```

### 3. Specialized Role Specifications (Inherit `_BASE.md`)
- **`dev.md`:** Focus on clean modular architecture, typing, self-verification. Payload: `notesForQA`, `dependenciesAdded`, `breakingChanges`, `verificationCommandRun`.
- **`qa.md`:** Adversarial test design, edge-case hunting, automated non-interactive testing. Payload: `testCommand`, `testResults` (`total`, `passed`, `failed`), `issuesFound`, `verifiedCriteria`.
- **`devops.md`:** GKE workloads, Workload Identity, Dockerfile/Helm/Kustomize, CI/CD, least-privilege security. Payload: `manifestsCreatedOrModified`, `gkeFeaturesConfigured`, `validationCommandsRun`, `securityChecklist`, `rollbackStrategy`.
- **`reviewer.md`:** Read-only diff inspection, OWASP security analysis, complexity audit. Payload: `reviewOutcome` (`APPROVED` / `CHANGES_REQUESTED`), `overallScore`, `findings`, `securityChecklist`, `architectureNotes`.
- **`docs.md`:** Technical writing, API contracts, sync docs with code truth. Payload: `docsCreatedOrModified`, `apiEndpointsDocumented`, `notes`.

---

## 🔍 Phase 4 Verification Gate
```bash
test -f skills/zellij-orchestrator/SKILL.md && echo "✅ SKILL.md exists"
for r in _BASE dev qa devops reviewer docs; do
  test -f "skills/zellij-orchestrator/resources/roles/${r}.md" && echo "✅ Role exists: $r.md"
done
```
