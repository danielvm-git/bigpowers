# e76s02: Install hub wiring (Wave B)

Wire ZCode into the bigpowers install hub: `install.sh`, `install-helpers.js`, `bin/setup.js`, `targets.yaml`, and `verify-install.sh`. Wave A adapter remains unchanged except repo-relative default paths for sync.

## In scope

- `install_zcode()` / `uninstall_zcode()` in `scripts/install.sh` — symlink rendered `.zcode/skills/<name>/` into `~/.zcode/skills/`, symlink `AGENTS.md` into `~/.zcode/AGENTS.md`.
- `zcode` cases in `scripts/lib/install-helpers.js` (global + local + uninstall).
- Add `zcode` to `SUPPORTED_IDS` in `bin/setup.js`.
- `zcode` row in `scripts/targets.yaml`.
- ZCode contract assertions in `scripts/verify-install.sh`.
- `scripts/test-zcode-hub.sh` regression harness.

## Out of scope

- Live ZCode UAT
- ZCode plugin hooks

## Verify

```bash
bash scripts/test-zcode-hub.sh &&
bash scripts/verify-install.sh &&
bash -n scripts/install.sh &&
node --check scripts/lib/install-helpers.js &&
node --check bin/setup.js &&
echo OK
```
