# Projected GSD 2 (gsd-pi) Project Directory Structure

Below is the projected filesystem folder and file structure for a hypothetical project built using **GSD 2 (gsd-pi)**.

```text
my-project/
├── .github/                       # CI/CD workflows and action configurations
├── .agent/                        # Active agent integrations (e.g. Antigravity)
│   └── skills/                    # GSD 2 agent skills and namespace meta-routers
│
├── .gsd/                          # Main planning context and state database (markdown projections)
│   ├── PROJECT.md                 # Strategic vision, developer preferences, decisions register
│   ├── REQUIREMENTS.md            # Feature mapping (Must Haves, Nice-to-Haves, Out of Scope)
│   ├── ROADMAP.md                 # Sequenced roadmap with status tags and [sketch] badges
│   ├── STATE.md                   # Live session state: decisions, active slice, active git branch
│   ├── config.json                # GSD 2 execution configuration (UOK, context window size)
│   ├── MILESTONES.md              # Archived completed milestones
│   │
│   ├── research/                  # Project research outputs
│   │   ├── SUMMARY.md
│   │   ├── STACK.md
│   │   ├── FEATURES.md
│   │   ├── ARCHITECTURE.md
│   │   └── PITFALLS.md
│   │
│   ├── codebase/                  # Mapped brownfield structure
│   │   ├── STACK.md
│   │   ├── ARCHITECTURE.md
│   │   ├── CONVENTIONS.md
│   │   ├── STRUCTURE.md
│   │   ├── TESTING.md
│   │   └── INTEGRATIONS.md
│   │
│   ├── slices/                    # Milestone implementation folders
│   │   ├── M001-ROADMAP.md        # Milestone roadmap excerpt and target DOD
│   │   ├── M001-CONTEXT.md        # Elicitation session output (decisions, preferences)
│   │   ├── M001-RESEARCH.md       # Milestone research and supply chain/slop audit
│   │   ├── M001-01-PLAN.md        # Execution plan for slice 1
│   │   ├── M001-01-SUMMARY.md     # Slice 1 outcome summary
│   │   ├── M001-VALIDATION.md     # Nyquist test coverage mapping
│   │   └── M001-UAT.md            # User Acceptance Test scripts
│   │
│   ├── exec/                      # Context Mode execution logs (stdout/stderr caches)
│   ├── debug/                     # Active and resolved debug sessions
│   └── migration/                 # Migration audit logs from legacy .planning structure
│
├── gsd.db                         # AUTHORITATIVE SQLite database (locks, command queue, sessions)
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
