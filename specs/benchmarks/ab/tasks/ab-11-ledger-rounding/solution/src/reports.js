import { normalSign } from "./accounts.js";
import { formatCents, roundToCents } from "./currency.js";

const MONTH = /^(\d{4})-(0[1-9]|1[0-2])$/;

// Sums stay in exact units; each reported figure is rounded once, the same way balanceOf rounds,
// so the report reconciles with balances and total debits always equal total credits.
export function monthlyReport(journal, month) {
  if (!MONTH.test(month || "")) throw new Error(`bad month: ${month}`);
  const range = { from: `${month}-01`, to: `${month}-31` };
  const rows = [];
  let allDebits = 0;
  let allCredits = 0;
  for (const account of journal.chart.values()) {
    let debits = 0;
    let credits = 0;
    for (const p of journal.postingsFor(account.code, range)) {
      if (p.units > 0) debits += p.units;
      else credits -= p.units;
    }
    if (!debits && !credits) continue;
    allDebits += debits;
    allCredits += credits;
    rows.push({
      account: account.code, name: account.name,
      debits: roundToCents(debits), credits: roundToCents(credits),
      net: roundToCents((debits - credits) * normalSign(account)),
    });
  }
  return { month, rows, totals: { debits: roundToCents(allDebits), credits: roundToCents(allCredits) } };
}

export function renderReport(report) {
  const out = [`Monthly report ${report.month}`, ""];
  out.push(`${"Account".padEnd(28)}${"Debits".padStart(14)}${"Credits".padStart(14)}${"Net".padStart(14)}`);
  for (const r of report.rows) {
    const label = `${r.account} ${r.name}`.slice(0, 27).padEnd(28);
    out.push(`${label}${formatCents(r.debits).padStart(14)}${formatCents(r.credits).padStart(14)}${formatCents(r.net).padStart(14)}`);
  }
  out.push("-".repeat(70));
  out.push(`${"Total".padEnd(28)}${formatCents(report.totals.debits).padStart(14)}${formatCents(report.totals.credits).padStart(14)}`);
  return out.join("\n") + "\n";
}
