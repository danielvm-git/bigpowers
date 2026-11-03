import { normalSign } from "./accounts.js";
import { roundToCents } from "./currency.js";

// Balance in cents on the account's normal side (income shows positive when credited).
export function balanceOf(journal, code, range = {}) {
  const account = journal.chart.get(code);
  if (!account) throw new Error(`unknown account: ${code}`);
  const units = journal.postingsFor(code, range).reduce((sum, p) => sum + p.units, 0);
  return roundToCents(units * normalSign(account));
}
