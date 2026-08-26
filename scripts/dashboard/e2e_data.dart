// Reads CA-978's e2e-data store into the E2E view's series and per-CUJ rows.

import 'dart:io';

import 'trend_series.dart';

/// One CUJ's history across every run in a suite.
class CujSummary {
  CujSummary({
    required this.name,
    required this.runs,
    required this.failures,
    required this.flakes,
    required this.lastStatus,
    required this.failuresPerRun,
  });

  final String name;
  final int runs;
  final int failures;
  final int flakes;
  final String lastStatus;

  /// Failure count per run, oldest first, for the row's sparkline.
  final List<int> failuresPerRun;
}

/// One E2E suite's runs.
class E2eGroup {
  E2eGroup({required this.suite, required this.metrics, required this.cujs});

  final String suite;
  final List<MetricSeries> metrics;
  final List<CujSummary> cujs;
}

/// Builds one group per suite found in [e2eStore].
///
/// Suites are kept apart for the same reason perf journeys are: a pass rate is
/// only meaningful relative to the set of CUJs it was measured over.
List<E2eGroup> loadE2e(Directory e2eStore) {
  return groupRunsBy(readIndexRuns(e2eStore), 'suite').entries.map((
    MapEntry<String, List<Map<String, Object?>>> group,
  ) {
    final List<Map<String, Object?>> index = group.value;

    MetricSeries series(
      String id,
      String label,
      String unit,
      double? Function(Map<String, Object?>) read,
    ) {
      return MetricSeries(
        id: id,
        label: label,
        unit: unit,
        points: index.map((Map<String, Object?> run) {
          return SeriesPoint(
            capturedAt: '${run['captured_at']}',
            commit: run['commit'] as String?,
            value: read(run),
          );
        }).toList(),
      );
    }

    return E2eGroup(
      suite: group.key,
      metrics: <MetricSeries>[
        series('pass_rate', 'Pass rate', '%', (Map<String, Object?> run) {
          return _percent(run['pass_rate']);
        }),
        series('flake_rate', 'Flake rate', '%', (Map<String, Object?> run) {
          return _percent(run['flake_rate']);
        }),
        series('duration_ms', 'Run duration', 's', (Map<String, Object?> run) {
          final double? ms = toDouble(run['duration_ms']);
          return ms == null ? null : ms / 1000;
        }),
      ],
      cujs: summariseCujs(
        index
            .map((Map<String, Object?> e) => readRunRecord(e2eStore, e))
            .toList(),
      ),
    );
  }).toList();
}

/// Rolls every run's per-case results up into one row per CUJ.
///
/// Flakes are counted separately from failures rather than folded into them:
/// the run they came from was reported green, so a CUJ that flakes every week
/// is invisible in the pass rate and only shows up here.
List<CujSummary> summariseCujs(List<Map<String, Object?>> runs) {
  final Map<String, List<String>> statusesByCuj = <String, List<String>>{};

  for (final Map<String, Object?> run in runs) {
    final Object? recorded = run['cases'];
    final List<Object?> cases = recorded is List<Object?>
        ? recorded
        : const <Object?>[];
    for (final Object? entry in cases) {
      if (entry is! Map<String, Object?>) {
        continue;
      }
      statusesByCuj
          .putIfAbsent('${entry['name']}', () => <String>[])
          .add('${entry['status']}');
    }
  }

  final List<String> names = statusesByCuj.keys.toList()..sort();
  return names.map((String name) {
    final List<String> statuses = statusesByCuj[name] ?? const <String>[];
    return CujSummary(
      name: name,
      runs: statuses.length,
      failures: statuses.where((String s) => s == 'failed').length,
      flakes: statuses.where((String s) => s == 'flaked').length,
      lastStatus: statuses.isEmpty ? 'unknown' : statuses.last,
      failuresPerRun: statuses
          .map((String s) => s == 'failed' ? 1 : 0)
          .toList(),
    );
  }).toList();
}

double? _percent(Object? rate) {
  final double? value = toDouble(rate);
  return value == null ? null : value * 100;
}
