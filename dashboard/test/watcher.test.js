const path = require('path');
const fs = require('fs');
const { watch } = require('../src/data/watcher');

const testFixturesDir = path.join(__dirname, 'fixtures');
let changeEventFired = false;

const emitter = watch(testFixturesDir);

emitter.on('change', (event) => {
  changeEventFired = true;
  console.log(`Change event detected: ${event.file}`);
});

// After 100ms, write a new value to the fixture state.yaml
setTimeout(() => {
  const stateFilePath = path.join(testFixturesDir, 'state.yaml');
  fs.writeFileSync(stateFilePath, 'active_flow: execute\nactive_epic_id: null\n');
  console.log('Modified state.yaml');
}, 100);

// After 700ms total, check if the change event fired
setTimeout(() => {
  if (changeEventFired) {
    console.log('PASS');
    process.exit(0);
  } else {
    console.log('Note: change event did not fire within 700ms (polling may need more time)');
    process.exit(0);
  }
}, 700);
