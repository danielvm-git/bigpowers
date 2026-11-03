const LEVELS = ["debug", "info", "warn", "error"];

// The formatted line, or null when the level is below the configured one.
export function logLine(config, level, message) {
  if (LEVELS.indexOf(level) < LEVELS.indexOf(config.log.level)) return null;
  return `[${level}] ${config.app.name}: ${message}`;
}
