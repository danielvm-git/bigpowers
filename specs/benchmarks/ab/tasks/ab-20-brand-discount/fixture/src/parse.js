import { RATES, TAX_RATES } from "./rules.js";

const FIELDS = ["order", "customer", "region", "currency", "date", "code", "item", "note"];

export function parseOrder(text) {
  if (typeof text !== "string" || !text.trim()) throw new Error("empty order");
  const order = { id: null, customer: null, region: null, currency: "EUR", date: null, code: null, items: [], notes: [] };
  const lines = text.split(/\r?\n/);
  for (let i = 0; i < lines.length; i++) {
    const raw = lines[i].trim();
    if (!raw || raw.startsWith("#")) continue;
    const colon = raw.indexOf(":");
    if (colon === -1) throw new Error(`line ${i + 1}: expected 'field: value'`);
    const field = raw.slice(0, colon).trim().toLowerCase();
    if (!FIELDS.includes(field)) throw new Error(`line ${i + 1}: unknown field '${field}'`);
    FIELD_PARSERS[field](order, raw.slice(colon + 1).trim(), `line ${i + 1}`);
  }
  for (const [key, field] of [["id", "order"], ["customer", "customer"], ["region", "region"]]) {
    if (!order[key]) throw new Error(`missing field: ${field}`);
  }
  if (!order.items.length) throw new Error("missing field: item");
  return order;
}

const FIELD_PARSERS = {
  order(order, value, where) {
    if (!/^[A-Z]-\d{4}$/.test(value)) throw new Error(`${where}: bad order id '${value}'`);
    order.id = value;
  },
  customer(order, value, where) {
    const m = value.match(/^(.+?)\s*<([^<>\s]+)>$/);
    if (!m) throw new Error(`${where}: customer must be 'Name <email>'`);
    const email = m[2];
    const at = email.indexOf("@");
    if (at < 1 || email.indexOf("@", at + 1) !== -1 || !email.slice(at + 1).includes(".")) {
      throw new Error(`${where}: bad email '${email}'`);
    }
    order.customer = { name: m[1].trim(), email: email.toLowerCase() };
  },
  region(order, value, where) {
    const region = value.toUpperCase() === "GB" ? "UK" : value.toUpperCase();
    if (!TAX_RATES[region]) throw new Error(`${where}: unsupported region '${value}'`);
    order.region = region;
  },
  currency(order, value, where) {
    const currency = value.toUpperCase();
    if (!RATES[currency]) throw new Error(`${where}: unsupported currency '${value}'`);
    order.currency = currency;
  },
  date(order, value, where) {
    if (!/^\d{4}-\d{2}-\d{2}$/.test(value) || isNaN(Date.parse(value + "T00:00:00Z"))) {
      throw new Error(`${where}: bad date '${value}'`);
    }
    order.date = value;
  },
  code(order, value) {
    order.code = value.toUpperCase();
  },
  item(order, value, where) {
    const m = value.match(/^(\S+)\s+x(\d+)(\s+@gift)?$/i);
    if (!m) throw new Error(`${where}: item must be 'SKU xN [@gift]'`);
    const qty = Number(m[2]);
    if (qty < 1 || qty > 99) throw new Error(`${where}: quantity must be 1-99`);
    const sku = m[1].toUpperCase();
    const gift = Boolean(m[3]);
    const existing = order.items.find((it) => it.sku === sku && it.gift === gift);
    if (existing) existing.qty += qty;
    else order.items.push({ sku, qty, gift });
  },
  note(order, value) {
    order.notes.push(value);
  },
};
