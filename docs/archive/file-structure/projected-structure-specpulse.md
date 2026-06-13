# Projected SpecPulse Project Directory Structure

Below is the projected filesystem folder and file structure for a hypothetical project built using **SpecPulse**.

```text
my-project/
├── .github/                       # CI/CD workflows and action configurations
├── .specpulse/                    # Core SpecPulse metadata and specifications directory
│   ├── config.yml                 # Main parameters for SpecPulse execution
│   ├── project_context.yaml       # Project description, domain settings, tech preferences
│   ├── feature_counter.txt        # Auto-incrementing numerical counter for feature IDs
│   │
│   ├── templates/                 # Blueprint templates for specs, plans, and tasks
│   │   ├── spec.md
│   │   ├── plan.md
│   │   ├── tasks.md
│   │   └── enterprise-spec.md
│   │
│   ├── specs/                     # Feature specifications organized by feature directories
│   │   └── 001-feature-auth/
│   │       └── spec-001.md
│   │
│   ├── plans/                     # Technical design documents
│   │   └── 001-feature-auth/
│   │       └── plan-001.md
│   │
│   ├── tasks/                     # Checklist files for agent tasking
│   │   └── 001-feature-auth/
│   │       └── tasks-001.md
│   │
│   ├── memory/                    # Persistent alignment context
│   │   ├── context.md             # Active developer session state
│   │   ├── decisions.md           # Log of design and architecture choices
│   │   └── patterns.md            # Preferred coding idioms and patterns
│   │
│   ├── logs/                      # Execution and debugging log files
│   │   └── debug.log
│   │
│   ├── cache/                     # Cached dependency information and web scrapes
│   └── tmp/                       # Temporary files used by SpecPulse commands
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
