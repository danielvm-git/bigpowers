import test from "node:test";
import assert from "node:assert";
import { parseOrder, priceOrder } from "../../src/orders.js";

const CATALOG = {
  "ITEM-NO-BRAND": { name: "No Brand Item", priceCents: 1000, category: "tools" }, // brand is undefined
  "ITEM-NULL-BRAND": { name: "Null Brand Item", priceCents: 1500, category: "tools", brand: null },
  "ACME-1": { name: "Acme Widget", priceCents: 2000, category: "tools", brand: "acme" },
};

test("audit-01: handles items with undefined or null brand gracefully without crashing", () => {
  const order = `order: AUDIT-1\ncustomer: Test <t@example.com>\nregion: PT\ndate: 2026-06-01\nitem: ITEM-NO-BRAND x1\nitem: ITEM-NULL-BRAND x1\ncode: ACME20\n`;
  // Must throw domain error 'needs items from brand: acme', NOT TypeError: Cannot read property of undefined
  assert.throws(() => priceOrder(parseOrder(order), CATALOG), {
    message: /discount code ACME20 needs items from brand: acme/,
  });
});

test("audit-02: boundary check on minBrandSubtotal exact minus 1 cent (2999 vs 3000)", () => {
  const customCatalog = {
    "ACME-EXACT": { name: "Acme Item", priceCents: 2999, category: "tools", brand: "acme" },
  };
  const order = `order: AUDIT-2\ncustomer: Test <t@example.com>\nregion: PT\ndate: 2026-06-01\nitem: ACME-EXACT x1\ncode: ACME20\n`;
  assert.throws(() => priceOrder(parseOrder(order), customCatalog), {
    message: /discount code ACME20 needs a brand subtotal of at least/,
  });
});
