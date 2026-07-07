# story: e37s08
# verify-install.sh — per-target contract matrix from targets.yaml

## Acceptance Criteria

```bash
bash scripts/verify-install.sh --matrix 2>&1 | grep -q 'PASS' &&
echo OK
```

## Out of scope
- Context generation or adapter dispatch (e37s06–s07)
- Installing or invoking any target binary
- Per-adapter smoke tests (e37s05 — test-adapters.sh)
- Codex-specific assertions (e37s04)

## Adapter guidance
- Must parse `scripts/targets.yaml` to enumerate targets and their `contracts`
- Each contract maps to an assertion function in `scripts/lib/target-contracts.sh`
- `--matrix` flag triggers contract assertions per target; output is PASS/FAIL per row
- `default_on` targets always asserted; `opt_in` only when artifacts exist; `optional` requires `--full`

