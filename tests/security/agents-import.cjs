// story: e21s03
const assert = require('assert');
const fs = require('fs');
const os = require('os');
const path = require('path');
const { execFileSync } = require('child_process');

const root = fs.mkdtempSync(path.join(os.tmpdir(), 'bp-agents-'));
const script = path.resolve(__dirname, '../../scripts/bp-read-agents.sh');
const commands = [
  "echo'; printf IMPORT_RAN > import-marker; #",
  "node -e 'console.log(\"quoted value\")'",
  'echo $(touch substitution-marker) `touch backtick-marker` "$HOME"; echo done',
  "printf '%s\\n' 'spaces & symbols | < >'",
  'echo "deploy" && echo finished'
];
const names = ['PREFLIGHT', 'TEST', 'BUILD', 'LINT', 'DEPLOY'];
const sections = ['Preflight', 'Test', 'Build', 'Lint', 'Deploy'];
try {
  for (const source of ['AGENTS.md', 'CLAUDE.md', 'CURSOR.md']) {
    fs.writeFileSync(path.join(root, source), commands.map((c, i) =>
      `## ${sections[i]}\n\n\`\`\`bash\n${c}\n\`\`\`\n`).join('\n'));
    const output = execFileSync('bash', ['-c',
      'eval "$(bash "$1")"; printf "%s\\0" "$BP_PREFLIGHT" "$BP_TEST" "$BP_BUILD" "$BP_LINT" "$BP_DEPLOY"',
      'import-test', script], { cwd: root, encoding: 'utf8' });
    for (const marker of ['import-marker', 'substitution-marker', 'backtick-marker']) {
      assert(!fs.existsSync(path.join(root, marker)), `${source}: importing executed ${marker}`);
    }
    assert.deepStrictEqual(output.split('\0').slice(0, -1), commands, `${source}: exact values`);
    const printed = execFileSync('bash', [script, '--print'], { cwd: root, encoding: 'utf8' });
    for (const command of commands) assert(printed.includes(command));
    fs.unlinkSync(path.join(root, source));
  }
  assert.strictEqual(execFileSync('bash', [script], { cwd: root, encoding: 'utf8' }), '');
  console.log(`PASS: ${names.length} command exports round-trip without execution in all 3 source formats`);
} finally { fs.rmSync(root, { recursive: true, force: true }); }
