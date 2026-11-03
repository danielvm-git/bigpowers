// March usage charges, as posted by the billing job. Run: node examples/march.js
import { balanceOf, createChart, Journal, monthlyReport } from "../src/index.js";

export const CHART = [
  { code: "1000", name: "Bank", type: "asset" },
  { code: "1200", name: "Receivables", type: "asset" },
  { code: "4100", name: "Usage revenue", type: "income" },
  { code: "4200", name: "Subscriptions", type: "income" },
  { code: "6100", name: "Hosting", type: "expense" },
];

// Seven customers, units used x 0.3333 per unit.
export const USAGE = [[20, "2026-03-03"], [69, "2026-03-07"], [59, "2026-03-11"], [41, "2026-03-15"],
  [38, "2026-03-19"], [44, "2026-03-24"], [24, "2026-03-28"]];

export function marchJournal() {
  const journal = new Journal(createChart(CHART));
  for (const [units, date] of USAGE) {
    const amount = (units * 3333) / 10000;
    const text = amount.toFixed(4);
    journal.post({ date, memo: `usage ${units}`, lines: [{ account: "1200", debit: text }, { account: "4100", credit: text }] });
  }
  journal.post({ date: "2026-03-30", memo: "bundle: usage + plan", lines: [
    { account: "1200", debit: "60.0050" }, { account: "4100", credit: "30.0025" }, { account: "4200", credit: "30.0025" }] });
  journal.post({ date: "2026-03-31", memo: "hosting", lines: [{ account: "6100", debit: "89.90" }, { account: "1000", credit: "89.90" }] });
  return journal;
}

if (import.meta.url === `file://${process.argv[1]}`) {
  const journal = marchJournal();
  const report = monthlyReport(journal, "2026-03");
  for (const row of report.rows) {
    const balance = balanceOf(journal, row.account, { from: "2026-03-01", to: "2026-03-31" });
    console.log(row.account, "report", row.net, "balance", balance);
  }
  console.log("totals", report.totals);
}
