# Projected SpecBoot Project Directory Structure

Below is the projected filesystem folder and file structure for a hypothetical project built using **SpecBoot** (LIDR OpenSpec Enhancement).

```text
my-project/
├── .github/                       # CI/CD workflows and action configurations
│
├── docs/                          # Codebase contracts and engineering standards
│   ├── api-spec.yml               # OpenAPI documentation contract (Single Source of Truth)
│   ├── data-model.md              # DB relations, tables, columns, and seed requirements
│   ├── base-standards.md          # Project conventions and architecture patterns
│   ├── backend-standards.md       # API, database, routing, and controller code style guidelines
│   ├── frontend-standards.md      # UI component, state management, and asset conventions
│   ├── documentation-standards.md # File headers, comments, and changelog guidelines
│   ├── development_guide.md       # Local installation and run guides
│   └── openspec-tasks-mandatory-steps.md # Standard checklist for change proposal compliance
│
├── ai-specs/                      # Agent instruction environment and helpers
│   ├── specboot-instructions.md   # Setup rules detailing how to run prompts with SpecBoot
│   ├── agents/                    # Personas and execution boundaries for AI roles
│   │   ├── tester.md
│   │   └── architect.md
│   │
│   ├── skills/                    # Specialized prompt skills for the project code base
│   │   ├── seed-database.md
│   │   └── generate-route.md
│   │
│   └── scripts/                   # CLI helpers for bootstrapping and validating files
│       ├── run-checks.sh
│       └── generate-scaffold.sh
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
