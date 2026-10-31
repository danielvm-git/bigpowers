const assert = require('assert');
const fs = require('fs');
const http = require('http');
const path = require('path');
const vm = require('vm');

// Replace filesystem watching and Express routing at the I/O boundary, but
// exercise a real TCP listener with the arguments supplied by createServer.
const filename = path.resolve(__dirname, '../../dashboard/src/web/server.js');
const moduleStub = { exports: {} };
const sandbox = {
  module: moduleStub, __dirname: path.dirname(filename), console, setTimeout, clearTimeout,
  require(name) {
    if (name === 'path') return path;
    if (name === '../loaders/watcher') return { watch: () => ({ on() {} }) };
    if (name.startsWith('../loaders/')) return {};
    assert.strictEqual(name, 'express');
    return () => ({ get() {}, listen: (...args) => http.createServer().listen(...args) });
  }
};
vm.runInNewContext(fs.readFileSync(filename, 'utf8'), sandbox, { filename });
const app = moduleStub.exports.createServer('/unused', 0);
const server = app.listen(0, () => {
  try {
    assert.strictEqual(server.address().address, '127.0.0.1');
    assert(server.address().port > 0, 'ephemeral port and callback remain supported');
    console.log('PASS: dashboard binds only to IPv4 loopback');
  } catch (error) { console.error(error); process.exitCode = 1; }
  finally { server.close(); }
});
server.on('error', error => { console.error(error); process.exitCode = 1; });
