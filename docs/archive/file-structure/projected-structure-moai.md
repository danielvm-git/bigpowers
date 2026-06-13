# Projected MoAI-ADK Project Directory Structure

Below is the projected filesystem folder and file structure for a hypothetical project built using **MoAI-ADK**.

```text
my-project/
├── .github/                       # CI/CD workflows and action configurations
├── .moai/                         # Core MoAI agent toolkit workspace
│   ├── manifest.json              # Authoritative files-to-skills registry index
│   ├── status_line.sh             # CLI status bar utility for active session rendering
│   │
│   ├── config/                    # LLM settings, agent templates, and parameter overrides
│   │
│   ├── project/                   # Foundations and high-level structure maps
│   │   ├── product.md             # Vision, roadmap, and requirements overview
│   │   ├── structure.md           # Mapped directory architecture and constraints
│   │   ├── tech.md                # Technology standards and dependencies
│   │   └── codemaps/              # Automatically generated AST structure index files
│   │
│   ├── specs/                     # Target specifications folder
│   │   ├── SPEC-AUTH-001/         # Feature specific specification folder
│   │   │   ├── spec.md            # Target feature functional specification
│   │   │   ├── plan.md            # Technical design and implementation step plan
│   │   │   └── acceptance.md      # Acceptance criteria and verification checklist
│   │   └── _archive/              # Shelved/superseded spec directories
│   │
│   ├── decisions/                 # Architecture Decision Records (ADRs) and choices
│   │   └── DEC-001-postgresql.md
│   │
│   ├── design/                    # UX layouts and mockups
│   │
│   ├── brain/                     # High-density agent memory and context learnings
│   │
│   ├── release/                   # Release plans and deployment manifests
│   │
│   ├── reports/                   # Lint reports, test outcomes, and coverage reviews
│   │
│   └── state/                     # Session locks and active developer story states
│
├── src/                           # Application Source Code (e.g. Go backend)
│   ├── cmd/
│   ├── pkg/
│   └── internal/
│
├── tests/                         # Automated tests (verifiers)
├── CLAUDE.md                      # Agent fast-reference instructions (commands, conventions)
└── package.json                   # Project manifest (includes versioning and dev dependencies)
```
