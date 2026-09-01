# story: e82s04
# Contributors

This file records external contributors whose work has been adapted or
upstreamed into bigpowers. Code authored inside this repository is committed
directly by [@danielvm-git](https://github.com/danielvm-git).

---

## Community Contributors

### Kevin Oberlies — [favilo/bigpowers](https://github.com/favilo/bigpowers)

**Contribution: Jujutsu VCS support + configurable project-runtime library (e82s01, e82s02)**

Kevin built and maintained a fork that introduced two cohesive capabilities:

1. **`scripts/lib/project-runtime.sh`** — a configurable project-settings library
   (`bp_specs_path`, `bp_vcs_kind`) that reads from `.bigpowers/config.yaml` or
   environment variables, with auto-detection of Jujutsu repos via `.jj/`.
   Enables bigpowers to operate in consumer projects with non-standard specs
   directories or VCS backends.

2. **Jujutsu-aware lifecycle skills** — updated `commit-message`, `kickoff-branch`,
   `release-branch`, and `survey-context` to read `state.yaml` `vcs.kind` and
   branch on native `jj` commands vs. Git, including `jj workspace add` for
   isolation, `jj bookmark set` for releases, and colocated-repo detection.

Discovered via fork audit on 2026-09-01.

---

### XcluEzy7 — [XcluEzy7/bigpowers](https://github.com/XcluEzy7/bigpowers)

**Contribution: OMP plugin extension (e82s03)**

XcluEzy7 built a native [oh-my-pi](https://github.com/oh-my-pi) OMP plugin that:

- Discovers every skill in `skills/` at runtime and registers each as a slash command.
- Exposes a unified `bigpowers_skill` LLM tool with `list`/`get`/`run` operations.
- Ports bigpowers' git-safety pre-tool-use hook into OMP's `tool_call` event API,
  blocking dangerous patterns and enforcing Conventional Commits.

The upstream port (in `extensions/omp-hooks.ts`) rebases the discovery logic onto
the current `skills/<name>/SKILL.md` source layout. The model-frontmatter stripping
and foreign AGENTS.md content from the original branch were not carried over.

Discovered via fork audit on 2026-09-01.
