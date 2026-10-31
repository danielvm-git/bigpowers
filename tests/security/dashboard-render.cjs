const assert = require('assert');
const fs = require('fs');
const path = require('path');
const vm = require('vm');

// Execute the shipped client and feed its public fetch/SSE inputs. Capture
// generated HTML at the DOM boundary; this is not a browser execution test.
const nodes = new Map(['pipeline', 'metrics', 'state', 'epics', 'ledger', 'status']
  .map(id => [id, { innerHTML: '', classList: { add() {}, remove() {} } }]));
const events = new Map();
let stream;
const payload = '<img src=x onerror="window.__bpXss=1"> & \'quoted\'';
const escaped = '&lt;img src=x onerror=&quot;window.__bpXss=1&quot;&gt; &amp; &#39;quoted&#39;';
const snapshot = {
  state: { activeFlow: payload, activeEpic: payload, activeStory: payload,
    gitBranch: payload, release: { version: payload } },
  projectMetrics: { totalBcps: payload, avgBcpPerHour: 1.5 },
  currentVelocity: { avgBcpPerHour: 2 },
  epics: [{ id: payload, title: payload, stories: [] }],
  cycleTimes: [{ id: payload, bcps: payload, cycleMin: payload, bcpPerHour: 3 }]
};
const sandbox = {
  console,
  document: {
    getElementById: id => nodes.get(id), querySelectorAll: () => [],
    addEventListener() {}, createElement: () => ({ getContext: () => ({}) })
  },
  window: { addEventListener: (name, fn) => events.set(name, fn) },
  fetch: async () => ({ json: async () => JSON.parse(JSON.stringify(snapshot)) }),
  EventSource: class { constructor() { stream = this; } },
  setInterval() { throw new Error('unexpected polling fallback'); }
};
const filename = path.resolve(__dirname, '../../dashboard/src/web/client.html');
const html = fs.readFileSync(filename, 'utf8');
for (const match of html.matchAll(/<script>([\s\S]*?)<\/script>/g)) {
  vm.runInNewContext(match[1], sandbox, { filename });
}
function assertEscaped() {
  for (const [panel, count] of [['state', 4], ['metrics', 2], ['epics', 2], ['ledger', 3]]) {
    const output = nodes.get(panel).innerHTML;
    assert(!output.includes('<img'), `${panel}: project metadata became HTML`);
    assert.strictEqual(output.split(escaped).length - 1, count, `${panel}: literal text preserved`);
  }
}
async function main() {
  events.get('load')();
  await new Promise(resolve => setImmediate(resolve));
  assertEscaped();
  assert(stream, 'initial fetch should connect SSE');
  stream.onmessage({ data: JSON.stringify(snapshot) });
  assertEscaped();
  stream.onmessage({ data: JSON.stringify({ state: { gitBranch: 'feature/example' },
    projectMetrics: { totalBcps: 0, avgBcpPerHour: 0 } }) });
  assert(nodes.get('state').innerHTML.includes('feature/example'));
  assert(nodes.get('metrics').innerHTML.includes('>0</span>'));
  assert(nodes.get('epics').innerHTML.includes('No epics available'));
  assert(nodes.get('ledger').innerHTML.includes('No cycle-time data available'));
  console.log('PASS: fetch and SSE render all project metadata as escaped text');
}
main().catch(error => { console.error(error); process.exitCode = 1; });
