# Task 001: Greeting / Health Check (Worker 1 - Backend / Logic)

## Objective
Acknowledge initialization and confirm communication link with Lead Orchestrator.

## Context
Initial ping to establish inter-agent communication and verify readiness.

## Instructions
1. Reply with a greeting and confirm your role as Worker 1 (Backend / Logic).
2. Write a JSON completion receipt to `.agent-bus/results/task_001_w1_greeting.json`.

## Receipt Format
Write `.agent-bus/results/task_001_w1_greeting.json`:
```json
{
  "task_id": "task_001_w1_greeting",
  "status": "completed",
  "worker": "Worker 1 (Backend / Logic)",
  "message": "Hi! Ready for backend tasks."
}
```
