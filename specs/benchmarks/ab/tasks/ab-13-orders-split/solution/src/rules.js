// Business tables: currencies, tax, shipping zones and discount codes.
export const RATES = { EUR: 1, USD: 1.08, GBP: 0.86 };
export const SYMBOLS = { EUR: "€", USD: "$", GBP: "£" };

export const TAX_RATES = {
  PT: { standard: 0.23, books: 0.06 },
  ES: { standard: 0.21, books: 0.04 },
  FR: { standard: 0.2, books: 0.055 },
  DE: { standard: 0.19, books: 0.07 },
  IT: { standard: 0.22, books: 0.04 },
  NL: { standard: 0.21, books: 0.09 },
  UK: { standard: 0.2, books: 0 },
  US: { standard: 0, books: 0 },
};

export const SHIPPING = {
  PT: { base: 399, perKg: 150, zone: "domestic" },
  ES: { base: 399, perKg: 150, zone: "domestic" },
  FR: { base: 699, perKg: 200, zone: "eu" },
  DE: { base: 699, perKg: 200, zone: "eu" },
  IT: { base: 699, perKg: 200, zone: "eu" },
  NL: { base: 699, perKg: 200, zone: "eu" },
  UK: { base: 999, perKg: 300, zone: "uk" },
  US: { base: 1499, perKg: 400, zone: "us" },
};

export const DISCOUNT_CODES = {
  SPRING10: { type: "percent", value: 10, minSubtotal: 2000, from: "2026-03-01", to: "2026-05-31" },
  FIVEOFF: { type: "fixed", value: 500 },
  "BOGO-BOOKS": { type: "bogo", category: "books" },
  BULK: { type: "tiered", tiers: [[10, 15], [5, 7]] },
};

export const GIFT_WRAP_CENTS = 250;
export const FREE_SHIPPING_THRESHOLD = 5000;
