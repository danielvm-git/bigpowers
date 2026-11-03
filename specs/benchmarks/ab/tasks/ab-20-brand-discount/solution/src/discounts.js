import { DISCOUNT_CODES } from "./rules.js";
import { formatMoney } from "./money.js";

// Applies the order's discount code to the priced lines; returns the discount in cents.
export function applyDiscount(order, lines, subtotal) {
  if (!order.code) return 0;
  const rule = DISCOUNT_CODES[order.code];
  if (!rule) throw new Error(`unknown discount code: ${order.code}`);
  if (rule.from && !order.date) throw new Error(`discount code needs an order date: ${order.code}`);
  if (rule.from && (order.date < rule.from || order.date > rule.to)) {
    throw new Error(`discount code expired: ${order.code}`);
  }
  if (rule.type === "bogo") return applyBogo(rule, lines);
  if (rule.type === "brand_percent") return applyBrandPercent(order.code, rule, lines);
  const discount = codeAmount(order.code, rule, lines, subtotal);
  if (discount > 0) allocate(discount, lines, subtotal);
  return discount;
}

function applyBrandPercent(code, rule, lines) {
  const brandLines = lines.filter((l) => l.brand === rule.brand);
  if (brandLines.length === 0) {
    throw new Error(`discount code ${code} needs items from brand: ${rule.brand}`);
  }
  const brandSubtotal = brandLines.reduce((sum, l) => sum + l.amountCents, 0);
  if (rule.minBrandSubtotal && brandSubtotal < rule.minBrandSubtotal) {
    throw new Error(`discount code ${code} needs a brand subtotal of at least ${formatMoney(rule.minBrandSubtotal, "EUR")}`);
  }
  const discount = Math.round((brandSubtotal * rule.value) / 100);
  if (discount > 0) allocate(discount, brandLines, brandSubtotal);
  return discount;
}

function codeAmount(code, rule, lines, subtotal) {
  if (rule.type === "percent") {
    if (subtotal < rule.minSubtotal) {
      throw new Error(`discount code ${code} needs a subtotal of at least ${formatMoney(rule.minSubtotal, "EUR")}`);
    }
    return Math.round((subtotal * rule.value) / 100);
  }
  if (rule.type === "fixed") return Math.min(rule.value, subtotal);
  const qty = lines.reduce((sum, l) => sum + l.qty, 0);
  const tier = rule.tiers.find(([min]) => qty >= min);
  return tier ? Math.round((subtotal * tier[1]) / 100) : 0;
}

// Every second unit in the category is free, cheapest units first.
function applyBogo(rule, lines) {
  const units = [];
  for (const l of lines) {
    if (l.category !== rule.category) continue;
    for (let k = 0; k < l.qty; k++) units.push({ line: l, cents: l.unitCents });
  }
  units.sort((a, b) => a.cents - b.cents);
  let discount = 0;
  for (let k = 0; k < Math.floor(units.length / 2); k++) {
    units[k].line.discountCents += units[k].cents;
    discount += units[k].cents;
  }
  return discount;
}

// Spreads the discount over lines by amount; leftover cents go to the largest lines first.
function allocate(discount, lines, subtotal) {
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
