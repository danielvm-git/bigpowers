# Audit Report — e61s02: Install hub wiring (Wave B)

**Date:** 2026-07-24
**Mode:** `--gate`
**Epic:** e61 — Integration: Hermes Agent — Skills + 3 Hook Systems
**Story:** e61s02 — Install hub wiring (Wave B)
**Files:** `scripts/install.sh`, `scripts/lib/install-helpers.js`, `bin/setup.js`, `scripts/verify-install.sh`, `scripts/test-hermes-hub.sh`, capsule specs

**Verify:**
```bash
bash scripts/test-hermes-hub.sh
bash scripts/verify-install.sh
bash -n scripts/install.sh && node --check scripts/lib/install-helpers.js && node --check bin/setup.js
```
**Verify result:** PASS

---

## Gate summary (stderr-style)

```
PASS Supply Chain & Security
PASS Provenance & Metadata
PASS Law of Demeter
PASS CONVENTIONS.md Compliance
PASS Scope
PASS Boy Scout Rule
PASS Types and Safety
PASS Test Coverage
PASS SOLID and Heuristics
PASS Code Style
PASS Agent Readability
```

**Overall: PASS**

---

## Supply Chain & Security

- [x] No new external packages
- [x] Symlink-only install; config-bridge writes `instructions:` path only (no shell hooks auto-enabled in config)
- [x] Hook template symlink is optional; user must enable in `~/.hermes/config.yaml`
- [x] THREAT_MODEL Wave B mitigations honored (no auto `hooks:` merge)

## Provenance & Metadata

- [x] Story tag `# story: e61s02` on install helpers + test harness
- [x] Capsule `e61s02-tasks.yaml` + spec present; epic.yaml updated

## Scope

- [x] Hub wiring only — Wave A adapter/hooks untouched
- [x] targets.yaml hermes row already complete (no edit required)

## Test Coverage

- [x] `scripts/test-hermes-hub.sh` — 18 assertions
- [x] `verify-install.sh` — hermes source + setup.js + install-helpers checks
- [x] Wave A `test-hermes-adapter.sh` still PASS

## SOLID and Heuristics

- [x] `linkRenderedSkills` / `bridgeHermesConfig` helpers keep install cases small
- [x] Mirrors pi/codex install patterns (symlink rendered output, idempotent config bridge)

---

**Next:** commit-message → release-branch (PR)
