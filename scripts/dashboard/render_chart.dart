// Renders a metric series as a standalone inline SVG line chart.
//
// Inline SVG rather than a charting library keeps the published page a single
// self-contained file with no script and no network fetch, which is what the
// ticket's "static-rendered and dependency-light" requirement asks for.
//
// Colours are referenced as CSS custom properties, never as literal hex, so the
// page's light and dark palettes both apply to the same markup.

import 'trend_series.dart';

/// Geometry of a small-multiple chart cell, in SVG user units.
const int chartWidth = 360;
const int chartHeight = 168;
const int _padLeft = 48;
const int _padRight = 14;
const int _padTop = 16;
const int _padBottom = 30;

/// Renders [series] as a line chart with an optional dashed baseline.
///
/// A series with no plottable value renders an empty state rather than an empty
/// axis, so "nothing has been recorded yet" is legible as its own answer rather
/// than looking like a chart that failed to draw.
String lineChartSvg(MetricSeries series) {
  if (!series.hasData) {
    return _emptyState(
      series.baseline == null
          ? 'No runs recorded yet'
          : 'No runs recorded yet (baseline ${formatValue(series.baseline)})',
    );
  }

  final _Scale scale = _Scale.forSeries(series);
  final StringBuffer svg = StringBuffer()
    ..write(
      '<svg class="chart" viewBox="0 0 $chartWidth $chartHeight" '
      'role="img" preserveAspectRatio="xMidYMid meet">',
    )
    ..write(_gridAndAxis(scale, series.unit));

  final double? baseline = series.baseline;
  if (baseline != null) {
    svg.write(_baseline(scale, baseline));
  }
  svg
    ..write(_segments(series, scale))
    ..write(_markers(series, scale))
    ..write(_xAxisLabels(series, scale))
    ..write('</svg>');
  return svg.toString();
}

/// Renders per-run failure counts as a bare sparkline for a table cell.
String sparklineSvg(List<int> values) {
  if (values.isEmpty) {
    return '<span class="muted">—</span>';
  }
  const int width = 72;
  const int height = 18;
  final int peak = values.fold<int>(1, (int a, int b) => a > b ? a : b);
  final StringBuffer bars = StringBuffer();
  final double slot = width / values.length;
  for (int i = 0; i < values.length; i++) {
    // A 2px surface gap between adjacent bars keeps them countable when several
    // runs in a row failed.
    final double barWidth = slot - 2 < 1 ? 1 : slot - 2;
    final double barHeight = values[i] == 0 ? 1 : height * values[i] / peak;
    final String fill = values[i] == 0 ? 'var(--grid)' : 'var(--status-critical)';
    bars.write(
      '<rect x="${_round(i * slot)}" y="${_round(height - barHeight)}" '
      'width="${_round(barWidth)}" height="${_round(barHeight)}" rx="1" '
      'fill="$fill"/>',
    );
  }
  return '<svg class="sparkline" viewBox="0 0 $width $height" role="img" '
      'aria-label="Failures per run, oldest first">$bars</svg>';
}

/// Maps series values and run indices onto chart coordinates.
class _Scale {
  _Scale({
    required this.min,
    required this.max,
    required this.pointCount,
  });

  factory _Scale.forSeries(MetricSeries series) {
    final List<double> values = series.points
        .map((SeriesPoint point) => point.value)
        .whereType<double>()
        .toList();
    final double? baseline = series.baseline;
    if (baseline != null) {
      values.add(baseline);
    }
    double min = values.reduce((double a, double b) => a < b ? a : b);
    double max = values.reduce((double a, double b) => a > b ? a : b);
    if (min == max) {
      // A flat series would otherwise divide by zero; giving it a band keeps the
      // line centred instead of pinned to an edge.
      min -= min.abs() * 0.1 + 1;
      max += max.abs() * 0.1 + 1;
    }
    return _Scale(min: min, max: max, pointCount: series.points.length);
  }

  final double min;
  final double max;
  final int pointCount;

  double x(int index) {
    if (pointCount <= 1) {
      return _padLeft + _plotWidth / 2;
    }
    return _padLeft + _plotWidth * index / (pointCount - 1);
  }

  double y(double value) {
    return _padTop + _plotHeight * (1 - (value - min) / (max - min));
  }

  static double get _plotWidth =>
      (chartWidth - _padLeft - _padRight).toDouble();
  static double get _plotHeight =>
      (chartHeight - _padTop - _padBottom).toDouble();
}

/// Draws the three recessive gridlines and their value labels.
String _gridAndAxis(_Scale scale, String unit) {
  final StringBuffer buffer = StringBuffer();
  for (int step = 0; step <= 2; step++) {
    final double value = scale.min + (scale.max - scale.min) * step / 2;
    final double y = _round(scale.y(value));
    buffer
      ..write(
        '<line x1="$_padLeft" y1="$y" x2="${chartWidth - _padRight}" y2="$y" '
        'class="grid"/>',
      )
      ..write(
        '<text x="${_padLeft - 6}" y="${y + 3.5}" class="tick" '
        'text-anchor="end">${escapeMarkup(formatValue(value))}</text>',
      );
  }
  return '$buffer<text x="$_padLeft" y="10" class="unit">${escapeMarkup(unit)}</text>';
}

/// Draws the baseline as a dashed rule in chrome ink, not as a second series.
String _baseline(_Scale scale, double baseline) {
  final double y = _round(scale.y(baseline));
  return '<line x1="$_padLeft" y1="$y" x2="${chartWidth - _padRight}" y2="$y" '
      'class="baseline"/>'
      '<text x="${chartWidth - _padRight}" y="${y - 4}" class="tick" '
      'text-anchor="end">baseline</text>';
}

/// Draws the line as one polyline per run of consecutive recorded values.
///
/// A gap is left open rather than bridged, because joining across a run that
/// recorded nothing would draw a trend that was never measured.
String _segments(MetricSeries series, _Scale scale) {
  final StringBuffer buffer = StringBuffer();
  List<String> current = <String>[];

  void flush() {
    if (current.length > 1) {
      buffer.write(
        '<polyline points="${current.join(' ')}" class="line"/>',
      );
    }
    current = <String>[];
  }

  for (int i = 0; i < series.points.length; i++) {
    final double? value = series.points[i].value;
    if (value == null) {
      flush();
      continue;
    }
    current.add('${_round(scale.x(i))},${_round(scale.y(value))}');
  }
  flush();
  return buffer.toString();
}

/// Draws a marker per recorded run, each carrying its own native tooltip.
String _markers(MetricSeries series, _Scale scale) {
  final StringBuffer buffer = StringBuffer();
  for (int i = 0; i < series.points.length; i++) {
    final SeriesPoint point = series.points[i];
    final double? value = point.value;
    if (value == null) {
      continue;
    }
    final String tooltip = escapeMarkup(
      '${shortDate(point.capturedAt)} · '
      '${formatValue(value)} ${series.unit}'
      '${point.commit == null ? '' : ' · ${point.commit}'}',
    );
    buffer.write(
      '<circle cx="${_round(scale.x(i))}" cy="${_round(scale.y(value))}" '
      'r="4" class="marker"><title>$tooltip</title></circle>',
    );
  }
  return buffer.toString();
}

/// Labels only the first and last run, so dates cannot collide.
String _xAxisLabels(MetricSeries series, _Scale scale) {
  final int last = series.points.length - 1;
  final String first =
      '<text x="$_padLeft" y="${chartHeight - 10}" class="tick">'
      '${escapeMarkup(shortDate(series.points.first.capturedAt))}</text>';
  if (last <= 0) {
    return first;
  }
  return '$first<text x="${chartWidth - _padRight}" y="${chartHeight - 10}" '
      'class="tick" text-anchor="end">'
      '${escapeMarkup(shortDate(series.points[last].capturedAt))}</text>';
}

String _emptyState(String message) =>
    '<p class="empty">${escapeMarkup(message)}</p>';

/// Trims an ISO-8601 timestamp to its date, leaving anything else untouched.
String shortDate(String capturedAt) {
  final int separator = capturedAt.indexOf('T');
  return separator == -1 ? capturedAt : capturedAt.substring(0, separator);
}

/// Formats a metric value at a precision that suits its magnitude.
String formatValue(double? value) {
  if (value == null) {
    return '—';
  }
  if (value.abs() >= 1000) {
    return value.round().toString();
  }
  return value
      .toStringAsFixed(1)
      .replaceFirst(RegExp(r'\.0$'), '');
}

double _round(double value) => (value * 10).roundToDouble() / 10;

/// Escapes text for interpolation into SVG or HTML markup.
///
/// CUJ names come from test-case names in an upstream JUnit report, so they are
/// not trusted to be markup-safe.
String escapeMarkup(String text) => text
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');
