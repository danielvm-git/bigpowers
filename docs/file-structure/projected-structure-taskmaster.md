# Projected Taskmaster Project Directory Structure

Below is the projected filesystem folder and file structure for a hypothetical project built using **Taskmaster**.

```text
my-project/
├── .github/                       # CI/CD workflows and action configurations
├── .taskmaster/                   # Core Taskmaster loop environment and state folder
│   ├── config.json                # Runtime orchestrator parameters and config overrides
│   ├── state.json                 # Current status of execution (active loops, task lists)
│   ├── loop-progress.txt          # Streaming stdout/trace log for autonomous task loops
│   │
│   ├── docs/                      # Product briefs, PRDs, and references
│   │   ├── prd.txt                # Initial Product Requirements Document
│   │   └── autonomous-tdd.md      # TDD workflow guides and code style conventions
│   │
│   ├── reports/                   # Outcome reports from test and implementation phases
│   │   └── run-report-001.json
│   │
│   ├── tasks/                     # Task definitions and status index
│   │   ├── tasks.json             # Structured checklist of all plan subtasks and state
│   │   └── task_001_init-db.txt   # Isolated instruction spec for task 1
│   │
│   └── templates/                 # Global task templates and instruction blueprints
│
├── src/                           # Application Source Code
│   ├── components/
│   ├── lib/
│   └── index.ts
│
├── tests/                         # Automated tests (verifiers)
│   └── integration/
│
├── CLAUDE.md                      # Agent fast-reference instructions (commands, conventions)
└── package.json                   # Project manifest (includes versioning and dev dependencies)
```
