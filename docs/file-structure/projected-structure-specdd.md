# Projected specdd Project Directory Structure

Below is the projected filesystem folder and file structure for a hypothetical project built using **specdd**.

```text
my-project/
├── .github/                       # CI/CD workflows and action configurations
├── .specdd/                       # SpecDD agent instructions and bootstrap rules
│   ├── bootstrap.md               # Main bootstrap directing agents to read project specs
│   ├── bootstrap.project.md       # Project-wide constraints and code standards
│   └── bootstrap.local.md         # Developer local environment path overrides
│
├── src/                           # Application Source Code (with colocated specs)
│   ├── components/
│   │   ├── navigation/
│   │   │   ├── navigation.sdd     # Local spec for the navigation folder/area
│   │   │   ├── Header.tsx         # Source code component
│   │   │   └── Header.sdd         # Colocated spec detailing Header rules (same basename)
│   │   │
│   │   └── button/
│   │       ├── Button.tsx
│   │       └── Button.sdd         # Colocated spec for the Button component
│   │
│   ├── lib/
│   │   ├── api.ts
│   │   └── api.sdd                # Colocated spec for API methods
│   │
│   └── index.ts
│
├── tests/                         # Automated tests (verifiers)
│   └── integration/
│
├── my-project.sdd                 # Root project specification (intent, modules, global rules)
├── CLAUDE.md                      # Agent fast-reference instructions (commands, conventions)
└── package.json                   # Project manifest (includes versioning and dev dependencies)
```
