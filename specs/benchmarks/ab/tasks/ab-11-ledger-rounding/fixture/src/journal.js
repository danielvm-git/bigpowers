import { formatUnits, parseAmount } from "./currency.js";

const DATE = /^\d{4}-\d{2}-\d{2}$/;

export class Journal {
  constructor(chart) {
    this.chart = chart;
    this.entries = [];
  }

  // lines: [{ account, debit: "12.50" } | { account, credit: "12.50" }]
  post({ date, memo = "", lines }) {
    if (!DATE.test(date || "")) throw new Error(`bad entry date: ${date}`);
    if (!Array.isArray(lines) || lines.length < 2) throw new Error("an entry needs at least two lines");
    const postings = lines.map((line) => this.#posting(line));
    const debits = postings.filter((p) => p.units > 0).reduce((sum, p) => sum + p.units, 0);
    const credits = -postings.filter((p) => p.units < 0).reduce((sum, p) => sum + p.units, 0);
    if (debits !== credits) {
      throw new Error(`entry does not balance: debits ${formatUnits(debits)}, credits ${formatUnits(credits)}`);
    }
    const id = this.entries.length + 1;
    this.entries.push({ id, date, memo, postings });
    return id;
  }

  postingsFor(code, { from = "0000-00-00", to = "9999-99-99" } = {}) {
    const found = [];
    for (const entry of this.entries) {
      if (entry.date < from || entry.date > to) continue;
      for (const p of entry.postings) if (p.account === code) found.push({ entryId: entry.id, date: entry.date, units: p.units });
    }
    return found;
  }

  #posting({ account, debit, credit }) {
    if (!this.chart.has(account)) throw new Error(`unknown account: ${account}`);
    if ((debit === undefined) === (credit === undefined)) throw new Error(`line for ${account} needs a debit or a credit`);
    const units = parseAmount(debit ?? credit);
    if (units <= 0) throw new Error(`amount for ${account} must be positive`);
    return { account, units: debit !== undefined ? units : -units };
  }
}
