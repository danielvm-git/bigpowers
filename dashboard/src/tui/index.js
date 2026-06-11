const path = require('path');
const { watch } = require('../data/watcher');
const { readStateYaml, readExecutionStatus, readEpicShards, readCycleTimes } = require('../data/reader');
const { getMetrics } = require('../data/metrics');
const { renderPipeline } = require('./pipeline');
const { renderEpicQueue } = require('./epic-queue');
const { renderMetricsBar } = require('./metrics-bar');
const { renderStateYaml } = require('./state-yaml');
const { renderFilesystem } = require('./filesystem');
const { renderLedger } = require('./ledger');

let blessed;
try {
  blessed = require('blessed');
} catch (err) {
  blessed = null;
}

function start(projectRoot) {
  if (!blessed) {
    console.error('Error: blessed module is not installed. Please run: npm install blessed');
    process.exit(1);
  }

  // Create screen
  const screen = blessed.screen({
    smartCSR: true,
    mouse: true,
    title: 'BigPowers Dashboard',
    256: true,
    fullUnicode: true
  });

  // Check terminal size
  if (screen.width < 120 || screen.height < 30) {
    const msg = blessed.box({
      parent: screen,
      top: 'center',
      left: 'center',
      width: 60,
      height: 10,
      content: '{center}Terminal must be at least 120x30{/center}\n{center}Please resize and try again{/center}',
      border: 'line',
      style: { border: { fg: 'yellow' } }
    });
    screen.render();
    return;
  }

  // Create layout zones
  const metricsBar = blessed.box({
    parent: screen,
    top: 0,
    left: 0,
    width: '100%',
    height: 3,
    border: 'line',
    style: { border: { fg: 'blue' } }
  });

  const pipeline = blessed.box({
    parent: screen,
    top: 3,
    left: 0,
    width: '100%',
    height: 5,
    border: 'line',
    style: { border: { fg: 'cyan' } }
  });

  const epicQueue = blessed.box({
    parent: screen,
    top: 8,
    left: 0,
    width: '33%',
    height: screen.height - 20,
    border: 'line',
    scrollable: true,
    mouse: true,
    keys: true,
    style: { border: { fg: 'green' } }
  });

  const actionLog = blessed.box({
    parent: screen,
    top: 8,
    left: '33%',
    width: '33%',
    height: screen.height - 20,
    border: 'line',
    scrollable: true,
    mouse: true,
    keys: true,
    style: { border: { fg: 'yellow' } }
  });

  const fsPanel = blessed.box({
    parent: screen,
    top: 8,
    left: '66%',
    width: '34%',
    height: screen.height - 20,
    border: 'line',
    scrollable: true,
    mouse: true,
    keys: true,
    style: { border: { fg: 'magenta' } }
  });

  const ledger = blessed.box({
    parent: screen,
    top: screen.height - 12,
    left: 0,
    width: '100%',
    height: 12,
    border: 'line',
    scrollable: true,
    mouse: true,
    keys: true,
    style: { border: { fg: 'white' } }
  });

  // Refresh function
  function refresh() {
    const stateData = readStateYaml(projectRoot);
    const executionStatus = readExecutionStatus(projectRoot);
    const epics = readEpicShards(projectRoot);
    const cycleTimes = readCycleTimes(projectRoot);
    const metrics = getMetrics(cycleTimes);

    renderMetricsBar(metricsBar, metrics, stateData);
    renderPipeline(pipeline, stateData);
    renderEpicQueue(epicQueue, epics, executionStatus);
    renderStateYaml(actionLog, stateData);
    renderFilesystem(fsPanel, projectRoot);
    renderLedger(ledger, cycleTimes);

    screen.render();
  }

  // Set up file watcher
  const watcher = watch(projectRoot);
  watcher.on('change', () => {
    refresh();
  });

  // Initial refresh
  refresh();

  // Key bindings
  screen.key(['q', 'C-c'], () => {
    watcher.close();
    process.exit(0);
  });

  screen.key(['r'], () => {
    refresh();
  });
}

module.exports = { start };
