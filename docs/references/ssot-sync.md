# story: e45s10 e84s01
# docs/references SSOT Sync

Agent-guidance files under `docs/references/` are distilled from upstream sources, not hand-edited ad hoc. Canonical inputs live in `CLAUDE.md`, `docs/PRINCIPLES.md`, and `skills/*/SKILL.md`.

| Action | Command |
|--------|---------|
| Regenerate locally | `bash scripts/sync-references.sh` |
| Manifest | `scripts/references-manifest.yaml` |
| Scheduled CI | `.github/workflows/sync-references.yml` (weekly) |

After changing SKILL.md `model:` frontmatter or token-management prose in CLAUDE.md, run `sync-references.sh` to refresh reference docs and `.sync-stamp`.
