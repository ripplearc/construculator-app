// The dashboard's palette and layout tokens.
//
// Held apart from page assembly because it is a static asset, not logic: the
// colour values are the data-viz reference palette, validated against both the
// light and dark chart surfaces rather than picked by eye.

/// Light is the default palette; the dark steps are chosen for the dark
/// surface rather than being an automatic inversion of the light ones.
const String dashboardStyles = '''
:root {
  color-scheme: light;
  --surface: #fcfcfb; --plane: #f9f9f7;
  --text: #0b0b0b; --text-2: #52514e; --muted: #898781;
  --grid: #e1e0d9; --axis: #c3c2b7; --border: rgba(11,11,11,0.10);
  --series: #2a78d6;
  --status-good: #0ca30c; --status-warning: #fab219; --status-critical: #d03b3b;
}
@media (prefers-color-scheme: dark) {
  :root:not([data-theme="light"]) {
    color-scheme: dark;
    --surface: #1a1a19; --plane: #0d0d0d;
    --text: #ffffff; --text-2: #c3c2b7; --muted: #898781;
    --grid: #2c2c2a; --axis: #383835; --border: rgba(255,255,255,0.10);
    --series: #3987e5;
  }
}
:root[data-theme="dark"] {
  color-scheme: dark;
  --surface: #1a1a19; --plane: #0d0d0d;
  --text: #ffffff; --text-2: #c3c2b7; --muted: #898781;
  --grid: #2c2c2a; --axis: #383835; --border: rgba(255,255,255,0.10);
  --series: #3987e5;
}
* { box-sizing: border-box; }
body {
  margin: 0; padding: 32px 24px 64px;
  background: var(--plane); color: var(--text);
  font-family: system-ui, -apple-system, "Segoe UI", sans-serif;
  line-height: 1.5;
}
header, section, footer { max-width: 1200px; margin: 0 auto; }
h1 { font-size: 1.6rem; margin: 0 0 4px; }
h2 { font-size: 1.2rem; margin: 40px 0 4px; }
h3 { font-size: 0.95rem; font-weight: 600; color: var(--text-2); margin: 24px 0 12px; }
nav { display: flex; gap: 16px; margin-top: 12px; }
nav a { color: var(--series); text-decoration: none; font-weight: 600; }
nav a:hover, nav a:focus { text-decoration: underline; }
.muted { color: var(--muted); }
.grid {
  display: grid; gap: 16px;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
}
.card {
  margin: 0; padding: 12px; background: var(--surface);
  border: 1px solid var(--border); border-radius: 8px;
}
figcaption { display: flex; justify-content: space-between; align-items: baseline; gap: 8px; }
.label { font-weight: 600; font-size: 0.9rem; }
.latest { font-size: 1.1rem; font-variant-numeric: tabular-nums; }
.unit-inline { font-size: 0.75rem; color: var(--muted); }
.chart { width: 100%; height: auto; display: block; margin-top: 8px; }
.gridline { stroke: var(--grid); stroke-width: 1; }
.line { fill: none; stroke: var(--series); stroke-width: 2; stroke-linejoin: round; }
.marker { fill: var(--series); stroke: var(--surface); stroke-width: 2; }
.baseline { stroke: var(--axis); stroke-width: 2; stroke-dasharray: 5 4; }
.tick { fill: var(--muted); font-size: 10px; font-variant-numeric: tabular-nums; }
.unit { fill: var(--muted); font-size: 10px; }
.empty {
  margin: 0; padding: 24px; text-align: center; color: var(--muted);
  background: var(--surface); border: 1px dashed var(--border); border-radius: 8px;
}
.scroll { overflow-x: auto; margin-top: 16px; }
table { border-collapse: collapse; width: 100%; min-width: 560px; background: var(--surface); }
caption { text-align: left; color: var(--muted); font-size: 0.85rem; padding: 8px 0; }
th, td { text-align: left; padding: 8px 12px; border-bottom: 1px solid var(--border); }
th { font-size: 0.8rem; color: var(--text-2); text-transform: uppercase; letter-spacing: 0.03em; }
.num { text-align: right; font-variant-numeric: tabular-nums; }
.badge { display: inline-flex; align-items: center; gap: 6px; }
.dot { width: 8px; height: 8px; border-radius: 50%; flex: none; }
.dot-good { background: var(--status-good); }
.dot-warning { background: var(--status-warning); }
.dot-critical { background: var(--status-critical); }
.dot-muted { background: var(--muted); }
.sparkline { display: block; width: 72px; height: 18px; }
footer { margin-top: 56px; padding-top: 16px; border-top: 1px solid var(--border); }
footer p { max-width: 70ch; color: var(--text-2); font-size: 0.9rem; }
''';
