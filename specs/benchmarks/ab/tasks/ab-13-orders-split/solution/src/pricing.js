import { applyDiscount } from "./discounts.js";
import { convert } from "./money.js";
import { giftWrapFor, shippingFor } from "./shipping.js";
import { applyTax } from "./tax.js";

export function priceOrder(order, catalog) {
  const lines = order.items.map((item) => toLine(item, catalog));
  const subtotal = lines.reduce((sum, l) => sum + l.amountCents, 0);
  const discount = applyDiscount(order, lines, subtotal);
  const { shipping, weight, allDigital } = shippingFor(order.region, lines, subtotal - discount);
  const giftWrap = giftWrapFor(lines);
  const tax = applyTax(order.region, lines, shipping + giftWrap);

  const conv = (cents) => convert(cents, order.currency);
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

function toLine(item, catalog) {
  const product = catalog[item.sku];
  if (!product) throw new Error(`unknown sku: ${item.sku}`);
  const category = product.category || "general";
  return {
    sku: item.sku, name: product.name, category, qty: item.qty, gift: item.gift,
    unitCents: product.priceCents, amountCents: product.priceCents * item.qty, discountCents: 0, taxCents: 0,
    weightGrams: category === "digital" ? 0 : (product.weightGrams || 0) * item.qty,
  };
}
