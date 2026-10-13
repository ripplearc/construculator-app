// Run with: node --test scripts/golden/classify.test.mjs
import assert from 'node:assert/strict';
import { test } from 'node:test';

import { classify } from './classify.mjs';

test('an atom is classified into its kind', () => {
  assert.deepEqual(classify("r.value==='410.67ft²'"), { kind: 'value', equals: '410.67ft²' });
  assert.deepEqual(classify('!r.tapeGroup[2]'), { kind: 'tapeBracketAt', index: 2, equals: false });
});

test('&& binds tighter than ||, so a||b&&c reads as any(a, all(b, c))', () => {
  assert.deepEqual(classify("r.value==='a'||r.label==='b'&&r.system==='c'"), {
    kind: 'any',
    checks: [
      { kind: 'value', equals: 'a' },
      { kind: 'all', checks: [{ kind: 'label', equals: 'b' }, { kind: 'system', equals: 'c' }] },
    ],
  });
  assert.deepEqual(classify("r.value==='a'&&r.label==='b'||r.system==='c'"), {
    kind: 'any',
    checks: [
      { kind: 'all', checks: [{ kind: 'value', equals: 'a' }, { kind: 'label', equals: 'b' }] },
      { kind: 'system', equals: 'c' },
    ],
  });
});

test('brackets override the precedence', () => {
  assert.deepEqual(classify("(r.value==='a'||r.label==='b')&&r.system==='c'"), {
    kind: 'all',
    checks: [
      { kind: 'any', checks: [{ kind: 'value', equals: 'a' }, { kind: 'label', equals: 'b' }] },
      { kind: 'system', equals: 'c' },
    ],
  });
});

test('a shape the classifier does not know is null, through && too', () => {
  assert.equal(classify('document.querySelectorAll(".x").length===2'), null);
  assert.equal(classify("r.value==='a'&&document.body.offsetWidth>0"), null);
});

test('spaces outside string literals are ignored, inside them kept', () => {
  assert.deepEqual(classify("r.strip[0] === 'Area: 410.67ft²'"), { kind: 'stripAt', index: 0, equals: 'Area: 410.67ft²' });
});
