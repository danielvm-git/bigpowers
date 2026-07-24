# e74s02: Install hub wiring (Wave B)

<!-- story: e74s02 -->

Wire Antigravity CLI into the bigpowers install hub: `install.sh`, `install-helpers.js`, `bin/setup.js`, `targets.yaml`, and `verify-install.sh`. Uses separate `~/.gemini/antigravity-cli/skills/` path — no clash with e64 Gemini `.gemini/extensions/bigpowers`.

## In scope

- `install_agy()` / `install_antigravity()` / `uninstall_agy()` in `scripts/install.sh`
- `antigravity` and `agy` cases in `scripts/lib/install-helpers.js` (global + local + uninstall)
- Add `antigravity` and `agy` to `SUPPORTED_IDS` in `bin/setup.js`
- Expand `agy` row in `scripts/targets.yaml` with skill output + contract
- Antigravity contract assertions in `scripts/verify-install.sh`
- `scripts/test-agy-hub.sh` regression harness
- Full `render_skill` in `scripts/adapters/agy.sh`

## Out of scope

- Live `agy` binary UAT (proprietary beta)
- Hook wiring to `~/.gemini/config/hooks.json` (deferred)
- `.gemini/extensions/**` (e64 Gemini CLI)

## Verify

```bash
bash scripts/test-agy-hub.sh &&
bash scripts/verify-install.sh &&
bash -n scripts/install.sh &&
node --check scripts/lib/install-helpers.js &&
node --check bin/setup.js &&
echo OK
```
