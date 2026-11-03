# Monthly report doesn't match the balances (off by a cent or two)

**Reported by:** Marta (finance)

Since we moved usage billing to per-unit prices, the monthly report and the account balances
don't agree any more. It's usually a cent, sometimes two or three. Example from March:

| | Monthly report (net) | Balance for March |
|---|---|---|
| 1200 Receivables | 158.35 | 158.33 |
| 4100 Usage revenue | 128.34 | 128.33 |

Also the report's total debits and total credits are sometimes different, which should be
impossible in double-entry. March shows debits 248.25 and credits 248.24.

To reproduce: post the March usage charges from `examples/march.js` and compare
`monthlyReport(journal, "2026-03")` with `balanceOf(journal, code, { from: "2026-03-01", to: "2026-03-31" })`.

The balances are what we reconcile against the bank, so those are right.
