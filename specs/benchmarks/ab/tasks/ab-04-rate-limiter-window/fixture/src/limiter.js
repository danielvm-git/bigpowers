export default class RateLimiter {
  constructor(limit, windowMs) {
    this.limit = limit;
    this.windowMs = windowMs;
    this.requests = 0;
    this.lastReset = Date.now();
  }

  isAllowed() {
    const now = Date.now();

    // Bug 1: Window expiry check is off-by-one (should be >= windowMs)
    // and it doesn't actually reset the counter correctly.
    if (now - this.lastReset > this.windowMs) {
      this.lastReset = now;
      // Bug 2: Fails to reset requests to 0 when window expires
      // this.requests = 0; // MISSING
    }

    if (this.requests < this.limit) {
      this.requests++;
      return true;
    }

    return false;
  }

  reset() {
    this.requests = 0;
    this.lastReset = Date.now();
  }
}
