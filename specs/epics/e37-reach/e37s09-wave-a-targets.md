# story: e37s09
# targets.yaml — Wave A: Goose (OSS) + Antigravity agy (proprietary beta)

## Acceptance Criteria

grep -q 'goose' scripts/targets.yaml && bash scripts/verify-install.sh --matrix 2>&1 | grep -q 'goose.*PASS' && echo OK

