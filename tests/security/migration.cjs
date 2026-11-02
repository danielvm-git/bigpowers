// story: e44s03 e44s06
const assert = require('assert');
const fs = require('fs');
const os = require('os');
const path = require('path');
const { execFileSync, spawnSync } = require('child_process');

const root = fs.mkdtempSync(path.join(os.tmpdir(), 'bp-migration-'));
const repo = path.resolve(__dirname, '../..');
const project = path.join(root, 'project');
const specs = path.join(project, 'specs');
const marker = path.join(root, 'executed-marker');
const git = (...args) => execFileSync('git', args, { cwd: project, stdio: 'pipe' });
function stamp(version) {
  fs.writeFileSync(path.join(specs, 'state.yaml'),
    `bigpowers_version: ${JSON.stringify(version)}\nactive_flow: null\n`);
  git('add', '.');
  git('-c', 'user.name=Test', '-c', 'user.email=test@example.invalid',
    'commit', '--allow-empty', '-qm', 'fixture');
}
function preview(script) {
  const before = fs.readFileSync(path.join(specs, 'state.yaml'), 'utf8');
  const result = spawnSync('bash', [script, '--project', project, '--dry-run'],
    { cwd: project, encoding: 'utf8' });
  assert(!result.error, String(result.error));
  assert(!fs.existsSync(marker), 'dry run executed version metadata');
  assert.strictEqual(fs.readFileSync(path.join(specs, 'state.yaml'), 'utf8'), before);
  assert.deepStrictEqual(fs.readdirSync(specs), ['state.yaml'], 'dry run wrote files');
  return result;
}
function copyFile(relative, destination) {
  const target = path.join(destination, relative);
  fs.mkdirSync(path.dirname(target), { recursive: true });
  fs.copyFileSync(path.join(repo, relative), target);
}
function installFixture(destination) {
  for (const relative of ['package.json', 'scripts/migrate-version.sh',
    'scripts/lib/python-env.sh', ...['common', 'plan', 'run', 'post', 'execute', 'transforms']
      .map(name => `scripts/lib/migrate-version-${name}.sh`)]) copyFile(relative, destination);
  const migrations = path.join(destination, 'specs/migrations');
  fs.mkdirSync(migrations, { recursive: true });
  fs.writeFileSync(path.join(migrations, 'registry.okf.md'),
    '---\nmigrations:\n  - id: test\n    since_version: "2.80.0"\n    order: 1\n---\n');
  fs.writeFileSync(path.join(migrations, 'test.okf.md'),
    '---\ntransforms: []\nactions_needed: []\n---\n');
  return path.join(destination, 'scripts/migrate-version.sh');
}
try {
  fs.mkdirSync(specs, { recursive: true });
  git('init', '-q', '-b', 'main');
  const script = installFixture(path.join(root, 'installation'));
  stamp(`0.0.0'; open('${marker}', 'w').write('DUMMY'); #`);
  const hostile = preview(script);
  assert.notStrictEqual(hostile.status, 0, 'invalid version must fail closed');
  assert(/invalid.*version/i.test(hostile.stderr), hostile.stderr);
  for (const version of ['1.0.0', '2.0.0', '2.20.0', '2.20.0-rc.1+build.2']) {
    stamp(version);
    const result = preview(script);
    assert.strictEqual(result.status, 0, result.stderr);
    assert(result.stdout.includes(`Detected version: ${version}`), result.stdout);
  }
  // The same data boundary applies to legitimate installation/project paths.
  const installation = path.join(root, "install's directory");
  const quotedScript = installFixture(installation);
  stamp('1.0.0');
  const quotedProject = path.join(root, "project's directory");
  fs.symlinkSync(project, quotedProject, 'dir');
  const result = spawnSync('bash', [quotedScript,
    '--project', quotedProject, '--dry-run'], { encoding: 'utf8' });
  assert.strictEqual(result.status, 0, result.stderr);
  assert(result.stdout.includes('Detected version: 1.0.0'), result.stdout);
  assert(result.stdout.includes('Transforms preview:'), result.stdout);
  assert(result.stdout.includes('-- test: test --'), result.stdout);
  assert(!result.stdout.includes('installed=unknown'), result.stdout);
  console.log('PASS: migration preview rejects executable stamps and supports quoted paths');
} finally { fs.rmSync(root, { recursive: true, force: true }); }
