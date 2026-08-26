// Reads CA-782's perf-data store into the system-health view's series.

import 'dart:io';

import 'trend_series.dart';

/// How to pull one metric out of a `perf-run.json` record.
class _MetricDefinition {
  const _MetricDefinition(this.id, this.label, this.unit, this.path);

  final String id;
  final String label;
  final String unit;

  /// Dotted path into the run's `metrics` block.
  final String path;
}

/// The five metrics the system-health view is required to plot.
///
/// `ttid_ms` has no producer yet: CA-782 records startup from
/// `timeToFirstFrameRasterizedMicros` as cold and warm start and emits no
/// separate TTID field. It is declared here so the view renders its slot with
/// an explicit empty state rather than silently showing four of five metrics.
const List<_MetricDefinition> _systemHealthMetrics = <_MetricDefinition>[
  _MetricDefinition('cold_start_ms', 'Cold start', 'ms', 'cold_start_ms.median'),
  _MetricDefinition('ttid_ms', 'TTID', 'ms', 'ttid_ms.median'),
  _MetricDefinition('warm_start_ms', 'Warm start', 'ms', 'warm_start_ms.median'),
  _MetricDefinition('memory', 'Peak memory', 'KB', 'memory.peak_rss_kb'),
  _MetricDefinition('jank', 'Jank (p90 build)', 'ms', 'jank.p90_frame_build_ms'),
];

/// One perf journey's runs. Journeys are never merged into one series.
class SystemHealthGroup {
  SystemHealthGroup({required this.journey, required this.metrics});

  final String journey;
  final List<MetricSeries> metrics;
}

/// Builds one group per journey found in [perfStore].
///
/// Runs are grouped rather than concatenated because CA-782 partitions by
/// journey precisely so that a journey change starts a new series; flattening
/// them here would reintroduce exactly the comparison that prevents.
List<SystemHealthGroup> loadSystemHealth(Directory perfStore) {
  final Map<String, Object?> baselines = readJsonObject(
    File('${perfStore.path}/baselines.json'),
  );

  return groupRunsBy(readIndexRuns(perfStore), 'journey').entries.map((
    MapEntry<String, List<Map<String, Object?>>> group,
  ) {
    final List<Map<String, Object?>> runs = group.value
        .map((Map<String, Object?> e) => readRunRecord(perfStore, e))
        .toList();
    final Object? recorded = baselines[group.key];
    final Map<String, Object?> journeyBaselines =
        recorded is Map<String, Object?> ? recorded : <String, Object?>{};

    return SystemHealthGroup(
      journey: group.key,
      metrics: _systemHealthMetrics.map((_MetricDefinition definition) {
        return MetricSeries(
          id: definition.id,
          label: definition.label,
          unit: definition.unit,
          baseline: toDouble(journeyBaselines[definition.id]),
          points: runs.map((Map<String, Object?> run) {
            return SeriesPoint(
              capturedAt: '${run['captured_at']}',
              commit: run['commit'] as String?,
              value: _metricValue(run, definition.path),
            );
          }).toList(),
        );
      }).toList(),
    );
  }).toList();
}

/// Resolves a dotted path inside a run's `metrics` block.
///
/// A metric block that reports `available: false` yields null: CA-782 writes
/// that instead of a number when it could not recognise the upstream artifact,
/// and plotting the absent value as anything would fabricate a data point.
double? _metricValue(Map<String, Object?> run, String path) {
  Object? node = run['metrics'];
  for (final String segment in path.split('.')) {
    if (node is! Map<String, Object?> || node['available'] == false) {
      return null;
    }
    node = node[segment];
  }
  return toDouble(node);
}
