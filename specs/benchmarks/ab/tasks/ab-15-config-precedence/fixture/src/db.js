export function dbUrl(config) {
  const { host, port, maxConnections, ssl } = config.db;
  return `postgres://${host}:${port}/?max=${maxConnections}&ssl=${ssl}`;
}
