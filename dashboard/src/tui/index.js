const path = require('path');
const { watch } = require('../loaders/watcher');
const { readStateYaml, readExecutionStatus, readEpicShards, readCycleTimes } = require('../loaders/reader');
const { computeProjectMetrics } = require('../loaders/metrics');
const { renderPipeline } = require('./pipeline');
const { renderEpicQueue } = require('./epic-queue');
const { renderMetricsBar } = require('./metrics-bar');
const { renderStateYaml } = require('./state-yaml');
const { renderFilesystem } = require('./filesystem');
const { renderLedger } = require('./ledger');

// Blessed box defaults — tags must be enabled for markup to render
const BOX_DEFAULTS = { tags: true };

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
  if (screen.width < 120 || screen.height < 34) {
    const msg = blessed.box({
      parent: screen,
      top: 'center',
      left: 'center',
      width: 60,
      height: 10,
      content: '{center}Terminal must be at least 120x34{/center}\n{center}Please resize and try again{/center}',
      border: 'line',
      tags: true,
      style: { border: { fg: 'yellow' } }
    });
    screen.render();
    return;
  }

  // Create layout zones
  const titleBar = blessed.box({
    parent: screen,
    top: 0,
    left: 0,
    width: '100%',
    height: 1,
    tags: true,
  });

  // height 5 = 3 content lines + top/bottom borders: status bar, step info, stats row
  const metricsBar = blessed.box({
    parent: screen,
    top: 1,
    left: 0,
    width: '100%',
    height: 5,
    border: 'line',
    tags: true,
    style: { border: { fg: 'blue' } }
  });

  const pipeline = blessed.box({
    parent: screen,
    top: 6,
    left: 0,
    width: '100%',
    height: 5,
    border: 'line',
    tags: true,
    label: ' {green-fg}≡ PIPELINE{/green-fg} ',
    style: { border: { fg: 'green' } }
  });

  const epicQueue = blessed.box({
    parent: screen,
    top: 11,
    left: 0,
    width: '33%',
    height: screen.height - 23,
    border: 'line',
    scrollable: true,
    mouse: true,
    keys: true,
    tags: true,
    label: ' {green-fg}≡ EPIC QUEUE{/green-fg} ',
    style: { border: { fg: 'green' } }
  });

  const actionLog = blessed.box({
    parent: screen,
    top: 11,
    left: '33%',
    width: '33%',
    height: screen.height - 23,
    border: 'line',
    scrollable: true,
    mouse: true,
    keys: true,
    tags: true,
    label: ' {cyan-fg}>_ STATE.YAML{/cyan-fg} ',
    style: { border: { fg: 'cyan' } }
  });

  const fsPanel = blessed.box({
    parent: screen,
    top: 11,
    left: '66%',
    width: '34%',
    height: screen.height - 23,
    border: 'line',
    scrollable: true,
    mouse: true,
    keys: true,
    tags: true,
    label: ' {magenta-fg}□ FILESYSTEM{/magenta-fg} ',
    style: { border: { fg: 'magenta' } }
  });

  const ledger = blessed.box({
    parent: screen,
    top: screen.height - 11,
    left: 0,
    width: '100%',
    height: 11,
    border: 'line',
    scrollable: true,
    mouse: true,
    keys: true,
    tags: true,
    label: ' {cyan-fg}⊙ CYCLE TIME LEDGER — BCPS · TIMESTAMPS · THROUGHPUT{/cyan-fg} ',
    style: { border: { fg: 'cyan' } }
  });

  // Refresh function
  function refresh() {
    const stateData = readStateYaml(projectRoot);
    const executionStatus = readExecutionStatus(projectRoot);
    const epics = readEpicShards(projectRoot);
    const cycleTimes = readCycleTimes(projectRoot);
    const metrics = computeProjectMetrics(cycleTimes);

    // Title bar: fixed project identity
    titleBar.setContent(' {bold}{cyan-fg}⚙ bigpowers factory{/cyan-fg}{/bold} {gray-fg}v2 — seed {cyan-fg}→{/cyan-fg} epics {cyan-fg}→{/cyan-fg} mvp{/gray-fg}');

    renderMetricsBar(metricsBar, metrics, stateData, epics, cycleTimes);
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
