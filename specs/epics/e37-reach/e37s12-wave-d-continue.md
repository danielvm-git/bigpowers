# story: e37s12
# targets.yaml — Wave D: continue (rules adapter; re-opened active OSS)

## Acceptance Criteria

grep -q 'continue' scripts/targets.yaml && bash scripts/verify-install.sh --matrix 2>&1 | grep -q 'continue' && echo OK

