import 'package:flutter_test/flutter_test.dart';

import '../../../../scripts/dashboard/e2e_data.dart';
import '../../../../scripts/dashboard/render_dashboard.dart';
import '../../../../scripts/dashboard/system_health_data.dart';
import '../../../../scripts/dashboard/trend_series.dart';

void main() {
  MetricSeries seriesOf(
    String id,
    String label,
    List<double?> values, {
    String unit = 'ms',
  }) {
    return MetricSeries(
      id: id,
      label: label,
      unit: unit,
      points: <SeriesPoint>[
        for (int i = 0; i < values.length; i++)
          SeriesPoint(
            capturedAt: '2026-08-0${i + 1}T03:00:00Z',
            commit: 'commit$i',
            value: values[i],
          ),
      ],
    );
  }

  String render({
    List<SystemHealthGroup> systemHealth = const <SystemHealthGroup>[],
    List<E2eGroup> e2e = const <E2eGroup>[],
  }) {
    return renderDashboard(
      systemHealth: systemHealth,
      e2e: e2e,
      generatedAt: '2026-08-26T09:00:00Z',
    );
  }

  SystemHealthGroup healthGroup({String journey = 'pre_login_v1'}) {
    return SystemHealthGroup(
      journey: journey,
      metrics: <MetricSeries>[
        seriesOf('cold_start_ms', 'Cold start', <double?>[800, 820]),
        seriesOf('ttid_ms', 'TTID', <double?>[null, null]),
      ],
    );
  }

  E2eGroup e2eGroup({
    String suite = 'cuj_v1',
    List<CujSummary> cujs = const <CujSummary>[],
  }) {
    return E2eGroup(
      suite: suite,
      metrics: <MetricSeries>[
        seriesOf('pass_rate', 'Pass rate', <double?>[100, 90], unit: '%'),
      ],
      cujs: cujs,
    );
  }

  CujSummary cuj({
    String name = 'cuj1',
    int failures = 1,
    int flakes = 2,
    String lastStatus = 'flaked',
  }) {
    return CujSummary(
      name: name,
      runs: 3,
      failures: failures,
      flakes: flakes,
      lastStatus: lastStatus,
      failuresPerRun: <int>[1, 0, 0],
    );
  }

  group('document', () {
    test('renders a complete standalone HTML document', () {
      final String html = render();

      expect(html, startsWith('<!doctype html>'));
      expect(html, contains('<title>Trend Dashboard</title>'));
      expect(html.trimRight(), endsWith('</html>'));
    });

    test('ships no script and fetches nothing', () {
      final String html = render(
        systemHealth: <SystemHealthGroup>[healthGroup()],
        e2e: <E2eGroup>[e2eGroup(cujs: <CujSummary>[cuj()])],
      );

      expect(html, isNot(contains('<script')));
      expect(html, isNot(contains('http://')));
      expect(html, isNot(contains('https://')));
    });

    test('makes both views reachable by anchor', () {
      final String html = render();

      expect(html, contains('id="system-health"'));
      expect(html, contains('id="e2e"'));
      expect(html, contains('href="#system-health"'));
      expect(html, contains('href="#e2e"'));
    });

    test('defines a dark palette for both the OS setting and a theme stamp',
        () {
      final String html = render();

      expect(html, contains('@media (prefers-color-scheme: dark)'));
      expect(html, contains(':root[data-theme="dark"]'));
    });

    test('stamps when it was generated', () {
      expect(render(), contains('2026-08-26T09:00:00Z'));
    });
  });

  group('system-health view', () {
    test('says so plainly when nothing has been recorded', () {
      expect(render(), contains('No performance runs have been recorded yet.'));
    });

    test('renders a card per metric with its latest value', () {
      final String html = render(
        systemHealth: <SystemHealthGroup>[healthGroup()],
      );

      expect(html, contains('Cold start'));
      expect(html, contains('820 <span class="unit-inline">ms</span>'));
    });

    test('marks a metric with no producer as not recorded', () {
      final String html = render(
        systemHealth: <SystemHealthGroup>[healthGroup()],
      );

      expect(html, contains('TTID'));
      expect(html, contains('not recorded'));
    });

    test('gives each journey its own heading', () {
      final String html = render(
        systemHealth: <SystemHealthGroup>[
          healthGroup(),
          healthGroup(journey: 'post_login_v1'),
        ],
      );

      expect(html, contains('Journey: pre_login_v1'));
      expect(html, contains('Journey: post_login_v1'));
    });
  });

  group('E2E view', () {
    test('says so plainly when nothing has been recorded', () {
      expect(render(), contains('No CUJ runs have been recorded yet.'));
    });

    test('renders a row per CUJ with its failure and flake counts', () {
      final String html = render(
        e2e: <E2eGroup>[
          e2eGroup(cujs: <CujSummary>[cuj(failures: 4, flakes: 7)]),
        ],
      );

      expect(html, contains('cuj1'));
      expect(html, contains('>4</td>'));
      expect(html, contains('>7</td>'));
    });

    test('names the status rather than relying on colour alone', () {
      final String html = render(
        e2e: <E2eGroup>[
          e2eGroup(cujs: <CujSummary>[cuj(lastStatus: 'flaked')]),
        ],
      );

      expect(html, contains('dot-warning'));
      expect(html, contains('>flaked</span>'));
    });

    test('falls back to a neutral dot for an unrecognised status', () {
      final String html = render(
        e2e: <E2eGroup>[
          e2eGroup(cujs: <CujSummary>[cuj(lastStatus: 'unknown')]),
        ],
      );

      expect(html, contains('dot-muted'));
    });

    test('keeps a wide table scrollable inside its own container', () {
      final String html = render(
        e2e: <E2eGroup>[e2eGroup(cujs: <CujSummary>[cuj()])],
      );

      expect(html, contains('class="scroll"'));
      expect(html, contains('overflow-x: auto'));
    });

    test('explains that pass rate counts a flake as a pass', () {
      expect(render(), contains('counts a flaked case as a pass'));
    });
  });

  group('untrusted text', () {
    test('escapes a CUJ name that contains markup', () {
      final String html = render(
        e2e: <E2eGroup>[
          e2eGroup(cujs: <CujSummary>[cuj(name: '<img onerror=x>')]),
        ],
      );

      expect(html, contains('&lt;img onerror=x&gt;'));
      expect(html, isNot(contains('<img')));
    });

    test('escapes a suite name that contains markup', () {
      final String html = render(
        e2e: <E2eGroup>[e2eGroup(suite: '<b>v2</b>')],
      );

      expect(html, contains('&lt;b&gt;v2&lt;/b&gt;'));
    });
  });
}
