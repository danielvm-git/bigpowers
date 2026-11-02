export default class TTLCache {
  constructor(ttlMs) {
    this.ttlMs = ttlMs;
    this.cache = new Map();
  }

  async get(key, fetchFn) {
    if (this.cache.has(key)) {
      const entry = this.cache.get(key);
      if (Date.now() < entry.expiry) {
        return entry.value;
      }
      this.cache.delete(key);
    }

    // Race condition here: multiple concurrent calls to get(key)
    // will all call fetchFn(key) simultaneously if the key is missing/expired.
    const value = await fetchFn(key);
    this.set(key, value);
    return value;
  }

  set(key, value) {
    const expiry = Date.now() + this.ttlMs;
    this.cache.set(key, { value, expiry });
  }

  clear() {
    this.cache.clear();
  }
}
