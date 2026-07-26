# e61s02: Install hub wiring (Wave B)

Wire Hermes Agent into the bigpowers install hub: `install.sh`, `install-helpers.js`, `bin/setup.js`, and `verify-install.sh`. Wave A adapter + hook templates remain unchanged.

## In scope

- `install_hermes()` / `uninstall_hermes()` in `scripts/install.sh` — symlink rendered `.hermes/skills/<name>/` into `~/.hermes/skills/`, config-bridge `instructions:` into `~/.hermes/config.yaml`, optional gateway hook template symlinks (no auto-enable in `hooks:` block).
- `hermes` cases in `scripts/lib/install-helpers.js` (global + local + uninstall).
- Add `hermes` to `SUPPORTED_IDS` in `bin/setup.js`.
- Hermes contract assertions in `scripts/verify-install.sh`.
- `scripts/test-hermes-hub.sh` regression harness.

## Out of scope

- Live Hermes gateway UAT
- Auto-merging shell `hooks:` entries into `~/.hermes/config.yaml`

## Verify

```bash
bash scripts/test-install-hub.sh &&
bash scripts/verify-install.sh &&
bash -n scripts/install.sh &&
node --check scripts/lib/install-helpers.js &&
node --check bin/setup.js &&
echo OK
```
