// Hidden: the bug in ISSUE.md. Report figures must equal account balances and totals must balance.
import test from "node:test";
import assert from "node:assert";
import { balanceOf, createChart, Journal, monthlyReport, roundToCents } from "../src/index.js";

const CHART = createChart([
  { code: "1000", name: "Bank", type: "asset" },
  { code: "1200", name: "Receivables", type: "asset" },
  { code: "4100", name: "Usage revenue", type: "income" },
  { code: "4200", name: "Subscriptions", type: "income" },
  { code: "6100", name: "Hosting", type: "expense" },
]);
const units = (n) => (n / 10000).toFixed(4);

function march() {
  const j = new Journal(CHART);
  for (const [qty, date] of [[20, "03"], [69, "07"], [59, "11"], [41, "15"], [38, "19"], [44, "24"], [24, "28"]]) {
    const amount = units(qty * 3333);
    j.post({ date: `2026-03-${date}`, lines: [{ account: "1200", debit: amount }, { account: "4100", credit: amount }] });
  }
  j.post({ date: "2026-03-30", lines: [
    { account: "1200", debit: "60.0050" }, { account: "4100", credit: "30.0025" }, { account: "4200", credit: "30.0025" }] });
  j.post({ date: "2026-03-31", lines: [{ account: "6100", debit: "89.90" }, { account: "1000", credit: "89.90" }] });
  return j;
}

function rng(seed) {
  return () => ((seed = (seed * 1103515245 + 12345) % 2147483648) / 2147483648);
}

// Seeded month of fractional usage charges, split bundles and payments.
function generated(seed, month) {
  const rand = rng(seed);
  const j = new Journal(CHART);
  for (let i = 0; i < 40; i++) {
    const day = String(1 + Math.floor(rand() * 28)).padStart(2, "0");
    const a = 1 + Math.floor(rand() * 900000);
    const b = 1 + Math.floor(rand() * 400000);
    const date = `${month}-${day}`;
    if (rand() < 0.6) j.post({ date, lines: [{ account: "1200", debit: units(a) }, { account: "4100", credit: units(a) }] });
    else j.post({ date, lines: [{ account: "1200", debit: units(a + b) }, { account: "4100", credit: units(a) }, { account: "4200", credit: units(b) }] });
    if (rand() < 0.3) j.post({ date, lines: [{ account: "1000", debit: units(b) }, { account: "1200", credit: units(b) }] });
  }
  return j;
}

function assertReportMatchesBalances(journal, month) {
  const report = monthlyReport(journal, month);
  const range = { from: `${month}-01`, to: `${month}-31` };
  for (const row of report.rows) {
    assert.strictEqual(row.net, balanceOf(journal, row.account, range), `net of ${row.account} in ${month}`);
  }
  assert.strictEqual(report.totals.debits, report.totals.credits, `totals in ${month}`);
}

test("ISSUE.md March example: report net equals the balance", () => {
  const report = monthlyReport(march(), "2026-03");
  const net = Object.fromEntries(report.rows.map((r) => [r.account, r.net]));
  assert.deepStrictEqual(net, { 1000: -8990, 1200: 15833, 4100: 12833, 4200: 3000, 6100: 8990 });
});

test("ISSUE.md March example: total debits equal total credits", () => {
  const { totals } = monthlyReport(march(), "2026-03");
  assert.deepStrictEqual(totals, { debits: 24823, credits: 24823 });
});

test("debit and credit columns are rounded from the exact sums", () => {
  const j = march();
  const row = monthlyReport(j, "2026-03").rows.find((r) => r.account === "1200");
  const debitUnits = j.postingsFor("1200").filter((p) => p.units > 0).reduce((s, p) => s + p.units, 0);
  assert.strictEqual(row.debits, roundToCents(debitUnits));
});

for (const [seed, month] of [[1, "2026-01"], [2, "2026-02"], [3, "2026-04"], [4, "2026-11"]]) {
  test(`generated month ${month}: report reconciles with balances`, () => {
    assertReportMatchesBalances(generated(seed, month), month);
  });
}
