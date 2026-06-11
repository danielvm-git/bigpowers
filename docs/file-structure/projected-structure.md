# Projected bigpowers Project Directory Structure

Below is the projected filesystem folder and file structure for a hypothetical project built using the `bigpowers` methodology.

```text
my-project/
├── .github/                       # CI/CD workflows and action configurations
├── .gemini/                       # Extension configs for Gemini CLI (auto-generated)
├── .cursor/                       # Extension configs for Cursor rules (auto-generated)
│   └── rules/                     # Auto-generated .md rules from SKILL.md files
│
├── specs/                         # MANDATORY: All planning and spec output lives here
│   ├── state.yaml                 # Active session state, current epic/bug, git details
│   ├── release-plan.yaml          # Release goals, target semver, prioritized epics
│   ├── execution-status.yaml      # Flat key-value store mapping stories (e.g. e01s01) to states
│   ├── planning-status.yaml       # Discover-phase checklist (optional status tracking)
│   │
│   ├── requirements/              # Product and domain definitions
│   │   ├── SCOPE_LATEST.yaml      # Detailed scope and functional requirements
│   │   ├── VISION_LATEST.yaml     # North star goals and initiative context
│   │   ├── GLOSSARY_LATEST.yaml   # Domain glossary/vocabulary
│   │   └── snapshots/             # Frozen baselines per release version
│   │       └── release-1.0.0/     # Copied release-plan, scope, vision on baseline freeze
│   │
│   ├── epics/                     # Epic and Story specifications
│   │   ├── e01-auth-system.yaml   # Epic-level plan, verification steps, and task list
│   │   └── e02-user-profile.yaml
│   │
│   ├── plans/                     # Tech architecture and architectural plans
│   │   ├── TECH_STACK_LATEST.md   # Base architecture, frameworks, database layouts
│   │   ├── TEST_PLAN_LATEST.md    # Test strategies and frameworks to use
│   │   ├── REFACTOR_LATEST.md     # Structural refactoring guidelines
│   │   └── IMPACT_LATEST.md       # Pre-calculated impact of changes
│   │
│   ├── adr/                       # Architectural Decision Records
│   │   ├── 0001-use-postgresql.md
│   │   └── 0002-jwt-authentication.md
│   │
│   └── bugs/                      # Bug investigation records
│       ├── registry.yaml          # Auto-generated bug index
│       └── BUG-001-login-fails.md # Investigation, root-cause, fix verification plan
│
├── scripts/                       # Shell scripts executing core bigpowers automation
│   ├── sync-skills.sh             # Syncs SKILL.md sources into .cursor and .gemini rules
│   ├── land-branch.sh             # Safely squash-merges and lands a feature branch
│   ├── validate-specs-yaml.sh     # Lints and validates specs/ YAML schemas
│   └── bp-yaml-set.sh             # Helper tool to programmatically update state YAMLs
│
├── profiles/                      # Git and integration profiles
│   └── solo-git.md                # Solo-developer specific flow instructions
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
├── GEMINI.md                      # Gemini-specific agent constraints and token directives
├── CONVENTIONS.md                 # Strict code style rules, testing mandates, and git guidelines
└── package.json                   # Project manifest (includes versioning and dev dependencies)
```
