# Projected MetaSpec Project Directory Structure

Below is the projected filesystem folder and file structure for a hypothetical **speckit** (Spec-Driven toolkit) generated using **MetaSpec**.

```text
my-speckit/
├── README.md                      # Toolkit documentation and quick start guide
├── AGENTS.md                      # AI agent guide (including token optimization and slash commands)
├── pyproject.toml                 # Python project configuration and dependency settings
├── .gitignore
│
├── memory/
│   └── constitution.md            # Foundational design principles and code invariants
│
├── scripts/
│   ├── init.sh                    # Initialization scripting for the generated toolkit
│   └── validate.sh                # Validation scripting for parsing specifications
│
├── templates/
│   └── spec-template.md           # Blueprint template for new specifications
│
├── specs/                         # Active requirements (created if initialized with --spec-kit)
│   └── main-feature-spec.md
│
└── src/
    └── my_spec_kit/               # Python source code package for the custom speckit
        ├── __init__.py
        ├── cli.py                 # Command line interface definitions
        ├── parser.py              # Parser module (e.g. YAML or Markdown syntax processor)
        └── validator.py           # AST or field-level semantic validation rules
```
