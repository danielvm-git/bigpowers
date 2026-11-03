// Amounts are kept as integer "units" of 1/10000 of the currency, so usage prices such as
// 0.3333 are exact. Cents appear only when a figure is presented.

export const UNITS_PER_CENT = 100;

export function parseAmount(text) {
  const m = /^(-)?(\d+)(?:\.(\d{1,4}))?$/.exec(String(text).trim());
  if (!m) throw new Error(`bad amount: ${text}`);
  const units = Number(m[2]) * 10000 + Number((m[3] || "").padEnd(4, "0"));
  return m[1] ? -units : units;
}

// Half away from zero: 0.005 -> 0.01, -0.005 -> -0.01.
export function roundToCents(units) {
  const sign = units < 0 ? -1 : 1;
  return sign * Math.floor((Math.abs(units) + UNITS_PER_CENT / 2) / UNITS_PER_CENT);
}

export function formatCents(cents) {
  const sign = cents < 0 ? "-" : "";
  const abs = Math.abs(cents);
  const whole = String(Math.floor(abs / 100)).replace(/\B(?=(\d{3})+(?!\d))/g, ",");
  return `${sign}${whole}.${String(abs % 100).padStart(2, "0")}`;
}

export function formatUnits(units) {
  const sign = units < 0 ? "-" : "";
  const abs = Math.abs(units);
  return `${sign}${Math.floor(abs / 10000)}.${String(abs % 10000).padStart(4, "0")}`;
}
