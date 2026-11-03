import test from "node:test";
import assert from "node:assert";
import { parseOrder, priceOrder, formatInvoice, formatMoney, processOrder } from "../src/orders.js";

const CATALOG = {
  "MUG-1": { name: "Mug", priceCents: 1200, category: "kitchen", weightGrams: 400 },
  "BOOK-1": { name: "Field Guide", priceCents: 2500, category: "books", weightGrams: 700 },
  "BOOK-2": { name: "Poems", priceCents: 1500, category: "books", weightGrams: 300 },
  "EBOOK-1": { name: "Ebook", priceCents: 900, category: "digital" },
};

const BASIC = `order: A-1001
customer: Ana Lima <Ana@Example.com>
region: PT
date: 2026-03-14
item: MUG-1 x2
item: BOOK-1 x1
note: leave at door
`;

test("parses fields and lowercases the email", () => {
  const order = parseOrder(BASIC);
  assert.strictEqual(order.id, "A-1001");
  assert.deepStrictEqual(order.customer, { name: "Ana Lima", email: "ana@example.com" });
  assert.deepStrictEqual(order.items, [{ sku: "MUG-1", qty: 2, gift: false }, { sku: "BOOK-1", qty: 1, gift: false }]);
  assert.deepStrictEqual(order.notes, ["leave at door"]);
});

test("rejects unknown fields with the line number", () => {
  assert.throws(() => parseOrder("order: A-1001\ncolour: red\n"), { message: "line 2: unknown field 'colour'" });
});

test("reports the first missing field", () => {
  assert.throws(() => parseOrder("order: A-1001\nregion: PT\n"), { message: "missing field: customer" });
});

test("prices a plain order with book and standard tax", () => {
  const priced = priceOrder(parseOrder(BASIC), CATALOG);
  assert.strictEqual(priced.subtotalCents, 4900);
  assert.strictEqual(priced.shippingCents, 549);
  assert.strictEqual(priced.taxCents, 552 + 150 + 126);
  assert.strictEqual(priced.totalCents, 4900 + 549 + 828);
});

test("percent code allocates the discount over lines", () => {
  const priced = priceOrder(parseOrder(BASIC + "code: spring10\n"), CATALOG);
  assert.strictEqual(priced.discountCents, 490);
  assert.deepStrictEqual(priced.lines.map((l) => l.discountCents), [240, 250]);
});

test("expired code is an error", () => {
  const text = BASIC.replace("2026-03-14", "2026-07-01") + "code: SPRING10\n";
  assert.throws(() => priceOrder(parseOrder(text), CATALOG), { message: "discount code expired: SPRING10" });
});

test("bogo makes the cheapest book free", () => {
  const text = BASIC + "item: BOOK-2 x1\ncode: BOGO-BOOKS\n";
  assert.strictEqual(priceOrder(parseOrder(text), CATALOG).discountCents, 1500);
});

test("digital-only orders ship for free", () => {
  const text = "order: A-1002\ncustomer: Bo <bo@example.com>\nregion: DE\nitem: EBOOK-1 x1\n";
  assert.strictEqual(priceOrder(parseOrder(text), CATALOG).shippingCents, 0);
});

test("converts to the order currency", () => {
  const priced = priceOrder(parseOrder(BASIC + "currency: usd\n"), CATALOG);
  assert.strictEqual(priced.currency, "USD");
  assert.strictEqual(priced.subtotalCents, 5292);
});

test("formats money with separators and sign", () => {
  assert.strictEqual(formatMoney(123456, "EUR"), "€1,234.56");
  assert.strictEqual(formatMoney(-5, "GBP"), "-£0.05");
});

test("renders a text invoice", () => {
  const invoice = processOrder(BASIC, CATALOG);
  assert.match(invoice, /^INVOICE A-1001\n/);
  assert.match(invoice, /TOTAL\s+€62\.77\n/);
  assert.match(invoice, /Note: leave at door\n$/);
});

test("renders json and csv", () => {
  const order = parseOrder(BASIC);
  const priced = priceOrder(order, CATALOG);
  assert.strictEqual(JSON.parse(formatInvoice(order, priced, { format: "json" })).totalCents, 6277);
  assert.match(formatInvoice(order, priced, { format: "csv" }), /^sku,qty,gift,amount,discount,tax\nMUG-1,2,no,2400,0,552\n/);
});
