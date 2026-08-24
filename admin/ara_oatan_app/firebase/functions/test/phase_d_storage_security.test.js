'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');

describe('phase_d_storage_security', () => {
  const rulesPath = path.join(
    __dirname,
    '..',
    '..',
    '..',
    '..',
    'mndob-main',
    'firebase',
    'storage.rules',
  );
  const rules = fs.readFileSync(rulesPath, 'utf8');

  it('users path uses server-enforced country scope via Firestore lookup', () => {
    assert.match(rules, /match \/users\/\{userId\}\/\{allPaths=\*\*\}/);
    assert.match(rules, /canReadUserUploads\(userId\)/);
    assert.match(rules, /countriesMatchDriver\(userId\)/);
    assert.match(rules, /firestore\.get\(/);
    assert.match(rules, /request\.auth\.uid == userId/);
    assert.match(rules, /isSuperAdmin\(\)/);
    assert.doesNotMatch(rules, /isPanelWriter\(\)[\s\S]*allow read: if signedIn/);
  });

  it('owner write validates content type and size', () => {
    assert.match(rules, /validUserUpload\(\)/);
    assert.match(rules, /request\.resource\.contentType/);
    assert.match(rules, /request\.resource\.size <= 15 \* 1024 \* 1024/);
    assert.match(rules, /application\/pdf/);
  });

  it('default deny catch-all', () => {
    assert.match(rules, /match \/\{allPaths=\*\*\}[\s\S]*allow read, create, update, delete: if false/);
  });

  it('anonymous/public denied by default catch-all', () => {
    const tail = rules.slice(rules.lastIndexOf('match /{allPaths=**}'));
    assert.ok(tail.includes('if false'));
  });
});
