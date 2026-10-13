// Exports the calculator prototype's SCENARIOS array to test/golden/scenarios.json
// for the golden replayer (CA-1075 H1).
//
// Usage: node scripts/golden/export_scenarios.mjs <prototype.html>
//
// The file holds every scenario's steps and checkpoints, each checkpoint's
// JavaScript source, and the typed check it was classified into. A checkpoint
// is the expected snapshot value after the steps before it — the prototype
// asserts them inline — so the Dart runner (H2) replays the steps and
// evaluates the checks against its own snapshot.
//
// The prototype's checkpoints are inline `f: r => …` closures over the
// snapshot, not named helpers, so "porting the checks" means recognising the
// handful of shapes they take. Anything the classifier does not recognise is
// kept as `{kind: "js", source}` so the runner can report it as unported
// rather than silently passing it.
import { execFileSync } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';

import { classify } from './classify.mjs';

const [, , htmlPath] = process.argv;
if (!htmlPath) {
  console.error('usage: node export_scenarios.mjs <prototype.html>');
  process.exit(2);
}
const html = fs.readFileSync(htmlPath, 'utf8');

// The prototype commit the file is exported from, so a stale export is
// visible: the runner prints it, and a re-export after the prototype moves
// shows up as a one-line diff in the header.
function commitOf(file) {
  try {
    return execFileSync('git', ['rev-parse', 'HEAD'], {
      cwd: path.dirname(path.resolve(file)), encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'],
    }).trim();
  } catch {
    console.error(`warning: ${file} is not in a git checkout, sourceCommit is null`);
    return null;
  }
}
const sourceCommit = commitOf(htmlPath);

// ── 1. Evaluate the SCENARIOS array literal with stubbed globals ────────────
const start = html.indexOf('const SCENARIOS = [');
const end = html.indexOf('\n];', start) + 3;
const arraySource = html.slice(start, end).replace('const SCENARIOS = [', '[');
const sandbox = {
  J: JSON.stringify,
  histAfterSaves: (n) => ({ histAfterSaves: n }),
  document: {}, state: {}, Engine: {}, REPLAY: {}, getComputedStyle: () => ({}),
  render: () => {}, persist: () => {},
};
const scenarios = vm.runInNewContext(arraySource, sandbox);

function checkOf(fn) {
  const source = fn.toString();
  const body = source.replace(/^\(?r\)?\s*=>\s*/, '');
  const expression = body.startsWith('{') ? null : body;
  const check = expression ? classify(expression) : null;
  return { source, check: check || { kind: 'js', source } };
}

// ── 2. Serialise steps ──────────────────────────────────────────────────────
function serialiseStep(step) {
  if (step.c !== undefined) {
    const { source, check } = checkOf(step.f);
    return { kind: 'checkpoint', description: step.c, check, source };
  }
  // The same precedence as the prototype's REPLAY.run, in case a step ever
  // carries two action keys.
  if (step.k) return { kind: 'key', key: step.k };
  if (step.mkey) return { kind: 'sheetKey', key: step.mkey };
  if (step.accept) return { kind: 'accept', prefix: step.accept };
  if (step.toggle) return { kind: 'toggle' };
  if (step.collapse) return { kind: 'collapse' };
  if (step.expand) return { kind: 'expand' };
  if (step.swipe) return { kind: 'swipe', direction: step.swipe, on: step.on || null };
  if (step.click) return { kind: 'click', selector: step.click, withText: step.withText || null };
  if (step.tapChip) return { kind: 'tapChip', prefix: step.tapChip };
  if (step.js) return { kind: 'js', source: step.js.toString() };
  return { kind: 'unknown', raw: JSON.stringify(step) };
}

const exported = scenarios.map((s) => ({
  id: s.id, category: s.cat, name: s.name, keys: s.how || null, expected: s.expected || null,
  steps: s.steps.map(serialiseStep),
}));

const outPath = path.resolve('test/golden/scenarios.json');
fs.mkdirSync(path.dirname(outPath), { recursive: true });
fs.writeFileSync(outPath, JSON.stringify({ source: path.basename(htmlPath), sourceCommit, count: exported.length, scenarios: exported }, null, 1) + '\n');

const checkpoints = exported.flatMap((s) => s.steps).filter((st) => st.kind === 'checkpoint');
const unported = checkpoints.filter((st) => st.check.kind === 'js');
const kinds = {};
for (const st of checkpoints) for (const k of flattenKinds(st.check)) kinds[k] = (kinds[k] || 0) + 1;
function flattenKinds(check) {
  if (check.kind === 'all' || check.kind === 'any') return check.checks.flatMap(flattenKinds);
  if (check.kind === 'not') return flattenKinds(check.check);
  return [check.kind];
}
console.log(`${exported.length} scenarios, ${checkpoints.length} checkpoints, ${unported.length} left as js, from ${sourceCommit ?? 'an unknown commit'}`);
console.log(Object.entries(kinds).sort((a, b) => b[1] - a[1]).map(([k, n]) => `${k}: ${n}`).join('\n'));
