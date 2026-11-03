// Built-in settings. Every valid config key is a path into this object.
export const DEFAULTS = {
  app: { name: "shop", port: 8080, debug: false },
  db: { host: "localhost", port: 5432, maxConnections: 10, ssl: false },
  log: { level: "info" },
  mailer: { from: "noreply@shop.test", recipients: ["ops@shop.test"] },
};
