# Projected Spec Kit Project Directory Structure

Below is the projected filesystem folder and file structure for a hypothetical project built using **Spec Kit**.

```text
my-project/
├── .github/                       # CI/CD workflows and action configurations
├── .specify/                      # Core Spec Kit directory
│   ├── memory/
│   │   └── constitution.md        # Foundational project principles and coding guidelines
│   ├── scripts/
│   │   └── bash/                  # Automation scripts (pre-flight checks, planning, tasking)
│   │       ├── check-prerequisites.sh
│   │       ├── common.sh
│   │       ├── create-new-feature.sh
│   │       ├── setup-plan.sh
│   │       └── setup-tasks.sh
│   └── templates/                 # Global blueprints for specs, plans, tasks
│       ├── CLAUDE-template.md
│       ├── plan-template.md
│       ├── spec-template.md
│       └── tasks-template.md
│
├── specs/                         # Feature specifications organized by feature/branch name
│   └── 001-create-taskify/        # Scoped feature development folder
│       ├── spec.md                # Functional requirements and user stories
│       ├── plan.md                # Technical implementation plan
│       ├── tasks.md               # Sequenced implementation checklist with dependencies
│       ├── data-model.md          # Domain and relational data mapping
│       ├── quickstart.md          # Setup instructions for this feature branch
│       ├── research.md            # Web research and version audit findings
│       └── contracts/             # API boundaries and websocket contracts
│           ├── api-spec.json
│           └── signalr-spec.md
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
