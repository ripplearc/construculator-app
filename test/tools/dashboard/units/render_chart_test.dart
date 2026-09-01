import 'package:flutter_test/flutter_test.dart';

import '../../../../scripts/dashboard/render_chart.dart';
import '../../../../scripts/dashboard/trend_series.dart';

void main() {
  MetricSeries seriesOf(
    List<double?> values, {
    double? baseline,
    String unit = 'ms',
  }) {
    return MetricSeries(
      id: 'cold_start_ms',
      label: 'Cold start',
      unit: unit,
      baseline: baseline,
      points: <SeriesPoint>[
        for (int i = 0; i < values.length; i++)
          SeriesPoint(
            capturedAt: '2026-08-${(i + 1).toString().padLeft(2, '0')}'
                'T03:00:00Z',
            commit: 'commit$i',
            value: values[i],
          ),
      ],
    );
  }

  group('lineChartSvg', () {
    test('renders an empty state rather than an empty axis with no data', () {
      final String svg = lineChartSvg(seriesOf(<double?>[null]));

      expect(svg, contains('No runs recorded yet'));
      expect(svg, isNot(contains('<svg')));
    });

    test('names the baseline in the empty state when one is recorded', () {
      final String svg = lineChartSvg(
        seriesOf(<double?>[null], baseline: 750),
      );

      expect(svg, contains('baseline 750'));
    });

    test('draws a line through consecutive recorded runs', () {
      final String svg = lineChartSvg(seriesOf(<double?>[800, 820, 810]));

      expect(svg, contains('<polyline'));
      expect('<circle'.allMatches(svg).length, 3);
    });

    test('leaves a gap open rather than bridging a missing run', () {
      final String svg = lineChartSvg(
        seriesOf(<double?>[800, null, 810, 815]),
      );

      expect('<polyline'.allMatches(svg).length, 1);
      expect('<circle'.allMatches(svg).length, 3);
    });

    test('plots a single run as a marker with no line', () {
      final String svg = lineChartSvg(seriesOf(<double?>[800]));

      expect(svg, isNot(contains('<polyline')));
      expect('<circle'.allMatches(svg).length, 1);
    });

    test('draws a flat series without collapsing its scale', () {
      final String svg = lineChartSvg(seriesOf(<double?>[800, 800, 800]));

      expect(svg, contains('<polyline'));
      expect(svg, isNot(contains('NaN')));
    });

    test('draws the baseline as a dashed rule with a direct label', () {
      final String svg = lineChartSvg(
        seriesOf(<double?>[800, 820], baseline: 750),
      );

      expect(svg, contains('class="baseline"'));
      expect(svg, contains('>baseline</text>'));
    });

    test('widens the scale so a far-off baseline stays on the chart', () {
      final String svg = lineChartSvg(
        seriesOf(<double?>[800, 820], baseline: 200),
      );

      // The lowest gridline label is the baseline, so it sits on the plot
      // rather than being clipped off the bottom edge.
      expect(svg, contains('>200</text>'));
    });

    test('gives every marker a tooltip naming its date, value and commit', () {
      final String svg = lineChartSvg(seriesOf(<double?>[800]));

      expect(svg, contains('<title>2026-08-01 · 800 ms · commit0</title>'));
    });

    test('omits the commit segment from a tooltip when no commit is recorded', () {
      final MetricSeries series = MetricSeries(
        id: 'cold_start_ms',
        label: 'Cold start',
        unit: 'ms',
        points: <SeriesPoint>[
          SeriesPoint(capturedAt: '2026-08-01T03:00:00Z', value: 800),
        ],
      );

      final String svg = lineChartSvg(series);

      expect(svg, contains('<title>2026-08-01 · 800 ms</title>'));
    });

    test('names the gridlines with a class that cannot clash with a CSS grid', () {
      final String svg = lineChartSvg(seriesOf(<double?>[800, 820]));

      expect(svg, contains('class="gridline"'));
      expect(svg, isNot(contains('class="grid"')));
    });

    test('labels only the first and last run on the x axis', () {
      final String svg = lineChartSvg(
        seriesOf(<double?>[800, 820, 810, 805]),
      );

      expect(svg, contains('2026-08-01'));
      expect(svg, contains('2026-08-04'));
      expect(svg, isNot(contains('>2026-08-02<')));
    });

    test('refers to colours as custom properties so both themes apply', () {
      final String svg = lineChartSvg(seriesOf(<double?>[800, 820]));

      expect(svg, isNot(contains('#')));
    });

    test('escapes a unit that contains markup', () {
      final String svg = lineChartSvg(
        seriesOf(<double?>[800], unit: '<script>'),
      );

      expect(svg, contains('&lt;script&gt;'));
      expect(svg, isNot(contains('<script>')));
    });
  });

  group('sparklineSvg', () {
    test('renders a placeholder when a CUJ has no runs', () {
      expect(sparklineSvg(<int>[]), isNot(contains('<svg')));
    });

    test('draws one bar per run', () {
      final String svg = sparklineSvg(<int>[0, 1, 0]);

      expect('<rect'.allMatches(svg).length, 3);
    });

    test('distinguishes a failing run from a passing one by fill', () {
      final String svg = sparklineSvg(<int>[0, 1]);

      expect(svg, contains('var(--status-critical)'));
      expect(svg, contains('var(--grid)'));
    });

    test('keeps bars on screen when many runs accumulate', () {
      final String svg = sparklineSvg(List<int>.filled(60, 1));

      expect(svg, isNot(contains('width="0"')));
      expect(svg, isNot(contains('width="-')));
    });
  });
}
