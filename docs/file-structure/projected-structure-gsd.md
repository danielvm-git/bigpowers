# Projected GSD v1 Project Directory Structure

Below is the projected filesystem folder and file structure for a hypothetical project built using **Get Shit Done (GSD v1)**.

```text
my-project/
├── .github/                       # CI/CD workflows and action configurations
├── .claude/                       # Claude Code configurations (global/local)
│   └── skills/
│       └── gsd-*/                 # Custom GSD slash command scripts and meta-skills
│
├── .planning/                     # Core planning context and state management
│   ├── PROJECT.md                 # Strategic vision, developer principles, constraints
│   ├── REQUIREMENTS.md            # Feature mapping (Must Haves, Nice-to-Haves, Out of Scope)
│   ├── ROADMAP.md                 # Sequenced roadmap with status tags ([done], [in-progress])
│   ├── STATE.md                   # Live session state: decisions, active phase, active git branch
│   ├── config.json                # GSD execution and model selector settings
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
│           ├── 01-UI-SPEC.md      # UI design specs (optional)
│           ├── 01-UI-REVIEW.md    # UI Visual Audit results (optional)
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
