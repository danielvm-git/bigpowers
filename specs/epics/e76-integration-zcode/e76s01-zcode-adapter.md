# story: e76s01
# ZCode adapter — Wave A greenfield skills-dir

## Requirements

### ADDED

- **R1:** `scripts/adapters/zcode.sh` renders skills to `~/.zcode/skills/<name>/SKILL.md` (override via `ZCODE_SKILLS`).
- **R2:** `wire_context` wires project AGENTS.md to `~/.zcode/AGENTS.md` (override via `ZCODE_AGENTS`).
- **R3:** Adapter is sourceable; exposes `render_skill` and `wire_context` for Wave B registry dispatch.

## Acceptance Criteria

```bash
test -f scripts/adapters/zcode.sh &&
bash -n scripts/adapters/zcode.sh &&
grep -q 'render_skill' scripts/adapters/zcode.sh &&
grep -q 'wire_context' scripts/adapters/zcode.sh &&
grep -q '\.zcode/skills' scripts/adapters/zcode.sh &&
echo OK
```

## Out of scope

- `scripts/targets.yaml` row (Wave B — e76s02)
- `scripts/install.sh`, `scripts/lib/install-helpers.js`, `bin/setup.js` hub wiring
- `scripts/verify-install.sh` contract
- ZCode plugin hook templates (unknown event names)
- E2E with ZCode binary

## Adapter guidance

- Skills path: `~/.zcode/skills/` per epic capsule (`integration_details.skills_path`)
- Config path: `~/.zcode/AGENTS.md` per capsule (`integration_details.config_path`)
- Pattern: skills-dir adapter like `gemini.sh` / `cursor.sh` (SKILL.md frontmatter + stdin SkillIR)
- Context: symlink project AGENTS.md → `~/.zcode/AGENTS.md` via `context-wire.sh`
- Test gate: scoped verify with `ZCODE_SKILLS` temp dir (no live home writes in CI)
