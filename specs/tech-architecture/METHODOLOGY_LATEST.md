# Methodology Lenses

Project-specific reasoning modes applied by `orchestrate-project` at phase gates. Toggle per release in STATE.md.

## Active Lenses

| Lens | When to apply | Output |
|------|---------------|--------|
| **STRIDE** | Plan / Harden phases | Threat table in IMPACT.md or security section |
| **Cost-of-Delay** | Plan / change-request | WSJF notes on epics |

## STRIDE (security)

For each component: Spoofing, Tampering, Repudiation, Information disclosure, Denial of service, Elevation of privilege — one mitigation each.

## Cost-of-Delay

Score: (Business Value + Time Criticality + Risk Reduction) / Job Size. Use for epic ordering in RELEASE-PLAN.md.

## Usage

`orchestrate-project` reads this file at phase transitions. If a lens is inactive, skip its checklist.
