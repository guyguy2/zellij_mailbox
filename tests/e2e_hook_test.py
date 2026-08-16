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
