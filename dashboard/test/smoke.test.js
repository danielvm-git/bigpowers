const assert = require('assert');
const path = require('path');
const reader = require('../src/data/reader');
const metrics = require('../src/data/metrics');
const pipelineMap = require('../src/data/pipeline-map');
const gateStatus = require('../src/data/gate-status');

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

console.log(`Smoke test: PASS (${passed}/4 assertions)`);
process.exit(0);
