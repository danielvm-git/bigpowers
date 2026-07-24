# story: e69s01
# MiMo Code adapter — Wave A skills-dir (.mimocode/skills/)

**type:** feat  
**risk:** P2  
**context:** infra  
**bcps:** 2

## Context

Wave A adapter-only story for epic e69. MiMo Code (XiaomiMiMo/MiMo-Code) discovers skills at `.mimocode/skills/<name>/SKILL.md`. No adapter exists yet. This story adds `scripts/adapters/mimo.sh` following the pi.sh/cursor.sh SkillIR pattern. Registry wiring (`targets.yaml`), install hub files, and verify-install assertions are **Wave B** — explicitly out of scope here.

## Requirements

### ADDED

- `scripts/adapters/mimo.sh` exports `render_skill` writing SKILL.md frontmatter + body to `${MIMO_SKILLS:-.mimocode/skills}/$IR_NAME/SKILL.md`
- Adapter accepts SkillIR JSON on stdin (same contract as pi.sh/cursor.sh)
- Adapter exports `wire_context` symlinking AGENTS.md via `context-wire.sh`
- Story tagged `# story: e69s01` in adapter source

## 17. Acceptance Criteria

```bash
test -f scripts/adapters/mimo.sh &&
bash -c 'source scripts/adapters/mimo.sh && declare -f render_skill wire_context >/dev/null' &&
REPO="$(git rev-parse --show-toplevel)" &&
TMP="$(mktemp -d)" &&
cd "$TMP" &&
export IR_NAME=smoke IR_DESC_ESCAPED=Smoke IR_BODY='# Smoke' MIMO_SKILLS=.mimocode/skills &&
source "$REPO/scripts/adapters/mimo.sh" &&
render_skill &&
test -f .mimocode/skills/smoke/SKILL.md &&
grep -q smoke .mimocode/skills/smoke/SKILL.md &&
echo OK
```

## Out of scope

- `scripts/targets.yaml` mimo row (Wave B)
- `install.sh`, `install-helpers.js`, `setup.js`, `verify-install.sh` changes
- MiMo plugin rendering (`.mimocode/plugins/` — future story)
- Hooks (MiMo has none per epic research)
- E2E with MiMo Code binary

## Risks

- **Registry gap:** `test-adapters.sh mimo` fails until Wave B adds targets.yaml row — mitigated by standalone smoke verify above.
- **Context file:** MiMo may prefer project-specific config; Wave A uses AGENTS.md symlink per e37 context spine.
