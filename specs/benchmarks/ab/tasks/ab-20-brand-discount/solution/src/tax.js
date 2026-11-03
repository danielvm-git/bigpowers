import { TAX_RATES } from "./rules.js";

// Sets taxCents on each line (books at the reduced rate); extras pay the standard rate.
export function applyTax(region, lines, extrasCents) {
  const rates = TAX_RATES[region];
  let tax = 0;
  for (const l of lines) {
    l.taxCents = Math.round((l.amountCents - l.discountCents) * (l.category === "books" ? rates.books : rates.standard));
    tax += l.taxCents;
  }
  return tax + Math.round(extrasCents * rates.standard);
}
