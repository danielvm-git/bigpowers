# Ledger

Small double-entry ledger used by the billing service.

- `currency.js` — amounts as integer units (1/10000), rounding to cents, formatting
- `accounts.js` — chart of accounts and each account's normal side
- `journal.js` — posting balanced entries
- `balances.js` — account balances
- `reports.js` — the monthly report sent to finance

Every entry must balance exactly in units. Usage charges are priced per unit to four decimals
(for example 0.3333), so most postings are not whole cents.

Finance reconciles the monthly report against account balances at month end.
