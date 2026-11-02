/**
 * Retry a function with exponential backoff.
 * @param {Function} fn - The function to retry.
 * @returns {Promise<any>} - The result of the function.
 */
export async function withRetry(fn) {
  // TODO: Implement retry with exponential backoff.
  // We need to support custom retry counts and delay strategies.
  return fn();
}

export class RetryExhaustedError extends Error {
  constructor(message, lastError) {
    super(message);
    this.name = "RetryExhaustedError";
    this.lastError = lastError;
  }
}
