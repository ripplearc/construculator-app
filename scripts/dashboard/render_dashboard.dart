// Assembles both views into one self-contained static HTML page.
//
// The page ships no script and fetches nothing: every value is inlined at build
// time. That is what lets it be published as a plain file to gh-pages and still
// render offline, and it is why the charts are SVG rather than a chart library.

import 'dashboard_styles.dart';
import 'e2e_data.dart';
import 'render_chart.dart';
import 'system_health_data.dart';
import 'trend_series.dart';

/// Renders the whole dashboard as one HTML document.
String renderDashboard({
  required List<SystemHealthGroup> systemHealth,
  required List<E2eGroup> e2e,
  required String generatedAt,
}) {
  return '<!doctype html>\n'
      '<html lang="en">\n'
      '<head>\n'
      '<meta charset="utf-8">\n'
      '<meta name="viewport" content="width=device-width, initial-scale=1">\n'
      '<title>Trend Dashboard</title>\n'
      '<style>$dashboardStyles</style>\n'
      '</head>\n'
      '<body>\n'
      '<header>\n'
      '<h1>Trend Dashboard</h1>\n'
      '<p class="muted">Lab measurement and CUJ suite results over time. '
      'Generated ${escapeMarkup(generatedAt)}.</p>\n'
      '<nav><a href="#system-health">System health</a>'
      '<a href="#e2e">E2E suite</a></nav>\n'
      '</header>\n'
      '${_systemHealthSection(systemHealth)}'
      '${_e2eSection(e2e)}'
      '$_footer'
      '</body>\n</html>\n';
}

String _systemHealthSection(List<SystemHealthGroup> groups) {
  if (groups.isEmpty) {
    return _section(
      'system-health',
      'System health',
      _empty('No performance runs have been recorded yet.'),
    );
  }
  final StringBuffer body = StringBuffer();
  for (final SystemHealthGroup group in groups) {
    body
      ..write('<h3>Journey: ${escapeMarkup(group.journey)}</h3>')
      ..write(_chartGrid(group.metrics));
  }
  return _section('system-health', 'System health', body.toString());
}

String _e2eSection(List<E2eGroup> groups) {
  if (groups.isEmpty) {
    return _section(
      'e2e',
      'E2E suite',
      _empty('No CUJ runs have been recorded yet.'),
    );
  }
  final StringBuffer body = StringBuffer();
  for (final E2eGroup group in groups) {
    body
      ..write('<h3>Suite: ${escapeMarkup(group.suite)}</h3>')
      ..write(_chartGrid(group.metrics))
      ..write(_cujTable(group.cujs));
  }
  return _section('e2e', 'E2E suite', body.toString());
}

String _section(String id, String heading, String body) {
  return '<section id="$id">\n<h2>${escapeMarkup(heading)}</h2>\n$body\n'
      '</section>\n';
}

String _chartGrid(List<MetricSeries> metrics) {
  final StringBuffer cards = StringBuffer();
  for (final MetricSeries metric in metrics) {
    cards.write(
      '<figure class="card">'
      '<figcaption><span class="label">${escapeMarkup(metric.label)}</span>'
      '<span class="latest">${_latest(metric)}</span></figcaption>'
      '${lineChartSvg(metric)}'
      '</figure>',
    );
  }
  return '<div class="grid">$cards</div>';
}

/// Shows the most recent recorded value as the card's headline figure.
String _latest(MetricSeries metric) {
  for (final SeriesPoint point in metric.points.reversed) {
    final double? value = point.value;
    if (value != null) {
      return '${escapeMarkup(formatValue(value))} '
          '<span class="unit-inline">${escapeMarkup(metric.unit)}</span>';
    }
  }
  return '<span class="muted">not recorded</span>';
}

String _cujTable(List<CujSummary> cujs) {
  if (cujs.isEmpty) {
    return _empty('No per-CUJ results have been recorded yet.');
  }
  final StringBuffer rows = StringBuffer();
  for (final CujSummary cuj in cujs) {
    rows.write(
      '<tr>'
      '<td>${escapeMarkup(cuj.name)}</td>'
      '<td class="num">${cuj.runs}</td>'
      '<td class="num">${cuj.failures}</td>'
      '<td class="num">${cuj.flakes}</td>'
      '<td>${_statusBadge(cuj.lastStatus)}</td>'
      '<td>${sparklineSvg(cuj.failuresPerRun)}</td>'
      '</tr>',
    );
  }
  return '<div class="scroll"><table>'
      '<caption>Per-CUJ results across every recorded run</caption>'
      '<thead><tr><th>CUJ</th><th class="num">Runs</th>'
      '<th class="num">Failures</th><th class="num">Flakes</th>'
      '<th>Last run</th><th>Failures over time</th></tr></thead>'
      '<tbody>$rows</tbody></table></div>';
}

/// Renders a status as a coloured dot beside its name.
///
/// The word carries the meaning and stays in body ink; the dot is a secondary
/// cue, so the status never depends on colour alone.
String _statusBadge(String status) {
  const Map<String, String> tokens = <String, String>{
    'passed': 'good',
    'flaked': 'warning',
    'failed': 'critical',
  };
  final String token = tokens[status] ?? 'muted';
  return '<span class="badge"><span class="dot dot-$token"></span>'
      '${escapeMarkup(status)}</span>';
}

String _empty(String message) => '<p class="empty">${escapeMarkup(message)}</p>';

const String _footer = '<footer>\n'
    '<h2>Reading this page</h2>\n'
    '<p><strong>Pass rate counts a flaked case as a pass</strong>, because '
    'that is what CI reports when a retry rescues a run. Flake rate is what '
    'that number hides, so read the two together: a pass rate near 100% with a '
    'rising flake rate is a suite losing trustworthiness, not a healthy one.</p>\n'
    '<p><strong>Baselines are not recorded yet.</strong> A chart shows a dashed '
    'baseline only once one exists in the store for that journey; until then no '
    'threshold is drawn, rather than a guessed one.</p>\n'
    '<p><strong>TTID has no producer yet.</strong> The performance harness '
    'records startup as cold and warm start and emits no separate TTID field, '
    'so that chart stays empty until it does.</p>\n'
    '<p class="muted">Sources: the perf-data and e2e-data branches. Each run '
    'is archived there; this page is a rendering of them, not the record '
    'itself.</p>\n'
    '</footer>\n';
