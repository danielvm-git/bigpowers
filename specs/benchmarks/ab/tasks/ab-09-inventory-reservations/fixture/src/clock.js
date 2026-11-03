// Injected clock interface for deterministic time travel testing
let currentTime = 1773489600000; // 2026-03-14T12:00:00.000Z

export const clock = {
  now() {
    return currentTime;
  },
  advance(ms) {
    currentTime += ms;
    return currentTime;
  },
  set(timeMs) {
    currentTime = timeMs;
    return currentTime;
  },
  reset() {
    currentTime = 1773489600000;
  }
};
