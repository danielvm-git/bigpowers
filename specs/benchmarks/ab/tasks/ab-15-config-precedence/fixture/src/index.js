import { loadConfig } from "./config.js";
import { dbUrl } from "./db.js";
import { listenAddress } from "./server.js";
import { logLine } from "./logger.js";
import { envelope } from "./mailer.js";

// Builds the config once and hands it to every module. Returns the startup summary.
export function start({ argv = [], env = {}, cwd = process.cwd() } = {}) {
  const config = loadConfig({ argv, env, cwd });
  const mail = envelope(config, "started");
  return [
    `app ${config.app.name} on ${listenAddress(config)} (debug ${config.app.debug ? "on" : "off"})`,
    `db ${dbUrl(config)}`,
    `log level ${config.log.level}`,
    `mail from ${mail.from} to ${mail.to}`,
    logLine(config, "debug", "debug logging enabled") ?? "debug logging disabled",
  ].join("\n");
}
