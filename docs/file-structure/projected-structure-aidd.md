# Projected AIDD Project Directory Structure

Below is the projected filesystem folder and file structure for a hypothetical project built using **AIDD** (Agent-Integrated Design and Development).

```text
my-project/
├── .github/                       # CI/CD workflows and action configurations
│
├── plan/                          # High-level architecture plans and stories
│   ├── plan.md                    # Core roadmap planning document
│   ├── story-map/                 # User journey layouts
│   │   └── auth-journey.yml       # YAML map detailing user interaction flow
│   └── stories/                   # Technical plans for specific agent-led tasks
│       ├── story-auth-agent.md
│       └── story-auth-human.md
│
├── ai/                            # Agent execution instructions and commands
│   ├── commands/                  # Custom prompt-based slash commands
│   │   ├── discover.md            # Command to check project status and list targets
│   │   ├── plan.md                # Command to draft implementation plan
│   │   ├── execute.md             # Command to run tests and write implementation
│   │   ├── review.md              # Command to perform deep code quality check
│   │   └── run-test.md            # Command to run automated test suites
│   │
│   ├── skills/                    # Sub-agent expertise definitions
│   │   ├── aidd-tdd/              # Red-Green-Refactor test skill rules
│   │   ├── aidd-observe/          # Error observing and debug skill rules
│   │   └── aidd-namespace/        # Namespace isolation and import check skill rules
│   │
│   └── scaffolds/                 # File and code snippet generator templates
│
├── aidd-custom/                   # Local overrides and custom prompt adjustments
│
├── src/                           # Application Source Code
│   ├── components/
│   ├── lib/
│   └── index.ts
│
├── tests/                         # Automated tests (verifiers)
│   └── integration/
│
├── vision.md                      # Foundational system requirements and business goals
├── AGENTS.md                      # Task assignment delegation matrix for sub-agents
├── activity-log.md                # Append-only ledger tracking all completed agent steps
├── CLAUDE.md                      # Agent fast-reference instructions (commands, conventions)
└── package.json                   # Project manifest (includes versioning and dev dependencies)
```
