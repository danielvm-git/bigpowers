const assert = require('assert');
const path = require('path');
const reader = require('../src/loaders/reader');
const metrics = require('../src/loaders/metrics');
const pipelineMap = require('../src/loaders/pipeline-map');
const gateStatus = require('../src/loaders/gate-status');
const { renderMetricsBar } = require('../src/tui/metrics-bar');
const { renderPipeline } = require('../src/tui/pipeline');
const { renderStateYaml } = require('../src/tui/state-yaml');
const { renderEpicQueue } = require('../src/tui/epic-queue');
const { renderFilesystem } = require('../src/tui/filesystem');
const { renderLedger } = require('../src/tui/ledger');

let passed = 0;

try {
  // Test 1: reader.readStateYaml
  const stateResult = reader.readStateYaml(path.join(__dirname, '..', '..', '..'));
  assert.ok(stateResult === null || typeof stateResult === 'object', 'readStateYaml should return null or object');
  passed++;
  console.log('  ✓ Test 1: reader.readStateYaml');
} catch (err) {
  console.error('✗ Test 1 failed:', err.message);
  process.exit(1);
}

try {
  // Test 2: metrics.computeProjectMetrics
  const metricsResult = metrics.computeProjectMetrics([
    { bcps: 3, cycleMin: 90 },
    { bcps: 2, cycleMin: 70 }
  ]);
  assert.strictEqual(metricsResult.totalBcps, 5, 'totalBcps should be 5');
  assert.strictEqual(metricsResult.totalMin, 160, 'totalMin should be 160');
  passed++;
  console.log('  ✓ Test 2: metrics.computeProjectMetrics');
} catch (err) {
  console.error('✗ Test 2 failed:', err.message);
  process.exit(1);
}

try {
  // Test 3: pipelineMap
  assert.strictEqual(pipelineMap.stepIndex('develop-tdd'), 3, 'develop-tdd should be at index 3');
  assert.strictEqual(pipelineMap.stepLabel(0), 'survey-context', 'step 0 should be survey-context');
  passed++;
  console.log('  ✓ Test 3: pipelineMap');
} catch (err) {
  console.error('✗ Test 3 failed:', err.message);
  process.exit(1);
}

try {
  // Test 4: gateStatus
  assert.strictEqual(gateStatus.gateColor('ready'), 'green', 'ready should be green');
  assert.strictEqual(gateStatus.gateColor('blocked'), 'red', 'blocked should be red');
  passed++;
  console.log('  ✓ Test 4: gateStatus');
} catch (err) {
  console.error('✗ Test 4 failed:', err.message);
  process.exit(1);
}

try {
  // Test 5: TUI render functions do not emit invalid blessed markup tags
  // Hardening against BUG-2026-06-11T160000: {dim} and {|} should never appear
  const mockBox = { content: '', setContent(c) { this.content = c; } };
  const testStateData = { activeFlow: 'test', release: { target_version: '1.0' }, gitBranch: 'main', epicCycle: { current_step: 1 } };
  const testEpics = [{ id: 'e01', title: 'Test', stories: [] }];

  renderMetricsBar(mockBox, { totalBcps: 5, totalMin: 120, avgBcpPerHour: 2.5 }, testStateData, testEpics, []);
  assert.ok(!mockBox.content.includes('{dim}') && !mockBox.content.includes('{|}'), 'metrics-bar should not contain {dim} or {|}');

  renderPipeline(mockBox, testStateData);
  assert.ok(!mockBox.content.includes('{dim}'), 'pipeline should not contain {dim}');

  renderStateYaml(mockBox, testStateData);
  assert.ok(!mockBox.content.includes('{dim}'), 'state-yaml should not contain {dim}');

  renderEpicQueue(mockBox, testEpics, null);
  assert.ok(!mockBox.content.includes('{dim}'), 'epic-queue should not contain {dim}');

  renderFilesystem(mockBox, path.join(__dirname, '..', '..', '..'));
  assert.ok(!mockBox.content.includes('{dim}'), 'filesystem should not contain {dim}');

  renderLedger(mockBox, [{ id: 's01', bcps: 3, cycleMin: 60, epic: 'e01' }]);
  assert.ok(!mockBox.content.includes('{dim}'), 'ledger should not contain {dim}');

  passed++;
  console.log('  ✓ Test 5: TUI render output does not contain invalid blessed markup tags');
} catch (err) {
  console.error('✗ Test 5 failed:', err.message);
  process.exit(1);
}

console.log(`Smoke test: PASS (${passed}/5 assertions)`);
process.exit(0);
