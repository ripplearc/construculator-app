// The shape a trend store is read into, and the primitives for reading one.
//
// Both raw stores — CA-782's perf-data and CA-978's e2e-data — are append-only
// archives of one JSON file per run plus a derived index.json. This file knows
// that much and nothing about what any particular metric means, so the two
// loaders built on it stay small and independently testable.
//
// Nothing here writes to a store. They are owned by the CI jobs that produce
// runs; the dashboard is a read-only consumer.

import 'dart:convert';
import 'dart:io';

/// One run's value for one metric.
class SeriesPoint {
  SeriesPoint({required this.capturedAt, this.commit, this.value});

  final String capturedAt;
  final String? commit;

  /// Null when the run recorded no usable value for this metric.
  ///
  /// A gap is plotted as a gap rather than as a zero, because a metric that
  /// failed to record is not the same as a metric that measured zero.
  final double? value;
}

/// A metric plotted over time, optionally against a recorded baseline.
class MetricSeries {
  MetricSeries({
    required this.id,
    required this.label,
    required this.unit,
    required this.points,
    this.baseline,
  });

  final String id;
  final String label;
  final String unit;
  final List<SeriesPoint> points;

  /// The baseline to plot this series against, when one has been recorded.
  ///
  /// No baseline numbers exist yet — CA-476 defines the methodology but cannot
  /// hold numbers until a harness has produced them — so this is normally null
  /// and the view says so rather than showing an invented threshold.
  final double? baseline;

  bool get hasData => points.any((SeriesPoint point) => point.value != null);
}

/// Reads a store's `index.json` entries, oldest first.
///
/// The index is sorted here rather than trusted, because it is rebuilt by
/// whichever publish ran last and its order is not part of either store's
/// contract.
List<Map<String, Object?>> readIndexRuns(Directory store) {
  final Object? runs = readJsonObject(File('${store.path}/index.json'))['runs'];
  if (runs is! List<Object?>) {
    return <Map<String, Object?>>[];
  }
  final List<Map<String, Object?>> entries = runs
      .whereType<Map<String, Object?>>()
      .toList();
  entries.sort((Map<String, Object?> a, Map<String, Object?> b) {
    return '${a['captured_at']}'.compareTo('${b['captured_at']}');
  });
  return entries;
}

/// Loads the full run record an index entry points at.
///
/// Falls back to the index entry itself when the run file is missing or
/// unreadable, so a store that lost a file still plots the headline numbers the
/// index carries rather than dropping the run from the trend entirely.
Map<String, Object?> readRunRecord(
  Directory store,
  Map<String, Object?> entry,
) {
  final File file = File('${store.path}/${entry['path']}');
  if (!file.existsSync()) {
    return entry;
  }
  final Map<String, Object?> run = readJsonObject(file);
  return run.isEmpty ? entry : run;
}

/// Groups run entries by the value of [key], preserving their order within each
/// group.
Map<String, List<Map<String, Object?>>> groupRunsBy(
  List<Map<String, Object?>> entries,
  String key,
) {
  final Map<String, List<Map<String, Object?>>> grouped =
      <String, List<Map<String, Object?>>>{};
  for (final Map<String, Object?> entry in entries) {
    grouped
        .putIfAbsent('${entry[key]}', () => <Map<String, Object?>>[])
        .add(entry);
  }
  return grouped;
}

/// Narrows a decoded JSON value to a double, or null if it is not a number.
double? toDouble(Object? value) => value is num ? value.toDouble() : null;

/// Decodes [file] as a JSON object, yielding an empty map if it cannot be read.
///
/// A store can legitimately be empty (nothing has published yet) and can be
/// caught mid-write, so neither case is an error worth aborting the whole
/// dashboard build for.
Map<String, Object?> readJsonObject(File file) {
  if (!file.existsSync()) {
    return <String, Object?>{};
  }
  try {
    final Object? decoded = jsonDecode(file.readAsStringSync());
    return decoded is Map<String, Object?> ? decoded : <String, Object?>{};
  } on FormatException {
    return <String, Object?>{};
  } on FileSystemException {
    // readAsStringSync decodes as UTF-8 and throws this (not FormatException)
    // when a run file is truncated inside a multi-byte character or is
    // otherwise not valid UTF-8. Same handling: treat it as unreadable.
    return <String, Object?>{};
  }
}
