# clean-my-room — reference patterns

Optional commands for the agent. Adapt paths; **dry-run** before bulk delete.

## Discover large top-level entries

```sh
du -sh ./* .[!.]* 2>/dev/null | sort -hr | head -30
```

## Find common logs (respect `.gitignore` when using fd)

```sh
fd -t f '\.log$' . 2>/dev/null
fd 'npm-debug' . 2>/dev/null
```

## Find build-like dirs (review list before `rm -rf`)

```sh
fd -t d '^(dist|build|out|target|\.next|coverage)$' . --max-depth 3 2>/dev/null
```

## Stray markdown at repo root (heuristic)

```sh
ls -1 ./*.md 2>/dev/null
fd -t f '^(draft|scratch|untitled|TODO|notes)' . --max-depth 1 2>/dev/null
```

## Git-safe moves

```sh
git status -sb
git check-ignore -v <path>   # was ignored?
# Tracked: git mv old new
# Untracked: mkdir -p … && mv old new
```

## `.gitignore` revision (after cleanup)

**Goal:** stop regenerated junk from polluting `git status`, without hiding real source.

1. **Read** root `.gitignore` and, in monorepos, `apps/*/.gitignore` / `packages/*/.gitignore` as needed. Check **`.git/info/exclude`** for machine-only rules that should *not* be committed (keep personal noise there; don’t copy into shared `.gitignore` unless the team agrees).
2. **Per-path checks** (last match wins; shows which file defined the rule):

   ```sh
   git check-ignore -v path/to/artifact
   git status -u --ignored    # optional: see ignored names (noisy)
   ```

3. **Pattern style**
   - Leading `/` = relative to the `.gitignore`’s directory (e.g. `/dist/` = only that folder at that level, not all nested `dist` unless intended).
   - `**` for deep trees, e.g. `**/*.log`, when noise appears at many depths.
   - **Negation** (`!`) is tricky: later rules, parent dirs, and `git add -f` interact—prefer narrow positive ignores over `!` unless you already use negation in that file.
4. **Do not** add rules that would ignore: application source, small JSON/YAML config the repo tracks, or `!important` assets. When unsure, run `git check-ignore -v` on a *known good* file that must stay tracked.
5. **Tracked but should be ignored** (user already committed `build/` once): this skill does not silently fix history; flag `git rm -r --cached <path>` + `.gitignore` as a **separate** explicit step the user must approve.
6. **Global excludes** (optional heads-up for “why is this still ignored?”):

   ```sh
   git config --get core.excludesfile
   ```

## Safety: never pass through these in automated deletes

- `.git/`, `.svn/`, `.hg/`
- `node_modules/`, `vendor/`, `venv/`, `.venv/`, `__pypackages__/`
- Files matching `.env`, `.env.*` (except `.env.example` if intentional)
- `~/.ssh`, `id_rsa*`, `*.pem` inside project trees

## Post-deploy / server-ish extras (name buckets to stack)

- Docker: dangling images/volumes (only if user asked for Docker cleanup; requires `docker` context).
- CI: `*.log` under `build/`, artifact dirs from previous runs.
- K8s: local `*.kube`, tmp kubeconfigs—list only; do not delete without confirmation.

## Inspiration

- Same **inventory → plan → confirm → act** flow as [post-deploy environment cleanup](https://mcpmarket.com/tools/skills/post-deploy-environment-cleanup) style workflows.
- [Agent template public](https://github.com/matsuni-kk/agent_template_public): honor **Flow** (draft) vs **Stock** (stable); do not “clean” user drafts from Flow without explicit approval.
