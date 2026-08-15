# Task 002: Greeting / Health Check (Worker 2 - Testing / QA / Review)

## Objective
Acknowledge initialization and confirm communication link with Lead Orchestrator.

## Context
Initial ping to establish inter-agent communication and verify readiness.

## Instructions
1. Reply with a greeting and confirm your role as Worker 2 (Testing / QA / Review).
2. Write a JSON completion receipt to `.agent-bus/results/task_002_w2_greeting.json`.

## Receipt Format
Write `.agent-bus/results/task_002_w2_greeting.json`:
```json
{
  "task_id": "task_002_w2_greeting",
  "status": "completed",
  "worker": "Worker 2 (Testing / QA / Review)",
  "message": "Hi! Ready for QA/testing tasks."
}
```
