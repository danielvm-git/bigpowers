# story: e53s02 e84s01
# Tombstone Aliases

Every skill rename or merge ships a tombstone alias for one release, so consumers referencing the old name don't break immediately.

## Mechanism

1. Run `bash scripts/tombstone-skill.sh <old-name> <new-name-or-merge-target>` when renaming or merging a skill. It replaces `skills/<old-name>/SKILL.md` with a stub pointing at the new name/location, preserves the old skill's `# story: eNNsNN` tags for traceability, and registers the mapping in `specs/tombstones.yaml` (old name, new name/target, creation timestamp, and `created_at_version`).
2. Run `bash scripts/validate-tombstones.sh` to confirm every registered tombstone's stub still resolves, and to flag any tombstone whose `created_at_version` is in a different minor/major release train (major.minor) than current version. Patch-only bumps within the same minor version do not expire a tombstone.
3. Update `docs/references/model-profiles.md` skill-count annotations alongside real uses of `tombstone-skill.sh`. A tombstone stub is still a `skills/*/SKILL.md` file and increments the live skill count.

### Rejected Names
Both old and new name must be a bare kebab-case skill name (`^[a-z][a-z0-9-]*$`). `tombstone-skill.sh` refuses invalid path characters before touching the filesystem.
