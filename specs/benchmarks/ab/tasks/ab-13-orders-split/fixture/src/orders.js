// Orders: parse order text, price it (discounts, shipping, tax, currency) and render invoices.
// Started as a quick script; everything still lives in this one file.

const FIELDS = ["order", "customer", "region", "currency", "date", "code", "item", "note"];

const RATES = { EUR: 1, USD: 1.08, GBP: 0.86 };
const SYMBOLS = { EUR: "€", USD: "$", GBP: "£" };

const TAX_RATES = {
  PT: { standard: 0.23, books: 0.06 },
  ES: { standard: 0.21, books: 0.04 },
  FR: { standard: 0.2, books: 0.055 },
  DE: { standard: 0.19, books: 0.07 },
  IT: { standard: 0.22, books: 0.04 },
  NL: { standard: 0.21, books: 0.09 },
  UK: { standard: 0.2, books: 0 },
  US: { standard: 0, books: 0 },
};

const SHIPPING = {
  PT: { base: 399, perKg: 150, zone: "domestic" },
  ES: { base: 399, perKg: 150, zone: "domestic" },
  FR: { base: 699, perKg: 200, zone: "eu" },
  DE: { base: 699, perKg: 200, zone: "eu" },
  IT: { base: 699, perKg: 200, zone: "eu" },
  NL: { base: 699, perKg: 200, zone: "eu" },
  UK: { base: 999, perKg: 300, zone: "uk" },
  US: { base: 1499, perKg: 400, zone: "us" },
};

const DISCOUNT_CODES = {
  SPRING10: { type: "percent", value: 10, minSubtotal: 2000, from: "2026-03-01", to: "2026-05-31" },
  FIVEOFF: { type: "fixed", value: 500 },
  "BOGO-BOOKS": { type: "bogo", category: "books" },
  BULK: { type: "tiered", tiers: [[10, 15], [5, 7]] },
};

const GIFT_WRAP_CENTS = 250;
const FREE_SHIPPING_THRESHOLD = 5000;

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
    const value = raw.slice(colon + 1).trim();
    if (!FIELDS.includes(field)) throw new Error(`line ${i + 1}: unknown field '${field}'`);
    if (field === "order") {
      if (!/^[A-Z]-\d{4}$/.test(value)) throw new Error(`line ${i + 1}: bad order id '${value}'`);
      order.id = value;
    } else if (field === "customer") {
      const m = value.match(/^(.+?)\s*<([^<>\s]+)>$/);
      if (!m) throw new Error(`line ${i + 1}: customer must be 'Name <email>'`);
      const email = m[2];
      const at = email.indexOf("@");
      if (at < 1 || email.indexOf("@", at + 1) !== -1 || !email.slice(at + 1).includes(".")) {
        throw new Error(`line ${i + 1}: bad email '${email}'`);
      }
      order.customer = { name: m[1].trim(), email: email.toLowerCase() };
    } else if (field === "region") {
      const region = value.toUpperCase() === "GB" ? "UK" : value.toUpperCase();
      if (!TAX_RATES[region]) throw new Error(`line ${i + 1}: unsupported region '${value}'`);
      order.region = region;
    } else if (field === "currency") {
      const currency = value.toUpperCase();
      if (!RATES[currency]) throw new Error(`line ${i + 1}: unsupported currency '${value}'`);
      order.currency = currency;
    } else if (field === "date") {
      if (!/^\d{4}-\d{2}-\d{2}$/.test(value) || isNaN(Date.parse(value + "T00:00:00Z"))) {
        throw new Error(`line ${i + 1}: bad date '${value}'`);
      }
      order.date = value;
    } else if (field === "code") {
      order.code = value.toUpperCase();
    } else if (field === "item") {
      const m = value.match(/^(\S+)\s+x(\d+)(\s+@gift)?$/i);
      if (!m) throw new Error(`line ${i + 1}: item must be 'SKU xN [@gift]'`);
      const qty = Number(m[2]);
      if (qty < 1 || qty > 99) throw new Error(`line ${i + 1}: quantity must be 1-99`);
      const sku = m[1].toUpperCase();
      const gift = Boolean(m[3]);
      const existing = order.items.find((it) => it.sku === sku && it.gift === gift);
      if (existing) existing.qty += qty;
      else order.items.push({ sku, qty, gift });
    } else {
      order.notes.push(value);
    }
  }
  if (!order.id) throw new Error("missing field: order");
  if (!order.customer) throw new Error("missing field: customer");
  if (!order.region) throw new Error("missing field: region");
  if (!order.items.length) throw new Error("missing field: item");
  return order;
}

export function priceOrder(order, catalog) {
  const lines = order.items.map((item) => {
    const product = catalog[item.sku];
    if (!product) throw new Error(`unknown sku: ${item.sku}`);
    const category = product.category || "general";
    return {
      sku: item.sku, name: product.name, category, qty: item.qty, gift: item.gift,
      unitCents: product.priceCents, amountCents: product.priceCents * item.qty, discountCents: 0, taxCents: 0,
      weightGrams: category === "digital" ? 0 : (product.weightGrams || 0) * item.qty,
    };
  });
  const subtotal = lines.reduce((sum, l) => sum + l.amountCents, 0);

  let discount = 0;
  let rule = null;
  if (order.code) {
    rule = DISCOUNT_CODES[order.code];
    if (!rule) throw new Error(`unknown discount code: ${order.code}`);
    if (rule.from && !order.date) throw new Error(`discount code needs an order date: ${order.code}`);
    if (rule.from && (order.date < rule.from || order.date > rule.to)) {
      throw new Error(`discount code expired: ${order.code}`);
    }
    if (rule.type === "percent") {
      if (subtotal < rule.minSubtotal) {
        throw new Error(`discount code ${order.code} needs a subtotal of at least ${formatMoney(rule.minSubtotal, "EUR")}`);
      }
      discount = Math.round((subtotal * rule.value) / 100);
    } else if (rule.type === "fixed") {
      discount = Math.min(rule.value, subtotal);
    } else if (rule.type === "bogo") {
      const units = [];
      for (const l of lines) {
        if (l.category !== rule.category) continue;
        for (let k = 0; k < l.qty; k++) units.push({ line: l, cents: l.unitCents });
      }
      units.sort((a, b) => a.cents - b.cents);
      for (let k = 0; k < Math.floor(units.length / 2); k++) {
        units[k].line.discountCents += units[k].cents;
        discount += units[k].cents;
      }
    } else {
      const qty = lines.reduce((sum, l) => sum + l.qty, 0);
      const tier = rule.tiers.find(([min]) => qty >= min);
      discount = tier ? Math.round((subtotal * tier[1]) / 100) : 0;
    }
  }
  if (discount > 0 && rule.type !== "bogo") {
    let allocated = 0;
    for (const l of lines) {
      l.discountCents = Math.floor((discount * l.amountCents) / subtotal);
      allocated += l.discountCents;
    }
    const byAmount = [...lines].sort((a, b) => b.amountCents - a.amountCents);
    for (let k = 0, rest = discount - allocated; rest > 0; k = (k + 1) % byAmount.length, rest--) {
      byAmount[k].discountCents++;
    }
  }

  const weight = lines.reduce((sum, l) => sum + l.weightGrams, 0);
  const allDigital = lines.every((l) => l.category === "digital");
  const zone = SHIPPING[order.region];
  let shipping = 0;
  if (!allDigital) {
    shipping = zone.base + Math.max(0, Math.ceil((weight - 1000) / 1000)) * zone.perKg;
    if (zone.zone === "domestic" && subtotal - discount >= FREE_SHIPPING_THRESHOLD) shipping = 0;
  }
  const giftWrap = lines.filter((l) => l.gift).length * GIFT_WRAP_CENTS;

  const rates = TAX_RATES[order.region];
  let tax = 0;
  for (const l of lines) {
    l.taxCents = Math.round((l.amountCents - l.discountCents) * (l.category === "books" ? rates.books : rates.standard));
    tax += l.taxCents;
  }
  tax += Math.round((shipping + giftWrap) * rates.standard);

  const conv = (cents) => Math.round(cents * RATES[order.currency]);
  const priced = {
    currency: order.currency,
    lines: lines.map((l) => ({
      sku: l.sku, name: l.name, qty: l.qty, gift: l.gift,
      amountCents: conv(l.amountCents), discountCents: conv(l.discountCents), taxCents: conv(l.taxCents),
    })),
    weightGrams: weight, allDigital,
    subtotalCents: conv(subtotal), discountCents: conv(discount), discountLabel: discount > 0 ? order.code : null,
    giftWrapCents: conv(giftWrap), shippingCents: conv(shipping), taxCents: conv(tax),
  };
  priced.totalCents = priced.subtotalCents - priced.discountCents + priced.giftWrapCents + priced.shippingCents + priced.taxCents;
  return priced;
}

export function formatMoney(cents, currency) {
  const sign = cents < 0 ? "-" : "";
  const abs = Math.abs(cents);
  const whole = String(Math.floor(abs / 100)).replace(/\B(?=(\d{3})+(?!\d))/g, ",");
  return `${sign}${SYMBOLS[currency]}${whole}.${String(abs % 100).padStart(2, "0")}`;
}

export function formatInvoice(order, priced, opts = {}) {
  const format = opts.format || "text";
  if (format === "json") {
    return JSON.stringify({ order: order.id, date: order.date, customer: order.customer, region: order.region, ...priced }, null, 2);
  }
  if (format === "csv") {
    const rows = ["sku,qty,gift,amount,discount,tax"];
    for (const l of priced.lines) {
      rows.push([l.sku, l.qty, l.gift ? "yes" : "no", l.amountCents, l.discountCents, l.taxCents].join(","));
    }
    rows.push(`subtotal,,,${priced.subtotalCents},${priced.discountCents},`);
    rows.push(`extras,,,${priced.giftWrapCents + priced.shippingCents},,`);
    rows.push(`total,,,${priced.totalCents},,${priced.taxCents}`);
    return rows.join("\n") + "\n";
  }
  if (format !== "text") throw new Error(`unknown format: ${format}`);
  const width = opts.width || 44;
  const row = (label, cents) => {
    const amount = formatMoney(cents, priced.currency);
    return label.padEnd(Math.max(label.length + 1, width - amount.length)) + amount;
  };
  const out = [`INVOICE ${order.id}`];
  if (order.date) out.push(`Date: ${order.date}`);
  out.push(`Bill to: ${order.customer.name} <${order.customer.email}>`);
  out.push(`Region: ${order.region}  Currency: ${priced.currency}`, "");
  for (const l of priced.lines) {
    let label = `  ${l.qty} x ${l.name} (${l.sku})${l.gift ? " [gift]" : ""}`;
    if (label.length > width - 12) label = label.slice(0, width - 15) + "...";
    out.push(row(label, l.amountCents));
  }
  out.push("-".repeat(width), row("Subtotal", priced.subtotalCents));
  if (priced.discountCents) out.push(row(`Discount (${priced.discountLabel})`, -priced.discountCents));
  if (priced.giftWrapCents) out.push(row("Gift wrap", priced.giftWrapCents));
  let shippingLabel = "Shipping";
  if (priced.shippingCents === 0) shippingLabel = priced.allDigital ? "Shipping (digital)" : "Shipping (free)";
  out.push(row(shippingLabel, priced.shippingCents), row("Tax", priced.taxCents));
  out.push("=".repeat(width), row("TOTAL", priced.totalCents));
  for (const note of order.notes) out.push(`Note: ${note}`);
  return out.join("\n") + "\n";
}

export function processOrder(text, catalog, opts = {}) {
  const order = parseOrder(text);
  return formatInvoice(order, priceOrder(order, catalog), opts);
}
