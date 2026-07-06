# story: e37s08
# verify-install.sh — per-target contract matrix from targets.yaml

## Acceptance Criteria

bash scripts/verify-install.sh --matrix 2>&1 | grep -q 'PASS' && echo OK

