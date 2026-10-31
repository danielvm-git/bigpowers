// story: e32s04
const assert = require('assert');
const fs = require('fs');
const os = require('os');
const path = require('path');
const { execFileSync } = require('child_process');

const root = fs.mkdtempSync(path.join(os.tmpdir(), 'bp-diff-'));
const git = (...args) => execFileSync('git', args, { cwd: root, stdio: 'pipe' });
const put = (name, value) => {
  fs.mkdirSync(path.dirname(path.join(root, name)), { recursive: true });
  fs.writeFileSync(path.join(root, name), value);
};

async function main() {
  const { getGitContext } = await import('../../bigpowers-mcp/build/lib/git-context.js');
  git('init', '-q');
  const secret = 'specs/m-secret.pem';
  const before = 'specs/a-public.md';
  const after = 'specs/z-public.md';
  const outside = 'private/readme.md';
  for (const file of [secret, before, after, outside]) put(file, 'baseline\n');
  git('add', '.');
  git('-c', 'user.name=Test', '-c', 'user.email=test@example.invalid',
    'commit', '-qm', 'fixture');
  for (const allowed of [[after], [before, after], [before], []]) {
    git('reset', '--hard', 'HEAD');
    put(secret, 'DUMMY_SECRET_VALUE\n');
    put(outside, 'OUT_OF_SCOPE_VALUE\n');
    for (const file of allowed) put(file, 'PUBLIC_CHANGE\n');
    const result = getGitContext(root, 'diff');
    assert.deepStrictEqual(Object.keys(result.diffs).sort(), [...allowed].sort());
    assert.deepStrictEqual(Object.values(result.changed_files).flat().sort(), [...allowed].sort());
    assert(!JSON.stringify(result).includes('DUMMY_SECRET_VALUE'));
    assert(!JSON.stringify(result).includes('OUT_OF_SCOPE_VALUE'));
    for (const file of allowed) assert(result.diffs[file].includes('+PUBLIC_CHANGE'));
  }
  git('reset', '--hard', 'HEAD');
  assert.deepStrictEqual(getGitContext(root, 'diff').diffs, {});
  console.log('PASS: secret diffs excluded in first, middle, last and only positions');
}

main().catch(error => { console.error(error); process.exitCode = 1; })
  .finally(() => fs.rmSync(root, { recursive: true, force: true }));
