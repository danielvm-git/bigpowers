import test from "node:test";
import assert from "node:assert";
import { parseOrder, priceOrder } from "../src/orders.js";

const CATALOG = {
  "ACME-ANVIL": { name: "Acme Anvil", priceCents: 4000, category: "tools", brand: "acme", weightGrams: 5000 },
  "ACME-HAMMER": { name: "Acme Hammer", priceCents: 1500, category: "tools", brand: "acme", weightGrams: 800 },
  "ZEN-RADIO": { name: "Zenith Radio", priceCents: 2000, category: "electronics", brand: "zenith", weightGrams: 600 },
  "GEN-BOOK": { name: "Notebook", priceCents: 1000, category: "stationery", weightGrams: 200 },
};

const ORDER_ACME = `order: B-2001
customer: Carlos Silva <carlos@example.com>
region: PT
date: 2026-06-15
item: ACME-ANVIL x1
item: ZEN-RADIO x1
`;

test("brand discount applies only to items of the matching brand", () => {
  const parsed = parseOrder(ORDER_ACME + "code: ACME20\n");
  const priced = priceOrder(parsed, CATALOG);

  // Anvil = 4000 cents -> 20% = 800 cents discount
  // Zenith radio = 2000 cents -> 0 discount
  assert.strictEqual(priced.discountCents, 800);
  assert.strictEqual(priced.discountLabel, "ACME20");

  const anvilLine = priced.lines.find((l) => l.sku === "ACME-ANVIL");
  const radioLine = priced.lines.find((l) => l.sku === "ZEN-RADIO");
  assert.strictEqual(anvilLine.discountCents, 800);
  assert.strictEqual(radioLine.discountCents, 0);
});

test("throws if brand subtotal is below minBrandSubtotal", () => {
  const shortOrder = `order: B-2002
customer: Carlos Silva <carlos@example.com>
region: PT
date: 2026-06-15
item: ACME-HAMMER x1
code: ACME20
`;
  // Hammer is 1500 cents, ACME20 requires 3000
  assert.throws(() => priceOrder(parseOrder(shortOrder), CATALOG), {
    message: /discount code ACME20 needs a brand subtotal of at least/,
  });
});

test("throws if order has no items of the target brand", () => {
  const noBrandOrder = `order: B-2003
customer: Carlos Silva <carlos@example.com>
region: PT
date: 2026-06-15
item: ZEN-RADIO x1
code: ACME20
`;
  assert.throws(() => priceOrder(parseOrder(noBrandOrder), CATALOG), {
    message: "discount code ACME20 needs items from brand: acme",
  });
});

test("brand discount without minimum threshold applies to any quantity", () => {
  const zenOrder = `order: B-2004
customer: Carlos Silva <carlos@example.com>
region: PT
date: 2026-06-15
item: ZEN-RADIO x1
code: ZENITH15
`;
  // Zenith radio = 2000 cents -> 15% = 300 cents discount
  const priced = priceOrder(parseOrder(zenOrder), CATALOG);
  assert.strictEqual(priced.discountCents, 300);
  assert.strictEqual(priced.lines[0].discountCents, 300);
});

test("brand discount allocates across multiple lines of the same brand", () => {
  const multiOrder = `order: B-2005
customer: Carlos Silva <carlos@example.com>
region: PT
date: 2026-06-15
item: ACME-ANVIL x1
item: ACME-HAMMER x2
code: ACME20
`;
  // Anvil = 4000, Hammers = 1500 x 2 = 3000. Total Acme = 7000 cents.
  // 20% of 7000 = 1400 cents discount.
  const priced = priceOrder(parseOrder(multiOrder), CATALOG);
  assert.strictEqual(priced.discountCents, 1400);

  const anvilLine = priced.lines.find((l) => l.sku === "ACME-ANVIL");
  const hammerLine = priced.lines.find((l) => l.sku === "ACME-HAMMER");
  assert.strictEqual(anvilLine.discountCents + hammerLine.discountCents, 1400);
  assert.strictEqual(anvilLine.discountCents, 800);
  assert.strictEqual(hammerLine.discountCents, 600);
});

test("tax is calculated on discounted amount, not full amount", () => {
  const priced = priceOrder(parseOrder(ORDER_ACME + "code: ACME20\n"), CATALOG);
  // Anvil net: 4000 - 800 = 3200 cents. PT standard tax = 23% -> 736 cents.
  // Radio net: 2000 - 0 = 2000 cents. PT standard tax = 23% -> 460 cents.
  const anvilLine = priced.lines.find((l) => l.sku === "ACME-ANVIL");
  const radioLine = priced.lines.find((l) => l.sku === "ZEN-RADIO");
  assert.strictEqual(anvilLine.taxCents, 736);
  assert.strictEqual(radioLine.taxCents, 460);
});

test("regression: existing standard discounts still work", () => {
  const basic = `order: B-2006
customer: Carlos Silva <carlos@example.com>
region: PT
date: 2026-04-10
item: ACME-ANVIL x1
code: SPRING10
`;
  const priced = priceOrder(parseOrder(basic), CATALOG);
  assert.strictEqual(priced.discountCents, 400);
});
