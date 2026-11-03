import { FREE_SHIPPING_THRESHOLD, GIFT_WRAP_CENTS, SHIPPING } from "./rules.js";

export function shippingFor(region, lines, discountedSubtotal) {
  const weight = lines.reduce((sum, l) => sum + l.weightGrams, 0);
  const allDigital = lines.every((l) => l.category === "digital");
  const zone = SHIPPING[region];
  let shipping = 0;
  if (!allDigital) {
    shipping = zone.base + Math.max(0, Math.ceil((weight - 1000) / 1000)) * zone.perKg;
    if (zone.zone === "domestic" && discountedSubtotal >= FREE_SHIPPING_THRESHOLD) shipping = 0;
  }
  return { shipping, weight, allDigital };
}

export function giftWrapFor(lines) {
  return lines.filter((l) => l.gift).length * GIFT_WRAP_CENTS;
}
