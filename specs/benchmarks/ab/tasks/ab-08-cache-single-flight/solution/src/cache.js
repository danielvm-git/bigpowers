export default class TTLCache {
  constructor(ttlMs) {
    this.ttlMs = ttlMs;
    this.cache = new Map();
    this.inFlight = new Map();
  }

  async get(key, fetchFn) {
    if (this.cache.has(key)) {
      const entry = this.cache.get(key);
      if (Date.now() < entry.expiry) {
        return entry.value;
      }
      this.cache.delete(key);
    }

    if (!this.inFlight.has(key)) {
      const pending = Promise.resolve()
        .then(() => fetchFn(key))
        .then((value) => {
          this.set(key, value);
          return value;
        })
        .finally(() => this.inFlight.delete(key));
      this.inFlight.set(key, pending);
    }
    return this.inFlight.get(key);
  }

  set(key, value) {
    const expiry = Date.now() + this.ttlMs;
    this.cache.set(key, { value, expiry });
  }

  clear() {
    this.cache.clear();
    this.inFlight.clear();
  }
}
