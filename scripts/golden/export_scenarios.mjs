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
import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';

const [, , htmlPath] = process.argv;
if (!htmlPath) {
  console.error('usage: node export_scenarios.mjs <prototype.html>');
  process.exit(2);
}
const html = fs.readFileSync(htmlPath, 'utf8');

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

// ── 2. Classify a checkpoint closure into a typed check ─────────────────────
// A string literal in either quote, captured with its quotes: the prototype
// writes "isn't complete" and "38\u00b030'" in double quotes.
const STR = String.raw`('(?:[^'\\]|\\.)*'|"(?:[^"\\]|\\.)*")`;
const NUM = String.raw`(-?\d+(?:\.\d+)?)`;
const unquote = (literal) => {
  const body = literal.slice(1, -1);
  if (literal[0] === '"') return JSON.parse('"' + body + '"');
  return JSON.parse('"' + body.replace(/"/g, '\\"').replace(/\\'/g, "'") + '"');
};
const atoms = [
  [new RegExp(`^r\\.value===${STR}$`), (m) => ({ kind: 'value', equals: unquote(m[1]) })],
  [new RegExp(`^r\\.value\\.startsWith\\(${STR}\\)$`), (m) => ({ kind: 'valueStartsWith', prefix: unquote(m[1]) })],
  [new RegExp(`^r\\.value\\.includes\\(${STR}\\)$`), (m) => ({ kind: 'valueIncludes', text: unquote(m[1]) })],
  [new RegExp(`^r\\.label===${STR}$`), (m) => ({ kind: 'label', equals: unquote(m[1]) })],
  [new RegExp(`^r\\.label\\.startsWith\\(${STR}\\)$`), (m) => ({ kind: 'labelStartsWith', prefix: unquote(m[1]) })],
  [new RegExp(`^r\\.label\\.includes\\(${STR}\\)$`), (m) => ({ kind: 'labelIncludes', text: unquote(m[1]) })],
  [new RegExp(`^r\\.tape\\[(\\d+)\\]===${STR}$`), (m) => ({ kind: 'tapeAt', index: +m[1], equals: unquote(m[2]) })],
  [new RegExp(`^r\\.tape\\[(\\d+)\\]\\.startsWith\\(${STR}\\)$`), (m) => ({ kind: 'tapeAtStartsWith', index: +m[1], prefix: unquote(m[2]) })],
  [new RegExp(`^J\\(r\\.tape\\)===J\\((\\[.*\\])\\)$`), (m) => ({ kind: 'tape', equals: vm.runInNewContext(m[1], {}) })],
  [new RegExp(`^r\\.tape\\.length===${NUM}$`), (m) => ({ kind: 'tapeLength', equals: +m[1] })],
  [new RegExp(`^r\\.strip\\[(\\d+)\\]===${STR}$`), (m) => ({ kind: 'stripAt', index: +m[1], equals: unquote(m[2]) })],
  [new RegExp(`^r\\.strip\\[(\\d+)\\]\\.startsWith\\(${STR}\\)$`), (m) => ({ kind: 'stripAtStartsWith', index: +m[1], prefix: unquote(m[2]) })],
  [new RegExp(`^r\\.strip\\[(\\d+)\\]\\.includes\\(${STR}\\)$`), (m) => ({ kind: 'stripAtIncludes', index: +m[1], text: unquote(m[2]) })],
  [new RegExp(`^J\\(r\\.strip\\)===J\\((\\[.*\\])\\)$`), (m) => ({ kind: 'strip', equals: vm.runInNewContext(m[1], {}) })],
  [new RegExp(`^r\\.strip\\.length===${NUM}$`), (m) => ({ kind: 'stripLength', equals: +m[1] })],
  [new RegExp(`^r\\.strip\\.length>${NUM}$`), (m) => ({ kind: 'stripLengthAbove', above: +m[1] })],
  [new RegExp(`^r\\.strip\\.some\\(x=>x\\.startsWith\\(${STR}\\)\\)$`), (m) => ({ kind: 'stripAnyStartsWith', prefix: unquote(m[1]) })],
  [new RegExp(`^r\\.strip\\.some\\(x=>x\\.includes\\(${STR}\\)\\)$`), (m) => ({ kind: 'stripAnyIncludes', text: unquote(m[1]) })],
  [new RegExp(`^r\\.strip\\.some\\(x=>x\\.endsWith\\(${STR}\\)\\)$`), (m) => ({ kind: 'stripAnyEndsWith', suffix: unquote(m[1]) })],
  [new RegExp(`^r\\.strip2\\[(\\d+)\\]===${STR}$`), (m) => ({ kind: 'strip2At', index: +m[1], equals: unquote(m[2]) })],
  [new RegExp(`^J\\(r\\.strip2\\)===J\\((\\[.*\\])\\)$`), (m) => ({ kind: 'strip2', equals: vm.runInNewContext(m[1], {}) })],
  [new RegExp(`^r\\.depKey===${STR}$`), (m) => ({ kind: 'depKey', equals: unquote(m[1]) })],
  [new RegExp(`^r\\.depKey\\.startsWith\\(${STR}\\)$`), (m) => ({ kind: 'depKeyStartsWith', prefix: unquote(m[1]) })],
  [new RegExp(`^r\\.depKey\\.includes\\(${STR}\\)$`), (m) => ({ kind: 'depKeyIncludes', text: unquote(m[1]) })],
  [new RegExp(`^r\\.toast\\.includes\\(${STR}\\)$`), (m) => ({ kind: 'toastIncludes', text: unquote(m[1]) })],
  [new RegExp(`^r\\.atoast\\.includes\\(${STR}\\)$`), (m) => ({ kind: 'actionToastIncludes', text: unquote(m[1]) })],
  [new RegExp(`^r\\.hint\\.includes\\(${STR}\\)$`), (m) => ({ kind: 'hintIncludes', text: unquote(m[1]) })],
  [new RegExp(`^r\\.eqLabel===${STR}$`), (m) => ({ kind: 'equalsLabel', equals: unquote(m[1]) })],
  [new RegExp(`^r\\.more===${STR}$`), (m) => ({ kind: 'more', equals: unquote(m[1]) })],
  [new RegExp(`^r\\.histStage===${NUM}$`), (m) => ({ kind: 'historyStage', equals: +m[1] })],
  [new RegExp(`^r\\.histCount===histAfterSaves\\(${NUM}\\)$`), (m) => ({ kind: 'historyCountAfterSaves', saves: +m[1] })],
  [/^r\.groupOpen===(true|false)$/, (m) => ({ kind: 'bracketOpen', equals: m[1] === 'true' })],
  [/^r\.groupOpen$/, () => ({ kind: 'bracketOpen', equals: true })],
  [/^!r\.groupOpen$/, () => ({ kind: 'bracketOpen', equals: false })],
  [/^!!r\.toast$/, () => ({ kind: 'toastShown', equals: true })],
  [/^!r\.toast$/, () => ({ kind: 'toastShown', equals: false })],
  [/^!!r\.atoast$/, () => ({ kind: 'actionToastShown', equals: true })],
  [/^!r\.atoast$/, () => ({ kind: 'actionToastShown', equals: false })],
  [/^!!r\.depKey$/, () => ({ kind: 'depKeyShown', equals: true })],
  [/^!r\.depKey$/, () => ({ kind: 'depKeyShown', equals: false })],
  [/^!!r\.hint$/, () => ({ kind: 'hintShown', equals: true })],
  [/^!r\.hint$/, () => ({ kind: 'hintShown', equals: false })],
  [/^!r\.strip\.length$/, () => ({ kind: 'stripLength', equals: 0 })],
  [new RegExp(`^r\\.tapeKinds\\[(\\d+)\\]===${STR}$`), (m) => ({ kind: 'tapeKindAt', index: +m[1], equals: unquote(m[2]) })],
  [new RegExp(`^J\\(r\\.tapeKinds\\)===J\\((\\[.*\\])\\)$`), (m) => ({ kind: 'tapeKinds', equals: vm.runInNewContext(m[1], {}) })],
  [new RegExp(`^r\\.tapeGroupOpen\\[(\\d+)\\]===(true|false)$`), (m) => ({ kind: 'tapeBracketOpenAt', index: +m[1], equals: m[2] === 'true' })],
  [new RegExp(`^r\\.system===${STR}$`), (m) => ({ kind: 'system', equals: unquote(m[1]) })],
  [new RegExp(`^r\\.unitToggleLabel===${STR}$`), (m) => ({ kind: 'unitToggleLabel', equals: unquote(m[1]) })],
  [/^r\.unitToggleShown===(true|false)$/, (m) => ({ kind: 'unitToggleShown', equals: m[1] === 'true' })],
  [new RegExp(`^r\\.strip\\.some\\(x=>x===${STR}\\)$`), (m) => ({ kind: 'stripAny', equals: unquote(m[1]) })],
  [new RegExp(`^r\\.tape\\.some\\(x=>x===${STR}\\)$`), (m) => ({ kind: 'tapeAny', equals: unquote(m[1]) })],
  [new RegExp(`^r\\.tape\\[r\\.tape\\.length-1\\]===${STR}$`), (m) => ({ kind: 'tapeLast', equals: unquote(m[1]) })],
  [new RegExp(`^r\\.tape\\.join\\(${STR}\\)===${STR}$`), (m) => ({ kind: 'tapeJoined', separator: unquote(m[1]), equals: unquote(m[2]) })],
  [/^r\.depKey===null$/, () => ({ kind: 'depKeyShown', equals: false })],
  [/^r\.atoast===null$/, () => ({ kind: 'actionToastShown', equals: false })],
  [/^r\.toast===null$/, () => ({ kind: 'toastShown', equals: false })],
  [new RegExp(`^r\\.mem===${STR}$`), (m) => ({ kind: 'memory', equals: unquote(m[1]) })],
  [new RegExp(`^r\\.fkGroup===${STR}$`), (m) => ({ kind: 'functionGroup', equals: unquote(m[1]) })],
  [new RegExp(`^r\\.histBlocks\\.length===${NUM}$`), (m) => ({ kind: 'historyBlocks', equals: +m[1] })],
  [/^r\.sheetHidden$/, () => ({ kind: 'sheetHidden', equals: true })],
  [/^!r\.sheetHidden$/, () => ({ kind: 'sheetHidden', equals: false })],
  [new RegExp(`^r\\.tapeGroup\\[(\\d+)\\]$`), (m) => ({ kind: 'tapeBracketAt', index: +m[1], equals: true })],
  [new RegExp(`^!r\\.tapeGroup\\[(\\d+)\\]$`), (m) => ({ kind: 'tapeBracketAt', index: +m[1], equals: false })],
  [new RegExp(`^!r\\.tapeGroupOpen\\[(\\d+)\\]$`), (m) => ({ kind: 'tapeBracketOpenAt', index: +m[1], equals: false })],
  [new RegExp(`^r\\.tapeGroupOpen\\[(\\d+)\\]$`), (m) => ({ kind: 'tapeBracketOpenAt', index: +m[1], equals: true })],
  [/^r\.toggle===(true|false)$/, (m) => ({ kind: 'stripToggleShown', equals: m[1] === 'true' })],
  [new RegExp(`^r\\.sizeRows\\.some\\(x=>x\\.includes\\(${STR}\\)\\)$`), (m) => ({ kind: 'sizeRowsAnyIncludes', text: unquote(m[1]) })],
  [new RegExp(`^r\\.tiles\\.some\\(x=>x\\.includes\\(${STR}\\)\\)$`), (m) => ({ kind: 'tilesAnyIncludes', text: unquote(m[1]) })],
  [new RegExp(`^r\\.strip\\.every\\(x=>x\\.startsWith\\(${STR}\\)\\|\\|x\\.startsWith\\(${STR}\\)\\)$`), (m) => ({ kind: 'stripAllStartWithAny', prefixes: [unquote(m[1]), unquote(m[2])] })],
  [/^r\.collapsed$/, () => ({ kind: 'collapsed', equals: true })],
  [new RegExp(`^r\\.tapeFrozen\\[(\\d+)\\]$`), (m) => ({ kind: 'tapeFrozenAt', index: +m[1], equals: true })],
  [new RegExp(`^!r\\.tapeFrozen\\[(\\d+)\\]$`), (m) => ({ kind: 'tapeFrozenAt', index: +m[1], equals: false })],
  [new RegExp(`^r\\.mems===${NUM}$`), (m) => ({ kind: 'memoryCount', equals: +m[1] })],
  [/^r\.moreOnScreen===(true|false)$/, (m) => ({ kind: 'overflowMarkerOnScreen', equals: m[1] === 'true' })],
  [new RegExp(`^r\\.tape\\[(\\d+)\\]$`), (m) => ({ kind: 'tapeAtPresent', index: +m[1] })],
  [new RegExp(`^r\\.strip\\[(\\d+)\\]$`), (m) => ({ kind: 'stripAtPresent', index: +m[1] })],
  [new RegExp(`^r\\.histBlocks\\[(\\d+)\\]$`), (m) => ({ kind: 'historyBlockAtPresent', index: +m[1] })],
  [new RegExp(`^r\\.histBlocks\\[(\\d+)\\]===${STR}$`), (m) => ({ kind: 'historyBlockAt', index: +m[1], equals: unquote(m[2]) })],
  [new RegExp(`^r\\.histBlocks\\[(\\d+)\\]\\.includes\\(${STR}\\)$`), (m) => ({ kind: 'historyBlockAtIncludes', index: +m[1], text: unquote(m[2]) })],
  [new RegExp(`^r\\.value\\.endsWith\\(${STR}\\)$`), (m) => ({ kind: 'valueEndsWith', suffix: unquote(m[1]) })],
  [new RegExp(`^r\\.label\\.endsWith\\(${STR}\\)$`), (m) => ({ kind: 'labelEndsWith', suffix: unquote(m[1]) })],
  [new RegExp(`^r\\.hint===${STR}$`), (m) => ({ kind: 'hint', equals: unquote(m[1]) })],
  [new RegExp(`^r\\.strip\\.includes\\(${STR}\\)$`), (m) => ({ kind: 'stripAny', equals: unquote(m[1]) })],
  [new RegExp(`^r\\.tape\\.includes\\(${STR}\\)$`), (m) => ({ kind: 'tapeAny', equals: unquote(m[1]) })],
  [/^r\.strip2===null$/, () => ({ kind: 'strip2', equals: null })],
  [/^r\.strip2!==null$/, () => ({ kind: 'not', check: { kind: 'strip2', equals: null } })],
  [new RegExp(`^r\\.strip2\\.length>${NUM}$`), (m) => ({ kind: 'strip2LengthAbove', above: +m[1] })],
  [/^r\.more===null$/, () => ({ kind: 'more', equals: null })],
  [/^r\.mem===null$/, () => ({ kind: 'memory', equals: null })],
  [new RegExp(`^r\\.histCount>${NUM}$`), (m) => ({ kind: 'historyCountAbove', above: +m[1] })],
  [new RegExp(`^r\\.histStage>=${NUM}$`), (m) => ({ kind: 'historyStageAtLeast', atLeast: +m[1] })],
  [new RegExp(`^r\\.strip\\.length>=${NUM}$`), (m) => ({ kind: 'stripLengthAbove', above: +m[1] - 1 })],
  [/^r\.unitToggleShown$/, () => ({ kind: 'unitToggleShown', equals: true })],
  [/^!r\.unitToggleShown$/, () => ({ kind: 'unitToggleShown', equals: false })],
  [new RegExp(`^r\\.strip\\.some\\(\\w+=>\\w+\\.indexOf\\(${STR}\\)===0\\)$`), (m) => ({ kind: 'stripAnyStartsWith', prefix: unquote(m[1]) })],
  [new RegExp(`^r\\.tape\\.some\\(\\w+=>\\w+\\.indexOf\\(${STR}\\)===0\\)$`), (m) => ({ kind: 'tapeAnyStartsWith', prefix: unquote(m[1]) })],
  [new RegExp(`^r\\.toast\\.startsWith\\(${STR}\\)$`), (m) => ({ kind: 'toastStartsWith', prefix: unquote(m[1]) })],
  [new RegExp(`^r\\.tape\\[(\\d+)\\]\\.includes\\(${STR}\\)$`), (m) => ({ kind: 'tapeAtIncludes', index: +m[1], text: unquote(m[2]) })],
];

// Splits a boolean expression on top-level && (or ||), respecting brackets
// and quotes, so each side can be classified on its own.
function splitTop(expr, op) {
  const parts = []; let depth = 0, quote = null, last = 0;
  for (let i = 0; i < expr.length; i++) {
    const ch = expr[i];
    if (quote) { if (ch === '\\') i++; else if (ch === quote) quote = null; continue; }
    if (ch === "'" || ch === '"') { quote = ch; continue; }
    if ('([{'.includes(ch)) depth++;
    if (')]}'.includes(ch)) depth--;
    if (depth === 0 && expr.startsWith(op, i)) { parts.push(expr.slice(last, i)); i += op.length - 1; last = i + 1; }
  }
  parts.push(expr.slice(last));
  return parts;
}

function stripOuterParens(expr) {
  let s = expr.trim();
  while (s.startsWith('(') && s.endsWith(')')) {
    let depth = 0, wraps = true;
    for (let i = 0; i < s.length; i++) {
      if (s[i] === '(') depth++;
      if (s[i] === ')') depth--;
      if (depth === 0 && i < s.length - 1) { wraps = false; break; }
    }
    if (!wraps) break;
    s = s.slice(1, -1).trim();
  }
  return s;
}

// Removes the whitespace between tokens but never inside a string literal:
// 'Area: 410.67ft²' has to survive as the prototype spells it.
function stripSpaces(expr) {
  let out = '', quote = null;
  for (let i = 0; i < expr.length; i++) {
    const ch = expr[i];
    if (quote) { out += ch; if (ch === '\\') { out += expr[++i]; } else if (ch === quote) quote = null; continue; }
    if (ch === "'" || ch === '"') { quote = ch; out += ch; continue; }
    if (!/\s/.test(ch)) out += ch;
  }
  return out;
}

function classify(expr) {
  const e = stripSpaces(stripOuterParens(expr));
  for (const [re, build] of atoms) {
    const m = e.match(re);
    if (m) return build(m);
  }
  const ands = splitTop(e, '&&');
  if (ands.length > 1) {
    const checks = ands.map(classify);
    return checks.every(Boolean) ? { kind: 'all', checks } : null;
  }
  const ors = splitTop(e, '||');
  if (ors.length > 1) {
    const checks = ors.map(classify);
    return checks.every(Boolean) ? { kind: 'any', checks } : null;
  }
  if (e.startsWith('!')) {
    const inner = classify(e.slice(1));
    if (inner) return { kind: 'not', check: inner };
  }
  return null;
}

function checkOf(fn) {
  const source = fn.toString();
  const body = source.replace(/^\(?r\)?\s*=>\s*/, '');
  const expression = body.startsWith('{') ? null : body;
  const check = expression ? classify(expression) : null;
  return { source, check: check || { kind: 'js', source } };
}

// ── 3. Serialise steps ──────────────────────────────────────────────────────
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
fs.writeFileSync(outPath, JSON.stringify({ source: path.basename(htmlPath), count: exported.length, scenarios: exported }, null, 1) + '\n');

const checkpoints = exported.flatMap((s) => s.steps).filter((st) => st.kind === 'checkpoint');
const unported = checkpoints.filter((st) => st.check.kind === 'js');
const kinds = {};
for (const st of checkpoints) for (const k of flattenKinds(st.check)) kinds[k] = (kinds[k] || 0) + 1;
function flattenKinds(check) {
  if (check.kind === 'all' || check.kind === 'any') return check.checks.flatMap(flattenKinds);
  if (check.kind === 'not') return flattenKinds(check.check);
  return [check.kind];
}
console.log(`${exported.length} scenarios, ${checkpoints.length} checkpoints, ${unported.length} left as js`);
console.log(Object.entries(kinds).sort((a, b) => b[1] - a[1]).map(([k, n]) => `${k}: ${n}`).join('\n'));
