#!/usr/bin/env node

const { execSync } = require('child_process');
const path = require('path');

console.log('🚀 bigpowers — setting up...\n');

try {
  const rootDir = path.dirname(path.dirname(__filename));
  
  console.log('Syncing skills...');
  execSync('bash scripts/sync-skills.sh', { 
    cwd: rootDir,
    stdio: 'inherit' 
  });
  
  console.log('\nRunning installation...');
  execSync('bash scripts/install.sh', { 
    cwd: rootDir,
    stdio: 'inherit' 
  });
  
  console.log('\n✅ bigpowers setup complete!\n');
} catch (error) {
  console.error('\n❌ Setup failed:', error.message);
  process.exit(1);
}
