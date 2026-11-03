// Orders: parse order text, price it and render invoices. Each step lives in its own module.
import { formatInvoice } from "./invoice.js";
import { parseOrder } from "./parse.js";
import { priceOrder } from "./pricing.js";

export { formatMoney } from "./money.js";
export { formatInvoice, parseOrder, priceOrder };

export function processOrder(text, catalog, opts = {}) {
  const order = parseOrder(text);
  return formatInvoice(order, priceOrder(order, catalog), opts);
}
