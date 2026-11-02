/**
 * Retry a function with exponential backoff.
 * @param {Function} fn - The async function to retry.
 * @param {{retries?: number, baseDelayMs?: number}} [options]
 * @returns {Promise<any>} - The result of the function.
 */
export async function withRetry(fn, { retries = 3, baseDelayMs = 100 } = {}) {
  let lastError;
  for (let attempt = 0; attempt <= retries; attempt++) {
    try {
      return await fn();
    } catch (err) {
      lastError = err;
      if (attempt < retries) await sleep(baseDelayMs * 2 ** attempt);
    }
  }
  throw new RetryExhaustedError(`Failed after ${retries + 1} attempts`, lastError);
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

export class RetryExhaustedError extends Error {
  constructor(message, lastError) {
    super(message);
    this.name = "RetryExhaustedError";
    this.lastError = lastError;
  }
}
