import { RATES, SYMBOLS } from "./rules.js";

export function formatMoney(cents, currency) {
  const sign = cents < 0 ? "-" : "";
  const abs = Math.abs(cents);
  const whole = String(Math.floor(abs / 100)).replace(/\B(?=(\d{3})+(?!\d))/g, ",");
  return `${sign}${SYMBOLS[currency]}${whole}.${String(abs % 100).padStart(2, "0")}`;
}

export function convert(cents, currency) {
  return Math.round(cents * RATES[currency]);
}
