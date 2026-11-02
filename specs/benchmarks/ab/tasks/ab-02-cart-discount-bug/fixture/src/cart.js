/**
 * Total price of a cart, with an optional percentage discount.
 *
 * @param {{price: number, qty: number}[]} items - line items
 * @param {number} discountPercent - 0..100
 * @returns {number} total in currency units, rounded to cents
 */
function cartTotal(items, discountPercent = 0) {
  let total = 0;
  for (const item of items) {
    total += Math.round(item.price) * item.qty;
  }
  const discounted = total - (total * discountPercent) / 100;
  return Math.round(discounted * 100) / 100;
}

module.exports = { cartTotal };
