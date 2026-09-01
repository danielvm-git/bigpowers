#!/usr/bin/env node
// bigpowers init — provision the CURRENT project (cwd) for skill tooling.
// story: BUG-2026-08-31-pi-scripts-provisioning (#116)
//
// Package installs (pi install npm:bigpowers, npm i -g, npx) register skills
// but never provision a project-local scripts/ tree — pi's package contract
// has no resource type for project files and no lifecycle script runs — so
// SKILL.md commands (`bash scripts/*.sh`) and `→ verify:` gates fail in every
// consumer project. `bigpowers init` (or `npx bigpowers init`) links the
// package's scripts/ into the project and scaffolds specs/{bugs,verifications}.

'use strict';

const path = require('path');

const ROOT = path.dirname(path.dirname(__filename));
const { initProject, initProjectRemove } = require('../scripts/lib/install-helpers.js');

if (process.argv.includes('--remove')) {
  initProjectRemove(ROOT);
  console.log('bigpowers init --remove: removed the managed scripts/ link');
  console.log('  (and specs/ scaffolding dirs only where untouched).');
  process.exit(0);
}

try {
  const result = initProject(ROOT);
  if (result.skipped === 'cwd-is-package') {
    console.log('bigpowers init: already inside the bigpowers package — nothing to provision.');
  } else {
    console.log('bigpowers init: linked scripts/ → package scripts tree.');
    console.log('bigpowers init: ensured specs/bugs/ + specs/verifications/ scaffolding.');
    console.log('Skill commands and verify gates (fix-bug, verify-work, wire-ci, …) now resolve here.');
  }
} catch (e) {
  // e.g. Refusing to replace a user-owned scripts/ — surface it, don't stack-trace.
  console.error(`bigpowers init: ${e.message}`);
  process.exit(1);
}
