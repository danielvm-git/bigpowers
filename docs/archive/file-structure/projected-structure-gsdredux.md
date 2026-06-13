# Projected get-shit-done-redux Project Directory Structure

Below is the projected filesystem folder and file structure for a hypothetical project built using **get-shit-done-redux**.

```text
my-project/
├── .github/                       # CI/CD workflows and action configurations
├── .planning/                     # Core planning context and state management
│   ├── PROJECT.md                 # Strategic vision, developer principles, constraints
│   ├── ROADMAP.md                 # Sequenced roadmap with status tags ([done], [in-progress])
│   ├── STATE.md                   # Live session state: decisions, active phase, active git branch
│   ├── REQUIREMENTS.md            # Feature mapping (Must Haves, Nice-to-Haves, Out of Scope)
│   ├── MILESTONES.md              # Archived completed milestones
│   ├── BACKLOG.md                 # Unscheduled tasks and epic lists
│   ├── LEARNINGS.md               # Continuous feedback logs
│   ├── config.json                # CLI settings and agent-routing rules
│   │
│   ├── research/                  # High-density tech stack and dependency investigations
│   │   ├── SUMMARY.md
│   │   ├── STACK.md
│   │   ├── FEATURES.md
│   │   ├── ARCHITECTURE.md
│   │   └── PITFALLS.md
│   │
│   ├── codebase/                  # Mapped brownfield structure
│   │   ├── STACK.md               # Codebase stack and environment metrics
│   │   ├── ARCHITECTURE.md        # Architectural patterns and structural mappings
│   │   ├── CONVENTIONS.md         # Formatting, typing, and syntax preferences
│   │   ├── STRUCTURE.md           # Directories and codebase entry points
│   │   ├── TESTING.md             # Testing framework configuration
│   │   └── INTEGRATIONS.md        # External APIs and services maps
│   │
│   └── phases/                    # Milestone implementation folders
│       └── 01-auth-flow/          # Isolated phase workspace
│           ├── 01-CONTEXT.md      # Discuss phase output (decisions, preferences)
│           ├── 01-RESEARCH.md     # Phase-level research (includes slop audit)
│           ├── 01-01-PLAN.md      # Isolated execution task plan
│           ├── 01-01-SUMMARY.md   # Post-execution outcome summary
│           ├── 01-VERIFICATION.md # Verification logs and acceptance validation
│           ├── 01-VALIDATION.md   # Coverage mapping
│           └── 01-UAT.md          # User Acceptance Test scripts
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
