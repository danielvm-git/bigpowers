// Hidden: the refactored module must behave exactly like the original (oracle/orders.js) on
// seeded random orders, valid and invalid, in every output format.
import test from "node:test";
import assert from "node:assert";
import * as oracle from "./oracle/orders.js";
import * as current from "../src/orders.js";

const CATALOG = {
  "MUG-1": { name: "Mug", priceCents: 1200, category: "kitchen", weightGrams: 400 },
  "PAN-9": { name: "Cast Iron Pan With A Very Long Name", priceCents: 5999, category: "kitchen", weightGrams: 2600 },
  "BOOK-1": { name: "Field Guide", priceCents: 2500, category: "books", weightGrams: 700 },
  "BOOK-2": { name: "Poems", priceCents: 1500, category: "books", weightGrams: 300 },
  "BOOK-3": { name: "Atlas", priceCents: 4200, category: "books", weightGrams: 1900 },
  "EBOOK-1": { name: "Ebook", priceCents: 900, category: "digital" },
  "CARD-1": { name: "Gift Card", priceCents: 2000, category: "digital" },
  "TEA-3": { name: "Tea", priceCents: 650, weightGrams: 120 },
};
const SKUS = Object.keys(CATALOG);
const REGIONS = ["PT", "ES", "FR", "DE", "IT", "NL", "UK", "gb", "US", "pt"];
const CURRENCIES = [null, null, "EUR", "usd", "GBP"];
const DATES = [null, "2026-03-14", "2026-04-02", "2026-05-31", "2026-06-01", "2026-02-28"];
const CODES = [null, null, "SPRING10", "spring10", "FIVEOFF", "BOGO-BOOKS", "BULK"];
// Rare invalid values: each field is wrong in a few percent of orders.
const BAD = { region: "BR", currency: "JPY", date: "2026-13-01", code: "WINTER5", sku: "NOPE-1", email: "bad@" };

function rng(seed) {
  return () => {
    seed = (seed + 0x6d2b79f5) | 0;
    let t = Math.imul(seed ^ (seed >>> 15), 1 | seed);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

function makeOrder(rand) {
  const pick = (list) => list[Math.floor(rand() * list.length)];
  const or = (value, bad) => (rand() < 0.03 ? bad : value);
  const lines = [`order: ${or("A", "a")}-${1000 + Math.floor(rand() * 9000)}`];
  if (rand() < 0.98) lines.push(`customer: ${pick(["Ana Lima", "Bo", "Zé"])} <${or(pick(["ana@example.com", "Bo@Shop.PT"]), BAD.email)}>`);
  if (rand() < 0.98) lines.push(`region: ${or(pick(REGIONS), BAD.region)}`);
  const currency = or(pick(CURRENCIES), BAD.currency);
  if (currency) lines.push(`currency: ${currency}`);
  const date = or(pick(DATES), BAD.date);
  if (date) lines.push(`date: ${date}`);
  const code = or(pick(CODES), BAD.code);
  if (code) lines.push(`code: ${code}`);
  const items = 1 + Math.floor(rand() * 5);
  for (let i = 0; i < items; i++) {
    const qty = or(1 + Math.floor(rand() * (rand() < 0.2 ? 12 : 3)), 0);
    lines.push(`item: ${rand() < 0.01 ? BAD.sku : pick(SKUS)} x${qty}${rand() < 0.2 ? " @gift" : ""}`);
  }
  if (rand() < 0.3) lines.push(`note: ${pick(["ring twice", "fragile", ""])}`);
  if (rand() < 0.1) lines.push("# comment line");
  if (rand() < 0.02) lines.push(pick(["colour: red", "no colon here"]));
  return lines.sort(() => rand() - 0.5).join(rand() < 0.1 ? "\r\n" : "\n");
}

function outcome(fn) {
  try {
    return { ok: fn() };
  } catch (err) {
    return { error: err.message };
  }
}

const OPTIONS = [{}, { format: "json" }, { format: "csv" }, { width: 30 }, { width: 60 }, { format: "xml" }];

for (let batch = 0; batch < 10; batch++) {
  test(`processOrder matches the original, batch ${batch + 1}`, () => {
    const rand = rng(1300 + batch);
    for (let i = 0; i < 30; i++) {
      const text = makeOrder(rand);
      const opts = OPTIONS[i % OPTIONS.length];
      assert.deepStrictEqual(
        outcome(() => current.processOrder(text, CATALOG, opts)),
        outcome(() => oracle.processOrder(text, CATALOG, opts)),
        `order:\n${text}\nopts: ${JSON.stringify(opts)}`,
      );
    }
  });
}

test("parseOrder and priceOrder match the original step by step", () => {
  const rand = rng(77);
  for (let i = 0; i < 120; i++) {
    const text = makeOrder(rand);
    const parsed = outcome(() => oracle.parseOrder(text));
    assert.deepStrictEqual(outcome(() => current.parseOrder(text)), parsed, text);
    if (parsed.ok) {
      assert.deepStrictEqual(
        outcome(() => current.priceOrder(current.parseOrder(text), CATALOG)),
        outcome(() => oracle.priceOrder(oracle.parseOrder(text), CATALOG)),
        text,
      );
    }
  }
});

test("formatMoney matches the original", () => {
  for (const cents of [0, 5, -5, 99, 100, 101, 99999, 100000, 123456789, -123456]) {
    for (const currency of ["EUR", "USD", "GBP"]) {
      assert.strictEqual(current.formatMoney(cents, currency), oracle.formatMoney(cents, currency));
    }
  }
});

test("bad input to parseOrder fails the same way", () => {
  for (const input of [undefined, null, "", "   \n  ", 42]) {
    assert.deepStrictEqual(outcome(() => current.parseOrder(input)), outcome(() => oracle.parseOrder(input)));
  }
});
