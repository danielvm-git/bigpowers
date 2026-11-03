// story: BUG-2026-11-03-cli-update-stale-version
// cli-version.js — read the installed version from disk, never from a require cache.
//
// `bigpowers update` runs `npm install -g bigpowers@latest` *inside a running
// process*. The package.json that process requires at startup is cached by Node,
// so a later `require(ROOT + '/package.json')` (from bin/setup.js, required after
// the reinstall) returns the version the process booted with. The banner then
// claims v2.88.5 while v2.92.0 is what was just installed.
//
// readFileSync always sees the new file, so every user-facing version string
// goes through here.

'use strict';

const fs = require('fs');
const path = require('path');

/** Version of the package rooted at `root`, read fresh from disk. */
function readPackageVersion(root) {
  try {
    const text = fs.readFileSync(path.join(root, 'package.json'), 'utf8');
    return JSON.parse(text).version || 'unknown';
  } catch {
    return 'unknown';
  }
}

module.exports = { readPackageVersion };
