const path = require('path');
const { watch } = require('../loaders/watcher');
const reader = require('../loaders/reader');
const metrics = require('../loaders/metrics');

let express;
try {
  express = require('express');
} catch (err) {
  express = null;
}

function createServer(projectRoot, port = 7742) {
  const watcher = watch(projectRoot);
  const clients = new Set();
  let debounceTimer = null;

  function buildSnapshot() {
    const state = reader.readStateYaml(projectRoot);
    const execStatus = reader.readExecutionStatus(projectRoot);
    const epics = reader.readEpicShards(projectRoot);
    const cycleTimes = reader.readCycleTimes(projectRoot);

    const projectMetrics = metrics.computeProjectMetrics(cycleTimes);
    const currentVelocity = metrics.computeCurrentVelocity(cycleTimes);

    return {
      state,
      execStatus,
      epics,
      cycleTimes,
      projectMetrics,
      currentVelocity,
      timestamp: new Date().toISOString()
    };
  }

  function broadcastSnapshot() {
    if (debounceTimer) {
      clearTimeout(debounceTimer);
    }
    debounceTimer = setTimeout(() => {
      const snapshot = buildSnapshot();
      const message = `data: ${JSON.stringify(snapshot)}\n\n`;
      for (const client of clients) {
        client.write(message);
      }
    }, 300);
  }

  watcher.on('change', broadcastSnapshot);

  if (!express) {
    // Fallback: return a minimal server object that doesn't do much
    return {
      listen(portNum, cb) {
        console.warn('Express not installed. Server will not start.');
        if (cb) cb();
        return {
          close() {}
        };
      }
    };
  }

  const app = express();

  // GET / - serve client.html
  app.get('/', (req, res) => {
    const clientPath = path.join(__dirname, 'client.html');
    res.sendFile(clientPath);
  });

  // GET /api/state - return current snapshot as JSON
  app.get('/api/state', (req, res) => {
    const snapshot = buildSnapshot();
    res.json(snapshot);
  });

  // GET /events - Server-Sent Events endpoint
  app.get('/events', (req, res) => {
    res.writeHead(200, {
      'Content-Type': 'text/event-stream',
      'Cache-Control': 'no-cache',
      'Connection': 'keep-alive'
    });

    // Send initial snapshot
    const snapshot = buildSnapshot();
    res.write(`data: ${JSON.stringify(snapshot)}\n\n`);

    // Add client to set
    clients.add(res);

    // Clean up on disconnect
    req.on('close', () => {
      clients.delete(res);
    });

    res.on('error', () => {
      clients.delete(res);
    });
  });

  return {
    listen(portNum = port, cb) {
      return app.listen(portNum, cb);
    }
  };
}

module.exports = { createServer };
