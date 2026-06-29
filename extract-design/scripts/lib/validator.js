import { execSync } from 'node:child_process';
import { existsSync } from 'node:fs';
import { log } from './logging.js';
const BIN = 'npx @google/design.md';

export class DesignValidator {
  constructor({ runCommand } = {}) { this._run = runCommand || ((c) => execSync(c, { encoding: 'utf8', timeout: 30_000 })); this._avail = null; }
  isAvailable() { if (this._avail !== null) return this._avail; try { this._run('npx -y @google/design.md --help'); this._avail = true; } catch { this._avail = false; } return this._avail; }
  lint(fp) { if (!this.isAvailable()) return { summary: { errors: 0, warnings: 0, info: 0 }, findings: [], skipped: true }; try { return JSON.parse(this._run(`${BIN} lint --format json ${fp}`)); } catch(e) { if (e.stdout) try { return JSON.parse(e.stdout); } catch {} throw e; } }
  diff(a, b) { if (!this.isAvailable()) return { skipped: true }; return JSON.parse(this._run(`${BIN} diff --format json ${a} ${b}`)); }
}
