# specs/metrics - Cycle Time Ledger

Stores per-story delivery metrics written by release-branch after each story lands.

## cycle-times.yaml schema

```yaml
stories:
  - id: e01s01
    bcps: 3
    start: "2026-06-10T09:45:00Z"
    end: "2026-06-10T11:15:00Z"
    cycle_minutes: 90
    bcp_per_hour: 2.0
```

Fields: `id`, `bcps`, `start` (ISO 8601), `end` (ISO 8601), `cycle_minutes`, `bcp_per_hour`
