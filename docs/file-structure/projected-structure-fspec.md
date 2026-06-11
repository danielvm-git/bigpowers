# Projected fspec Project Directory Structure

Below is the projected filesystem folder and file structure for a hypothetical project built using **fspec**.

```text
my-project/
├── .github/                       # CI/CD workflows and action configurations
│
├── spec/                          # Core BDD specification folder
│   ├── FOUNDATION.md              # Domain, bounded contexts, personas, and capabilities definitions
│   ├── foundation.json            # Machine-readable representation of FOUNDATION.md
│   ├── TAGS.md                    # Structured categorization rules for test scenarios
│   ├── tags.json                  # Machine-readable tags metadata
│   ├── epics.json                 # Epic list with description and status
│   ├── prefixes.json              # Custom prefix definitions for work units
│   ├── work-units.json            # Authoritative database registry of all work units (checkpoints)
│   │
│   ├── attachments/               # Screenshots, mockups, and event storming mermaid diagrams
│   │   ├── event-storming.mermaid
│   │   └── mock-dashboard.png
│   │
│   └── features/                  # BDD Gherkin specifications and coverage maps
│       ├── add-user.feature       # Gherkin scenarios for a feature/bug/chore/spike
│       ├── add-user.feature.coverage # Detailed validation and test coverage mappings
│       ├── fix-login-bug.feature
│       └── fix-login-bug.feature.coverage
│
├── src/                           # Application Source Code
│   ├── components/
│   ├── lib/
│   └── index.ts
│
├── tests/                         # Automated tests mapped directly in .feature.coverage files
│   └── integration/
│
├── AGENTS.md                      # Detailed rules for agent integration and step execution flow
├── CLAUDE.md                      # Agent fast-reference instructions (commands, conventions)
└── package.json                   # Project manifest (includes versioning and dev dependencies)
```
