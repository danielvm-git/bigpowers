### Story e48s15: Refactor Skills Render Pipeline to Hybrid JSON Seam — Implementation Steps

**type:** refactor
**risk:** P0
**context:** infra
**Context**: Replaces the shallow bash global-variable seam between `sync-skills.sh` and `scripts/adapters/*.sh` with a deep JSON contract (`SkillIR`) piped over `stdin`, powered by a Python engine. This adheres to ADR-0008 and eliminates shared state coupling without violating the project's adapter file rules.

## Requirements

#### MODIFIED: Skills Render Pipeline data flow
**Before:** `sync-skills.sh` parses `SKILL.md` via Bash regex, exports global variables (`IR_NAME`, `IR_BODY`), and sources `scripts/adapters/*.sh` in the same process.
**After:** `sync-skills.sh` delegates parsing to `scripts/lib/srp-engine.py`, which constructs a `SkillIR` JSON and pipes it over `stdin` to subprocessed `scripts/adapters/*.sh` adapters.

## Steps

1. Scaffold `scripts/lib/srp-engine.py` to parse `SKILL.md` frontmatter/body into JSON and output it to stdout. (ref: ADR-0008) → verify: `python3 scripts/lib/srp-engine.py skills/plan-work/SKILL.md --dry-run | jq .name`
2. Update the `cursor` adapter (`scripts/adapters/cursor.sh`) to read `SkillIR` JSON from `stdin` via `jq` instead of relying on Bash globals. (ref: ADR-0008) → verify: `echo '{"name":"test","description":"desc","body":"content"}' | bash scripts/adapters/cursor.sh`
3. Implement subprocess dispatch in `srp-engine.py` to pipe the compiled JSON into the adapter executable. (ref: ADR-0008) → verify: `python3 scripts/lib/srp-engine.py skills/plan-work/SKILL.md --target cursor`
4. Refactor `sync-skills.sh` to remove bash-based regex parsing, delegating iteration and dispatch entirely to `srp-engine.py`. (ref: ADR-0008) → verify: `bash scripts/sync-skills.sh`

## Verification Script (Step-by-Step)

1. Verify the Python engine syntax: `python3 -m py_compile scripts/lib/srp-engine.py`
2. Run a dry-run parse on a known skill: `python3 scripts/lib/srp-engine.py skills/plan-work/SKILL.md --dry-run` and visually confirm valid JSON.
3. Pass a synthetic JSON payload to `cursor.sh`: `echo '{"name":"test-skill","body":"test body"}' | bash scripts/adapters/cursor.sh` and ensure `.cursor/rules/test-skill.mdc` is created properly.
4. Execute the full pipeline: `bash scripts/sync-skills.sh`. Check that `skills-lock.json` and `.gemini/extensions/bigpowers/skills/` are updated correctly without bash global variable bleed.

## Out of scope

- Rewriting adapters into Python. They must remain bash scripts.
- Porting all adapters at once if some can be skipped (though all active ones need the `jq` update eventually).

## Risks

- **JSON Escaping:** The Markdown body might contain unescaped quotes or JSON control characters. `srp-engine.py` uses the standard `json` module, which should safely encode them, but `jq -r` in bash must cleanly decode them.
- **Backwards Compatibility:** Adapters must be fully switched over; a mixed state will break `sync-skills.sh`.
