# Agent Skills

A collection of agent skills (each folder has a `SKILL.md`) for planning, development, and tooling. This **GitHub repository** is the source for the skill content; the recommended way to install it into [Cursor](https://cursor.com) for yourself and your team is the open **`npx skills`** CLI (see below). This repo is **not** published to npm as its own package.

**GitHub address:** use `https://github.com/OWNER/skills` where `OWNER` is your org or user (this project’s public remote is `danielvm-git/skills`—swap in your fork if you use one).

## Install with npx (team, Cursor)

The [`skills` package on npm](https://www.npmjs.com/package/skills) is a **third-party** CLI that installs skills from a Git public repository into multiple coding agents, including Cursor. Project home: [MattCraftsCode/skills](https://github.com/MattCraftsCode/skills). You can also browse the ecosystem at [skills.sh](https://skills.sh).

**Requirements:** [Node.js](https://nodejs.org/) (for `npx`) and a way to read this repo from GitHub (public `https` or authenticated `git` for private repos).

**Preview skills without installing** (clone is temporary; nothing is written to your agent dirs beyond the CLI’s cache):

```sh
npx skills@latest add OWNER/skills --list
```

**Install all skills for Cursor, globally, without prompts** (typical one-liner for teammates—replace `OWNER`):

```sh
npx skills@latest add OWNER/skills -g -a cursor -y --skill '*'
```

- **Global (`-g`)** installs to **`~/.cursor/skills`**, one directory per skill (for example `~/.cursor/skills/tdd/SKILL.md`). This matches a machine-wide setup similar to the shell script in this repository.

**Install for the current project only** (no `-g`; skills live under the CLI’s project path—often **`.agents/skills/`** per upstream, not your home directory):

```sh
cd /path/to/your-app
npx skills@latest add OWNER/skills -a cursor -y --skill '*'
```
- **Install specific skills only:** add `--skill name` (repeat or see upstream docs). Use a quoted `'*'` to mean all skills, as in the one-liner above.
- If **symlinks** are a problem on your system, add **`--copy`** to the same command so files are copied instead of linked.
- If the agent does not pick up changes, start a new chat or reload the window.

**After this repo is updated on GitHub**, refresh installed skills with:

```sh
npx skills check
npx skills update
```

or run the `npx skills@latest add ...` command again.

**Private GitHub repo:** use a full URL or ssh remote so git credentials apply, for example:

```sh
npx skills@latest add https://github.com/ORG/skills
npx skills@latest add git@github.com:ORG/skills.git
```

**Project-scoped install (no `-g`)** install skills inside an application checkout (for committing them with a product repo). The upstream CLI places Cursor’s project skills under **`.agents/skills/`** for that run; see the [CLI README](https://github.com/MattCraftsCode/skills) for scope and flags.

**Example** using the public `OWNER` for this collection:

```sh
npx skills@latest add danielvm-git/skills -g -a cursor -y --skill '*'
```

## Install with the shell script (no npx)

If you prefer not to use Node, or you want a straight **rsync** from a local tree, use the scripts in [`scripts/`](scripts/) from a clone or archive of this repository.

| Script | Installs to | Use when |
| ------ | ------------ | -------- |
| [`install-cursor-skills.sh`](scripts/install-cursor-skills.sh) | **`~/.cursor/skills`** (global) | You want the same skills in Cursor for every project on this machine. |
| [`install-cursor-skills-local.sh`](scripts/install-cursor-skills-local.sh) | **`<project>/.cursor/skills`** (per repo) | You want skills only in one checkout (e.g. to commit under that app or a team template). Optional first argument: install root; default is the current directory. |

Both read skill folders from this skills repo unless you set **`SOURCE_DIR`**. Set **`TARGET_DIR`** to override the destination entirely.

### Without cloning

Download a **snapshot** of the default branch, extract, and run the script. GitHub unpacks the archive into a folder named **`skills-main`** (branch `main` + repository name). Replace `OWNER` in the URL.

```sh
curl -L https://github.com/OWNER/skills/archive/refs/heads/main.tar.gz -o skills.tar.gz
tar -xzf skills.tar.gz
cd skills-main
# Global (~/.cursor/skills):
./scripts/install-cursor-skills.sh
# Or local (./.cursor/skills in the directory you name; often run from the app project):
# ./scripts/install-cursor-skills-local.sh /path/to/your-app
```

**ZIP (e.g. Windows):** `https://github.com/OWNER/skills/archive/refs/heads/main.zip` — unzip, `cd` into `skills-main`, then run the script.

**Updates:** download and extract again, then re-run the script from the new tree.

### With git clone

```sh
git clone --depth 1 https://github.com/OWNER/skills.git
cd skills
./scripts/install-cursor-skills.sh
# Local install into another project (example):
# ./scripts/install-cursor-skills-local.sh /path/to/your-app
```

**Updates:** `git pull` in the clone, then run the same script you use (`install-cursor-skills.sh` or `install-cursor-skills-local.sh`) again.

### Script options

- **Global script:** by default, skills are written to **`~/.cursor/skills`**.
- **Local script:** by default, skills are written to **`<install-root>/.cursor/skills`** (install root is the first argument, or the current working directory).

Re-runs **overwrite** the same paths. Override sources and destinations with:

| Variable     | Default (global script)   | Default (local script)              |
| ------------ | ------------------------- | ----------------------------------- |
| `SOURCE_DIR` | Root of this skills clone | Root of this skills clone           |
| `TARGET_DIR` | `~/.cursor/skills`        | `<install-root>/.cursor/skills`     |

```sh
SOURCE_DIR=/path/to/skills-main ./scripts/install-cursor-skills.sh
# Force a custom project path (either script):
TARGET_DIR=/path/to/your-project/.cursor/skills ./scripts/install-cursor-skills.sh
```

```sh
# From the skills repo, install into another checkout’s .cursor/skills
./scripts/install-cursor-skills-local.sh /path/to/your-app
cd /path/to/your-app && /path/to/skills/scripts/install-cursor-skills-local.sh
```

## Planning and design

- **to-prd** — Turn the current conversation into a PRD and submit it as a GitHub issue.
- **to-issues** — Break a plan, spec, or PRD into vertical-slice GitHub issues.
- **grill-me** — Stress-test a plan or design through structured questioning.
- **domain-model** — Stress-test a plan against the domain model and update `CONTEXT.md` / ADRs as you decide.
- **design-an-interface** — Explore multiple interface designs for a module with parallel sub-agents.
- **request-refactor-plan** — Build a small-commit refactor plan via interview, then file it as a GitHub issue.
- **zoom-out** — Ask the agent to step up a level of abstraction and map modules and callers.

## Development

- **tdd** — Red–green–refactor and vertical slices.
- **triage-issue** — Find root cause in the repo and file a GitHub issue with a TDD-oriented fix plan.
- **fix-and-report** — End-to-end bug fix: triage, diagnose, implement TDD fix, and report to GitHub.
- **improve-codebase-architecture** — Use `CONTEXT.md` and `docs/adr/` to find architectural improvements.
- **migrate-to-shoehorn** — Move tests from `as` assertions to `@total-typescript/shoehorn`.
- **scaffold-exercises** — Create exercise layouts with problems, solutions, and explainers.

## Tooling and setup

- **setup-pre-commit** — Husky, lint-staged, Prettier, typecheck, and tests on commit.
- **git-guardrails-claude-code** — Block dangerous git commands via hooks in Claude Code.

## GitHub and QA

- **github-triage** — Triage issues with a label-based workflow and `gh`.
- **qa** — Conversational bug reports; agent explores the codebase and files GitHub issues.

## Writing and knowledge

- **write-a-skill** — Author new skills with structure and progressive disclosure.
- **edit-article** — Revise articles for structure, clarity, and tone.
- **ubiquitous-language** — Build a DDD-style glossary from the conversation.
- **obsidian-vault** — Work with an Obsidian vault, wikilinks, and index notes.

## Other

- **caveman** — Ultra-compressed communication mode (invoked with user phrases like “caveman mode”).

## Repository layout

Each skill is a **top-level directory** in this repo containing **`SKILL.md`**. The install scripts only sync those directories; hidden top-level directories (names starting with `.`) are skipped. The `npx skills` CLI discovers the same set of skills from GitHub (recursive search for valid `SKILL.md` files).
