import test from "node:test";
import assert from "node:assert";
import { balanceOf, createChart, formatCents, Journal, monthlyReport, parseAmount, renderReport, roundToCents } from "../src/index.js";

const CHART = [
  { code: "1000", name: "Bank", type: "asset" },
  { code: "1200", name: "Receivables", type: "asset" },
  { code: "4100", name: "Usage revenue", type: "income" },
  { code: "6100", name: "Hosting", type: "expense" },
];

function journal() {
  const j = new Journal(createChart(CHART));
  j.post({ date: "2026-03-02", lines: [{ account: "1200", debit: "120.00" }, { account: "4100", credit: "120.00" }] });
  j.post({ date: "2026-03-20", lines: [{ account: "1000", debit: "100.00" }, { account: "1200", credit: "100.00" }] });
  j.post({ date: "2026-04-01", lines: [{ account: "6100", debit: "45.50" }, { account: "1000", credit: "45.50" }] });
  return j;
}

test("parses amounts to units", () => {
  assert.strictEqual(parseAmount("12.5"), 125000);
  assert.strictEqual(parseAmount("0.3333"), 3333);
  assert.throws(() => parseAmount("1.23456"), { message: "bad amount: 1.23456" });
});

test("rounds units to cents half away from zero", () => {
  assert.strictEqual(roundToCents(150), 2);
  assert.strictEqual(roundToCents(-150), -2);
  assert.strictEqual(roundToCents(149), 1);
});

test("formats cents", () => {
  assert.strictEqual(formatCents(123456), "1,234.56");
  assert.strictEqual(formatCents(-7), "-0.07");
});

test("rejects an unbalanced entry", () => {
  const j = new Journal(createChart(CHART));
  assert.throws(
    () => j.post({ date: "2026-03-01", lines: [{ account: "1200", debit: "10" }, { account: "4100", credit: "9.99" }] }),
    { message: "entry does not balance: debits 10.0000, credits 9.9900" },
  );
});

test("balances follow the normal side", () => {
  const j = journal();
  assert.strictEqual(balanceOf(j, "1200"), 2000);
  assert.strictEqual(balanceOf(j, "4100"), 12000);
  assert.strictEqual(balanceOf(j, "1000", { from: "2026-03-01", to: "2026-03-31" }), 10000);
});

test("monthly report lists active accounts in chart order", () => {
  const report = monthlyReport(journal(), "2026-03");
  assert.deepStrictEqual(report.rows.map((r) => [r.account, r.debits, r.credits, r.net]), [
    ["1000", 10000, 0, 10000],
    ["1200", 12000, 10000, 2000],
    ["4100", 0, 12000, 12000],
  ]);
  assert.deepStrictEqual(report.totals, { debits: 22000, credits: 22000 });
});

test("renders the report", () => {
  const text = renderReport(monthlyReport(journal(), "2026-04"));
  assert.match(text, /^Monthly report 2026-04\n/);
  assert.match(text, /6100 Hosting\s+45\.50\s+0\.00\s+45\.50\n/);
});
