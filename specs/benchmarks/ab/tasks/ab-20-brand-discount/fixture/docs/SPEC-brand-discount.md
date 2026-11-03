# Specification: Brand-Specific Percentage Discount

## Background
We are expanding the discount system to support brand-specific percentage discounts (e.g. 20% off all Acme products).

## Requirements

1. **Catalog Brand Attribute:**
   Catalog items can now specify an optional `brand` string property (e.g. `"acme"`, `"zenith"`). In `src/pricing.js`, `toLine(item, catalog)` must map `brand: product.brand || null` to each order line.

2. **Discount Code Rule Definition:**
   A discount rule with `type: "brand_percent"` has the following shape:
   ```javascript
   {
     type: "brand_percent",
     brand: "acme",         // target brand (case-sensitive)
     value: 20,             // percentage discount (0-100)
     minBrandSubtotal: 3000 // optional minimum spend in cents for this brand only
   }
   ```
   Add the following new discount codes to `DISCOUNT_CODES` in `src/rules.js`:
   - `ACME20`: `{ type: "brand_percent", brand: "acme", value: 20, minBrandSubtotal: 3000 }`
   - `ZENITH15`: `{ type: "brand_percent", brand: "zenith", value: 15 }`

3. **Discount Calculation & Validation in `src/discounts.js`:**
   - If an order uses a `brand_percent` code:
     - Find all order lines where `line.brand === rule.brand`.
     - If the order contains no items from that brand, throw `new Error("discount code " + code + " needs items from brand: " + rule.brand)`.
     - Calculate the total amount for the brand: `brandSubtotal = sum(line.amountCents for matching lines)`.
     - If `rule.minBrandSubtotal` is specified and `brandSubtotal < rule.minBrandSubtotal`, throw:
       `new Error("discount code " + code + " needs a brand subtotal of at least " + formatMoney(rule.minBrandSubtotal, "EUR"))`.
     - The total brand discount is: `Math.round((brandSubtotal * rule.value) / 100)`.
     - The discount must be allocated exclusively among the matching brand lines (using `allocate(discount, brandLines, brandSubtotal)`). Non-brand lines receive 0 discount.
     - Return the total discount in cents.

4. **Invariants & Preservations:**
   - All existing discount codes (`SPRING10`, `FIVEOFF`, `BOGO-BOOKS`, `BULK`) must continue to behave exactly as before.
   - Tax and shipping calculations must remain intact.
   - All tests in `test/orders.test.js` must keep passing.
