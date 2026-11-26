import { log } from './logging.js';
import { RETRY_CONFIG } from './constants.js';
export async function withRetry(fn, opts = {}) {
  const max = opts.maxAttempts ?? RETRY_CONFIG.MAX_ATTEMPTS;
  const base = opts.baseDelayMs ?? RETRY_CONFIG.BASE_DELAY_MS;
  for (let a = 1; a <= max; a++) {
    try { return await fn(); }
    catch (e) { if (a === max) throw e; const d = base * Math.pow(2, a - 1); log.warn('retry', { attempt: a, max, delayMs: d, error: e.message }); await new Promise(r => setTimeout(r, d)); }
  }
}
export async function withTimeout(fn, ms) {
  return Promise.race([fn(), new Promise((_, r) => setTimeout(() => r(new Error(`Timed out after ${ms}ms`)), ms))]);
}
