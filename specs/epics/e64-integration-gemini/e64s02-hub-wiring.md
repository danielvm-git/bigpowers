# e64s02: Install hub wiring (Wave B)

Wire Gemini CLI into the bigpowers install hub: `install.sh`, `install-helpers.js`, `bin/setup.js`, `targets.yaml`, and `verify-install.sh`. Wave A hook templates remain unchanged.

## In scope

- `install_gemini()` / `uninstall_gemini()` in `scripts/install.sh` — symlink extension to `~/.gemini/config/plugins/bigpowers/`, symlink Wave A hook templates to `~/.gemini/hooks/`, merge `BeforeTool` + `SessionStart` entries into `~/.gemini/settings.json` when present.
- `gemini` hook cases in `scripts/lib/install-helpers.js` (global + uninstall).
- Verify `gemini` in `SUPPORTED_IDS` in `bin/setup.js`.
- `gemini_hooks_manifest` contract in `scripts/targets.yaml` + `target-contracts.sh`.
- Gemini contract assertions in `scripts/verify-install.sh`.
- `scripts/test-gemini-hub.sh` regression harness.

## Out of scope

- Live Gemini CLI UAT against `~/.gemini/settings.json`
- Auto-enabling `before-tool-token-mgmt.sh` in settings (optional hook; symlink only)

## Verify

```bash
bash scripts/test-install-hub.sh &&
bash scripts/test-adapter-render.sh &&
bash scripts/verify-install.sh &&
bash -n scripts/install.sh &&
node --check scripts/lib/install-helpers.js &&
node --check bin/setup.js &&
echo OK
```
