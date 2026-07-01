# Contributing to bigpowers

Thanks for your interest in contributing! bigpowers is an open-source system of 69+ AI agent skills for spec-driven, test-first software development. This guide will help you get started.

## Code of Conduct

Be respectful, constructive, and patient. We're building tools for developers — treat each other like the professionals we are.

## Before You Start

1. **Read the docs.** Start with [`README.md`](README.md), [`CLAUDE.md`](CLAUDE.md), and [`CONVENTIONS.md`](CONVENTIONS.md). These define the project's architecture, conventions, and engineering standards.
2. **Run bigpowers.** Install with `npx bigpowers` and walk through the experience as a user before contributing as a developer.
3. **Understand the lifecycle.** bigpowers follows a 6-phase methodology: Discover → Elaborate → Plan → Build → Verify → Release. Read [`docs/WORKFLOW-SOP-v2.md`](docs/WORKFLOW-SOP-v2.md) for the full SOP.

## How to Contribute

### Reporting Bugs

- Search [existing issues](https://github.com/danielvm-git/bigpowers/issues) first.
- Use the bug report template if one exists.
- Include: what you did, what you expected, what happened, your OS, Node version, and any error output.
- If the bug is in a specific skill, name the skill.

### Proposing Features

- Open a [discussion](https://github.com/danielvm-git/bigpowers/discussions) before opening a PR for a new feature. We want to align on the approach before you invest time.
- New skills must follow the [verb-noun kebab-case naming convention](CONVENTIONS.md#skill-naming--conventions-and-exceptions) (ADR-0001).
- New features should include: a description of the problem, the proposed solution, and any alternatives considered.

### Proposing a New Skill

Skills are the core of bigpowers. To propose a new one:

1. **Check the index.** [`SKILL-INDEX.md`](SKILL-INDEX.md) lists all 69+ active skills. Make sure your idea doesn't overlap with an existing skill.
2. **Identify the phase.** Every skill belongs to one of 7 phases: Discover, Design, Plan, Build, Verify, Release, Sustain.
3. **Write a SKILL.md draft.** Follow the structure of existing skills. Every SKILL.md needs: a description, phase, instructions, and references.
4. **Open a discussion.** Share your SKILL.md draft in a GitHub discussion. We'll review whether it fits the roadmap before you invest in a full PR.
5. **Once approved,** open a PR with:
   - A new directory: `[verb]-[noun]/` containing `SKILL.md`
   - Evidence that you ran `bash scripts/sync-skills.sh` to regenerate artifacts
   - A Conventional Commit: `feat(skills): add [verb]-[noun] skill`

### Pull Request Process

1. **Branch from main.** Use `kickoff-branch` or create a feature branch manually.
2. **Follow CONVENTIONS.md.** F.I.R.S.T tests. SOLID. Boy Scout Rule. No `any` types. Functions under 20 lines.
3. **Run sync.** After any SKILL.md change, run `bash scripts/sync-skills.sh` to regenerate generated artifacts. Do not edit `.cursor/rules` or `.gemini/extensions/` directly.
4. **Validate YAML.** Run `bash scripts/validate-specs-yaml.sh` if you've changed any `specs/*.yaml` files.
5. **Write Conventional Commits.** Format: `type(scope): description`. See [CONVENTIONS.md](CONVENTIONS.md#conventional-commits--semantic-versioning) for the full spec.
6. **Open a PR.** Use `gh pr create`. Include: what you changed, why, how to verify, and any open questions.
7. **Wait for review.** A maintainer will review within a few days. Be responsive to feedback.

### Writing Documentation

Documentation is a first-class contribution. You don't need to write code to help.

- **README improvements:** Clearer install instructions, better examples, fixed typos.
- **Skill docs:** Every SKILL.md should be clear enough for a new user to understand without asking.
- **Guides and tutorials:** Walkthroughs for specific use cases (e.g., "Using bigpowers with a Next.js project").
- **Translations:** Help make bigpowers accessible to non-English-speaking developers.

## Development Setup

```bash
# Clone the repo
git clone https://github.com/danielvm-git/bigpowers.git
cd bigpowers

# Install dependencies + run postinstall sync
npm install

# Or manually:
bash scripts/install.sh
npm run sync
```

### Prerequisites

- **Bash** — required for all scripts
- **Node.js** v14+
- **jq** — highly recommended for YAML validation scripts
- **An AI coding tool** — Claude Code, Cursor, Gemini CLI, or pi (to test skills end-to-end)

### Project Structure

```
bigpowers/
├── [skill-name]/       # Each skill has its own directory with SKILL.md
├── scripts/            # Install, sync, validation, and compliance scripts
├── specs/              # YAML cockpit — state.yaml, release-plan.yaml, epics/
├── docs/               # Guides and references
├── profiles/           # Stack-specific conventions (TypeScript+Vue, Node Service, etc.)
├── .cursor/rules/      # Generated — do not edit directly
├── .gemini/extensions/ # Generated — do not edit directly
└── .pi/skills/         # Generated — do not edit directly
```

**Never edit generated files.** Always edit the source `SKILL.md` and run `bash scripts/sync-skills.sh`.

## Testing

- **Skill validation:** `bash scripts/sync-skills.sh` validates SKILL.md syntax and structure.
- **YAML validation:** `bash scripts/validate-specs-yaml.sh` checks the YAML cockpit for correctness.
- **Compliance check:** `npm run compliance` runs a comprehensive check of the repo.
- **Manual testing:** The best test of a skill is using it with an AI coding tool. After changes, run `survey-context` or invoke the skill to verify it works.

## Getting Help

- **Questions?** Open a [GitHub discussion](https://github.com/danielvm-git/bigpowers/discussions).
- **Bug?** Open an [issue](https://github.com/danielvm-git/bigpowers/issues).
- **Want to chat?** [Link to Discord/Slack — to be added]

## Recognition

All contributors are recognized in the README and release notes. Significant contributions (new skills, major features) get a shoutout in the changelog and on social media. We believe in giving credit where it's due.

---

*bigpowers is MIT-licensed. By contributing, you agree that your contributions will be licensed under the same terms.*
