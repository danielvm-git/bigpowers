export default class RateLimiter {
  constructor(limit, windowMs) {
    this.limit = limit;
    this.windowMs = windowMs;
    this.requests = 0;
    this.lastReset = Date.now();
  }

  isAllowed() {
    const now = Date.now();

    if (now - this.lastReset >= this.windowMs) {
      this.lastReset = now;
      this.requests = 0;
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
