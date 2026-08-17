# Phase 1: Test Harness & Behavioral Contracts (TDD Ground Truth)

You are executing **Phase 1 of 5 (TDD Pipeline)** for reconstructing the **`zellij-orchestrator`** plugin repository.

## 🎯 Phase Objective
In this phase, you establish the **Ground Truth Test Suite** before implementing business logic. You will author the end-to-end lifecycle hook test harness and worker smoke tests in `tests/`.

---

## 📂 Deliverables for Phase 1

Create the following 8 test scripts in `tests/`:

1. `tests/e2e_hook_test.py` (Master E2E Hook Verification Suite)
2. `tests/worker_hook_smoke.py`
3. `tests/dev_check.py`
4. `tests/test_qa_check.py`
5. `tests/autowake_check.py`
6. `tests/worker1_math.py`
7. `tests/worker2_anagram.py`
8. `tests/worker2_string.py`

---

## 📋 Behavioral Contracts to Test in `tests/e2e_hook_test.py`

Your E2E test suite must test the following 4 lifecycle hook behaviors using `subprocess.run`:

1. **`test_bus_status_hook`:**
   - Invokes `./scripts/bus_status.sh` with stdin JSON `{"workspacePaths": ["..."]}`.
   - Asserts response is valid JSON object `{}` or includes `"injectSteps"`.

2. **`test_guardrails_blocks_destructive`:**
   - Sends payload for `run_command` with `"CommandLine": "rm -rf /"`.
   - Asserts response returns `{"decision": "deny"}`.

3. **`test_guardrails_blocks_role_edit_for_workers`:**
   - Sends payload for `write_to_file` targeting `.agent-bus/roles/dev.md` with environment variable `ZELLIJ_PANE_ID=2`.
   - Asserts response returns `{"decision": "deny"}`.

4. **`test_check_pending_receipt_worker_isolation`:**
   - Simulates `.agent-bus/tasks/` containing Task A (for Worker 1 / `dev`) and Task B (for Worker 2 / `qa`).
   - When Worker 1 (`ZELLIJ_PANE_ID=2`) has a receipt in `.agent-bus/results/task_001_dev.json`, calling `./scripts/check_pending_receipt.sh` must return `{}` (pass), even though Task B is missing a receipt.
   - When Worker 2 (`ZELLIJ_PANE_ID=1`) lacks a receipt for Task B, calling `./scripts/check_pending_receipt.sh` must return `{"decision": "continue"}`.

---

## 🔍 Phase 1 Verification Gate
```bash
# Verify all test files compile cleanly
python3 -m py_compile tests/*.py && echo "✅ All Python test files syntax OK"
```
