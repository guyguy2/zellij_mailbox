# Phase 4: Verification & Smoke Test Suite

You are executing **Phase 4 of 5** for reconstructing the **`zellij-orchestrator`** plugin repository.

## 🎯 Phase Objective
In this phase, you will implement the 8 Python test and verification scripts (`tests/worker_hook_smoke.py`, `tests/dev_check.py`, `tests/test_qa_check.py`, `tests/autowake_check.py`, `tests/e2e_hook_test.py`, `tests/worker1_math.py`, `tests/worker2_anagram.py`, `tests/worker2_string.py`) that validate lifecycle hook isolation, guardrail enforcement, auto-wake mechanics, and worker unit behaviors.

---

## 📂 Deliverables for Phase 4

Create the following 8 Python test files with exact contents specified below:

1. `tests/worker_hook_smoke.py`
2. `tests/dev_check.py`
3. `tests/test_qa_check.py`
4. `tests/autowake_check.py`
5. `tests/e2e_hook_test.py`
6. `tests/worker1_math.py`
7. `tests/worker2_anagram.py`
8. `tests/worker2_string.py`

---

## 📄 File Specifications

### 1. `tests/worker_hook_smoke.py`
```python
"""Lightweight test utility script to verify worker hook execution."""

def test_basic_arithmetic():
    assert 2 + 2 == 4
    assert 10 - 3 == 7
    assert 3 * 5 == 15
    assert 20 / 4 == 5

if __name__ == "__main__":
    test_basic_arithmetic()
    print("All smoke tests passed successfully.")
```

---

### 2. `tests/dev_check.py`
```python
def get_worker_status():
    return "DEV_READY"

if __name__ == "__main__":
    assert get_worker_status() == "DEV_READY"
    print("dev_check: PASSED")
```

---

### 3. `tests/test_qa_check.py`
```python
def test_qa_assertions():
    assert 10 > 5
    assert "QA" in "QA_VERIFIED"

if __name__ == "__main__":
    test_qa_assertions()
    print("test_qa_check: PASSED")
```

---

### 4. `tests/autowake_check.py`
```python
def square(n):
    return n * n

if __name__ == "__main__":
    assert square(4) == 16
    print("autowake_check: PASSED")
```

---

### 5. `tests/e2e_hook_test.py`
```python
import json
import os
import subprocess
import tempfile

def test_bus_status_hook():
    """Verify bus_status hook returns JSON and handles empty/active tasks."""
    res = subprocess.run(
        ["./scripts/bus_status.sh"],
        input=json.dumps({"workspacePaths": [os.getcwd()]}),
        capture_output=True,
        text=True,
        check=True
    )
    data = json.loads(res.stdout.strip())
    assert isinstance(data, dict)

def test_guardrails_blocks_destructive():
    """Verify guardrails blocks dangerous commands."""
    payload = {
        "workspacePaths": [os.getcwd()],
        "toolCall": {
            "name": "run_command",
            "args": {
                "CommandLine": "rm -rf /"
            }
        }
    }
    res = subprocess.run(
        ["./scripts/guardrails.sh"],
        input=json.dumps(payload),
        capture_output=True,
        text=True,
        check=True
    )
    data = json.loads(res.stdout.strip())
    assert data.get("decision") == "deny"

def test_guardrails_blocks_role_edit_for_workers():
    """Verify guardrails blocks worker panes from modifying roles."""
    payload = {
        "workspacePaths": [os.getcwd()],
        "toolCall": {
            "name": "write_to_file",
            "args": {
                "TargetFile": ".agent-bus/roles/dev.md"
            }
        }
    }
    env = os.environ.copy()
    env["ZELLIJ_PANE_ID"] = "2"
    res = subprocess.run(
        ["./scripts/guardrails.sh"],
        input=json.dumps(payload),
        capture_output=True,
        text=True,
        env=env,
        check=True
    )
    data = json.loads(res.stdout.strip())
    assert data.get("decision") == "deny"

def test_check_pending_receipt_worker_isolation():
    """Verify check_pending_receipt only enforces tasks targeting the specific worker pane."""
    with tempfile.TemporaryDirectory() as tmpdir:
        tasks_dir = os.path.join(tmpdir, ".agent-bus", "tasks")
        results_dir = os.path.join(tmpdir, ".agent-bus", "results")
        os.makedirs(tasks_dir)
        os.makedirs(results_dir)

        # Create Task A for Worker 1 (dev) and Task B for Worker 2 (qa)
        task_a = os.path.join(tasks_dir, "task_001_dev.md")
        with open(task_a, "w") as f:
            f.write("# Task\n- **Assigned Worker:** Worker 1 (`dev`)\n")

        task_b = os.path.join(tasks_dir, "task_002_qa.md")
        with open(task_b, "w") as f:
            f.write("# Task\n- **Assigned Worker:** Worker 2 (`qa`)\n")

        # Worker 1 completes Task A
        receipt_a = os.path.join(results_dir, "task_001_dev.json")
        with open(receipt_a, "w") as f:
            f.write(json.dumps({
                "taskId": "task_001_dev",
                "status": "COMPLETED",
                "role": "dev",
                "summary": "Done"
            }))

        env_w1 = os.environ.copy()
        env_w1["ZELLIJ_PANE_ID"] = "2"

        # Worker 1 checks Stop hook - should pass even though Task B has no receipt!
        res_w1 = subprocess.run(
            [os.path.abspath("./scripts/check_pending_receipt.sh")],
            input=json.dumps({"workspacePaths": [tmpdir]}),
            capture_output=True,
            text=True,
            env=env_w1,
            check=True
        )
        assert json.loads(res_w1.stdout.strip()) == {}

        # Worker 2 checks Stop hook - should be intercepted because Task B is missing receipt
        env_w2 = os.environ.copy()
        env_w2["ZELLIJ_PANE_ID"] = "1"
        res_w2 = subprocess.run(
            [os.path.abspath("./scripts/check_pending_receipt.sh")],
            input=json.dumps({"workspacePaths": [tmpdir]}),
            capture_output=True,
            text=True,
            env=env_w2,
            check=True
        )
        data_w2 = json.loads(res_w2.stdout.strip())
        assert data_w2.get("decision") == "continue"

if __name__ == '__main__':
    test_bus_status_hook()
    test_guardrails_blocks_destructive()
    test_guardrails_blocks_role_edit_for_workers()
    test_check_pending_receipt_worker_isolation()
    print("All Hook E2E tests verified successfully.")
```

---

### 6. `tests/worker1_math.py`
```python
def factorial(n):
    return 1 if n <= 1 else n * factorial(n - 1)

if __name__ == '__main__':
    assert factorial(5) == 120
    print("Factorial test passed.")
```

---

### 7. `tests/worker2_anagram.py`
```python
def is_anagram(s1, s2):
    return sorted(s1.replace(" ", "").lower()) == sorted(s2.replace(" ", "").lower())

if __name__ == '__main__':
    assert is_anagram("listen", "silent") is True
    assert is_anagram("hello", "world") is False
    print("Anagram test passed.")
```

---

### 8. `tests/worker2_string.py`
```python
def is_palindrome(s):
    return s == s[::-1]

if __name__ == '__main__':
    assert is_palindrome("racecar") is True
    assert is_palindrome("hello") is False
    print("String palindrome test passed.")
```

---

## 🔍 Phase 4 Verification Commands
Run the following validation commands to confirm Phase 4 completion:

```bash
# Run all verification test scripts
python3 tests/worker_hook_smoke.py
python3 tests/dev_check.py
python3 tests/test_qa_check.py
python3 tests/autowake_check.py
python3 tests/e2e_hook_test.py
python3 tests/worker1_math.py
python3 tests/worker2_anagram.py
python3 tests/worker2_string.py
```
