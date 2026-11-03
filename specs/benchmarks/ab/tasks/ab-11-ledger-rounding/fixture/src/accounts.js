const NORMAL_SIDE = { asset: "debit", expense: "debit", liability: "credit", income: "credit", equity: "credit" };

export function createChart(definitions) {
  const chart = new Map();
  for (const { code, name, type } of definitions) {
    if (!/^\d{4}$/.test(code)) throw new Error(`bad account code: ${code}`);
    if (!NORMAL_SIDE[type]) throw new Error(`bad account type for ${code}: ${type}`);
    if (chart.has(code)) throw new Error(`duplicate account: ${code}`);
    chart.set(code, { code, name, type, normal: NORMAL_SIDE[type] });
  }
  return chart;
}

// +1 for accounts that grow with debits, -1 for accounts that grow with credits.
export function normalSign(account) {
  return account.normal === "debit" ? 1 : -1;
}
