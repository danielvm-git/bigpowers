import { formatMoney } from "./money.js";

export function formatInvoice(order, priced, opts = {}) {
  const format = opts.format || "text";
  if (format === "json") {
    return JSON.stringify({ order: order.id, date: order.date, customer: order.customer, region: order.region, ...priced }, null, 2);
  }
  if (format === "csv") return csvInvoice(priced);
  if (format !== "text") throw new Error(`unknown format: ${format}`);
  return textInvoice(order, priced, opts.width || 44);
}

function csvInvoice(priced) {
  const rows = ["sku,qty,gift,amount,discount,tax"];
  for (const l of priced.lines) {
    rows.push([l.sku, l.qty, l.gift ? "yes" : "no", l.amountCents, l.discountCents, l.taxCents].join(","));
  }
  rows.push(`subtotal,,,${priced.subtotalCents},${priced.discountCents},`);
  rows.push(`extras,,,${priced.giftWrapCents + priced.shippingCents},,`);
  rows.push(`total,,,${priced.totalCents},,${priced.taxCents}`);
  return rows.join("\n") + "\n";
}

function textInvoice(order, priced, width) {
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
