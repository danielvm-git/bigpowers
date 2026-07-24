# e69s02: Install hub wiring (Wave B)

Wire MiMo Code into the bigpowers install hub: `install.sh`, `install-helpers.js`, `bin/setup.js`, `targets.yaml`, and `verify-install.sh`. Wave A adapter remains unchanged.

## In scope

- `install_mimo()` / `uninstall_mimo()` in `scripts/install.sh` — symlink rendered `.mimocode/skills/<name>/` into `~/.mimocode/skills/`, symlink `AGENTS.md` into `~/.mimocode/AGENTS.md`.
- `mimo` cases in `scripts/lib/install-helpers.js` (global + local + uninstall).
- Add `mimo` to `SUPPORTED_IDS` in `bin/setup.js`.
- `mimo` row in `scripts/targets.yaml`.
- MiMo contract assertions in `scripts/verify-install.sh`.
- `scripts/test-mimo-hub.sh` regression harness.

## Out of scope

- Live MiMo Code UAT
- MiMo plugins (`.mimocode/plugins/` — future story)
- Hooks (MiMo has none per epic research)

## Verify

```bash
bash scripts/test-mimo-hub.sh &&
bash scripts/verify-install.sh &&
bash -n scripts/install.sh &&
node --check scripts/lib/install-helpers.js &&
node --check bin/setup.js &&
echo OK
```
