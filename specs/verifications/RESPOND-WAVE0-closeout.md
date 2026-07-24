# Respond Review — Wave 0 Closeout Summary

**Branch:** `feat/wave0-closeout`  
**Order:** e60 → e63 → e77 → e78

## Must-fix applied
- Claude hook path → `skills/guard-git/...` (install.sh + install-helpers)
- `installGlobal` links `hooks/lib` for guard-git runtime
- `pi` in TOOLS; `linkHook` throws on missing source

## Should-fix applied
- Golden gate `install-helpers`; uninstall `repoRoot` prefix
- Cursor selftest; deprecated install-cursor-skills* → rules symlink
- `linkDir` fail-loud; setup.js Cursor per-project note

## Deferred
- JS path settings.json jq merge / create-if-missing
- Local project uninstall coverage

## Verify
`node --check bin/setup.js && node --check scripts/lib/install-helpers.js && bash scripts/test-install-helpers.sh && bash scripts/golden-g04-selftest.sh` → PASS

**Wave 0 COMPLETE — ready for Phase 0**
