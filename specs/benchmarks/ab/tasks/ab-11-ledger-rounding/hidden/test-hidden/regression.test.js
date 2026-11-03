// Hidden: behaviour that already works and must keep working (catches fixes in the wrong place).
import test from "node:test";
import assert from "node:assert";
import * as ledger from "../src/index.js";

const { balanceOf, createChart, formatCents, formatUnits, Journal, monthlyReport, parseAmount, renderReport, roundToCents } = ledger;

const CHART = createChart([
  { code: "1000", name: "Bank", type: "asset" },
  { code: "1200", name: "Receivables", type: "asset" },
  { code: "4100", name: "Usage revenue", type: "income" },
  { code: "6100", name: "Hosting", type: "expense" },
]);

function post(j, date, debitAccount, creditAccount, amount) {
  j.post({ date, lines: [{ account: debitAccount, debit: amount }, { account: creditAccount, credit: amount }] });
}

test("roundToCents is half away from zero", () => {
  const table = [[0, 0], [49, 0], [50, 1], [149, 1], [150, 2], [-49, 0], [-50, -1], [-150, -2], [9999, 100], [123456, 1235]];
  for (const [units, cents] of table) assert.strictEqual(roundToCents(units) + 0, cents, `units ${units}`);
});

test("balance rounds the exact total once", () => {
  const j = new Journal(CHART);
  for (let i = 0; i < 3; i++) post(j, "2026-05-02", "1200", "4100", "0.3333");
  assert.strictEqual(balanceOf(j, "1200"), 100);
  assert.strictEqual(balanceOf(j, "4100"), 100);
});

test("half-cent postings add up before rounding", () => {
  const j = new Journal(CHART);
  post(j, "2026-05-02", "6100", "1000", "0.0050");
  post(j, "2026-05-03", "6100", "1000", "0.0050");
  assert.strictEqual(balanceOf(j, "6100"), 1);
  assert.strictEqual(balanceOf(j, "1000"), -1);
});

test("balance honours the date range", () => {
  const j = new Journal(CHART);
  post(j, "2026-04-30", "1200", "4100", "10.00");
  post(j, "2026-05-01", "1200", "4100", "2.50");
  post(j, "2026-06-01", "1200", "4100", "1.00");
  assert.strictEqual(balanceOf(j, "4100", { from: "2026-05-01", to: "2026-05-31" }), 250);
  assert.strictEqual(balanceOf(j, "4100"), 1350);
});

test("formatting helpers", () => {
  assert.strictEqual(formatCents(0), "0.00");
  assert.strictEqual(formatCents(100000000), "1,000,000.00");
  assert.strictEqual(formatCents(-123456), "-1,234.56");
  assert.strictEqual(formatUnits(3333), "0.3333");
  assert.strictEqual(formatUnits(-125000), "-12.5000");
});

test("parseAmount accepts up to four decimals and rejects the rest", () => {
  assert.strictEqual(parseAmount(" 7 "), 70000);
  assert.strictEqual(parseAmount("-0.05"), -500);
  for (const bad of ["", "1.", ".5", "1,00", "abc", "1.00001"]) {
    assert.throws(() => parseAmount(bad), { message: `bad amount: ${bad}` });
  }
});

test("journal rejects malformed entries", () => {
  const j = new Journal(CHART);
  const cases = [
    [{ date: "2026-5-1", lines: [] }, "bad entry date: 2026-5-1"],
    [{ date: "2026-05-01", lines: [{ account: "1000", debit: "1" }] }, "an entry needs at least two lines"],
    [{ date: "2026-05-01", lines: [{ account: "9999", debit: "1" }, { account: "1000", credit: "1" }] }, "unknown account: 9999"],
    [{ date: "2026-05-01", lines: [{ account: "1000", debit: "1", credit: "1" }, { account: "1200", credit: "1" }] }, "line for 1000 needs a debit or a credit"],
    [{ date: "2026-05-01", lines: [{ account: "1000", debit: "0" }, { account: "1200", credit: "0" }] }, "amount for 1000 must be positive"],
  ];
  for (const [entry, message] of cases) assert.throws(() => j.post(entry), { message });
  assert.strictEqual(j.entries.length, 0);
});

test("chart validation", () => {
  assert.throws(() => createChart([{ code: "12", name: "x", type: "asset" }]), { message: "bad account code: 12" });
  assert.throws(() => createChart([{ code: "1000", name: "x", type: "cash" }]), { message: "bad account type for 1000: cash" });
  assert.throws(() => createChart([{ code: "1000", name: "a", type: "asset" }, { code: "1000", name: "b", type: "asset" }]),
    { message: "duplicate account: 1000" });
});

test("monthly report on whole cents is unchanged", () => {
  const j = new Journal(CHART);
  post(j, "2026-05-02", "1200", "4100", "120.00");
  post(j, "2026-05-20", "1000", "1200", "100.00");
  post(j, "2026-06-01", "6100", "1000", "45.50");
  const report = monthlyReport(j, "2026-05");
  assert.deepStrictEqual(report, {
    month: "2026-05",
    rows: [
      { account: "1000", name: "Bank", debits: 10000, credits: 0, net: 10000 },
      { account: "1200", name: "Receivables", debits: 12000, credits: 10000, net: 2000 },
      { account: "4100", name: "Usage revenue", debits: 0, credits: 12000, net: 12000 },
    ],
    totals: { debits: 22000, credits: 22000 },
  });
  assert.throws(() => monthlyReport(j, "2026-13"), { message: "bad month: 2026-13" });
});

test("rendered report layout is unchanged", () => {
  const j = new Journal(CHART);
  post(j, "2026-05-02", "1200", "4100", "1234.56");
  assert.strictEqual(renderReport(monthlyReport(j, "2026-05")), [
    "Monthly report 2026-05",
    "",
    "Account                             Debits       Credits           Net",
    "1200 Receivables                  1,234.56          0.00      1,234.56",
    "4100 Usage revenue                    0.00      1,234.56      1,234.56",
    "-".repeat(70),
    "Total                             1,234.56      1,234.56",
    "",
  ].join("\n"));
});

test("public API is unchanged", () => {
  assert.deepStrictEqual(Object.keys(ledger).sort(), [
    "Journal", "balanceOf", "createChart", "formatCents", "formatUnits", "monthlyReport", "normalSign", "parseAmount",
    "renderReport", "roundToCents",
  ]);
});
