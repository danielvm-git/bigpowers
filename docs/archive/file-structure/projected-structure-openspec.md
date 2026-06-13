# Projected OpenSpec Project Directory Structure

Below is the projected filesystem folder and file structure for a hypothetical project built using **OpenSpec**.

```text
my-project/
├── .github/                       # CI/CD workflows and action configurations
│
├── openspec/                      # Core OpenSpec change management directory
│   ├── changes/                   # Active and historical changesets
│   │   ├── add-dark-mode/         # Focused directory for an active proposal/feature
│   │   │   ├── proposal.md        # Problem statement, why, and high-level description
│   │   │   ├── specs/             # Scenarios and detailed requirements
│   │   │   │   └── theme-toggle.md
│   │   │   ├── design.md          # Technical design, file plan, and API specifications
│   │   │   └── tasks.md           # Implementation checklist and task boundary declarations
│   │   │
│   │   └── archive/               # Historical change archives for auditing and alignment
│   │       ├── 2026-05-01-oauth/
│   │       └── 2026-06-10-landing/
│   │
│   └── schemas/                   # Custom workflow and tool schemas (optional override bundle)
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
