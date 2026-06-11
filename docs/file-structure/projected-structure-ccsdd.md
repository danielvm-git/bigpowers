# Projected cc-sdd Project Directory Structure

Below is the projected filesystem folder and file structure for a hypothetical project built using the **cc-sdd** framework.

```text
my-project/
├── .github/                       # CI/CD workflows and action configurations
├── .agent/                        # Active agent integrations (e.g. Antigravity)
│   └── skills/                    # 17 progressive disclosure agent skills (e.g. kiro-impl)
│
├── .kiro/                         # Shared project specifications and templates
│   ├── steering/                  # Steering instructions and AI guidance docs
│   │   └── rules.md
│   │
│   ├── settings/                  # Configurations and schema constraints
│   │   ├── templates/             # Custom blueprints (requirements.md, design.md, tasks.md)
│   │   └── rules/                 # Judgment standards and verification constraints
│   │
│   └── specs/                     # Feature boundary documentation
│       ├── brief.md               # Feature description from kiro-discovery
│       ├── roadmap.md             # Breakdown of multi-spec initiatives (if applicable)
│       └── photo-albums/          # Scoped feature specification folder
│           ├── requirements.md    # EARS-format specifications and acceptance criteria
│           ├── design.md          # Visual maps (Mermaid diagrams) and File Structure Plan
│           └── tasks.md           # Implementation checklist with boundary/dependency markers
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
