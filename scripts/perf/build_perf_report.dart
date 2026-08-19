// Builds a perf-run.json record from the raw artifacts emitted by
// capture_perf_run.sh.
//
// Usage:
//   dart scripts/perf/build_perf_report.dart --input <dir> --output <file>

import 'dart:convert';
import 'dart:io';

/// Version of the perf-run.json contract.
///
/// The trend store keeps every historical run, so consumers need to know which
/// shape they are reading. Bump this whenever a field changes meaning; adding a
/// new optional field does not require a bump.
const int perfRunSchemaVersion = 1;

/// Startup metric used for both cold and warm start.
///
/// Rasterization of the first frame is the point the user actually sees
/// something, so it tracks perceived startup better than the build timestamp.
const String _startupMetricKey = 'timeToFirstFrameRasterizedMicros';

Future<void> main(List<String> args) async {
  final Map<String, String> options = <String, String>{};
  for (int i = 0; i + 1 < args.length; i += 2) {
    options[args[i]] = args[i + 1];
  }
  final String? input = options['--input'];
  final String? output = options['--output'];
  if (input == null || output == null) {
    stderr.writeln('Usage: build_perf_report.dart --input <dir> --output <file>');
    exitCode = 1;
    return;
  }

  final Map<String, Object?> report = buildPerfReport(Directory(input));
  final File outputFile = File(output);
  await outputFile.parent.create(recursive: true);
  await outputFile.writeAsString(
    '${const JsonEncoder.withIndent('  ').convert(report)}\n',
  );
  stdout.writeln('✅ Wrote ${outputFile.path}');
}

/// Assembles the perf-run.json record from a raw capture directory.
Map<String, Object?> buildPerfReport(Directory input) {
  final Map<String, Object?> meta = _readJsonObject(
    File('${input.path}/meta.json'),
  );
  final String journey = meta['journey'] as String? ?? 'unknown';

  final List<double> cold = readStartupSamplesMillis(
    Directory('${input.path}/cold'),
  );
  final List<double> warm = readStartupSamplesMillis(
    Directory('${input.path}/warm'),
  );

  return <String, Object?>{
    'schema_version': perfRunSchemaVersion,
    'journey': journey,
    'captured_at': meta['captured_at'],
    'commit': meta['commit'],
    'flutter_version': meta['flutter_version'],
    'device': <String, Object?>{
      'id': meta['device_id'],
      // Device models are not yet registered for the lab hardware, so the
      // model is recorded as unknown rather than guessed. Populating it is
      // tracked in the operator documentation, not inferred here.
      'model': meta['device_model'],
    },
    'flavor': meta['flavor'],
    'iterations': meta['iterations'],
    'metrics': <String, Object?>{
      'cold_start_ms': _summariseStartup(cold),
      'warm_start_ms': _summariseStartup(warm),
      'jank': readJankSummary(
        File('${input.path}/jank/$journey.timeline_summary.json'),
      ),
      'memory': readMemorySummary(
        File('${input.path}/memory/memory_profile.json'),
      ),
    },
  };
}

/// Reads every `run-*/start_up_info.json` under [directory], in run order.
List<double> readStartupSamplesMillis(Directory directory) {
  if (!directory.existsSync()) {
    return <double>[];
  }
  final List<Directory> runs =
      directory.listSync().whereType<Directory>().toList()
        ..sort((Directory a, Directory b) => _runIndex(a).compareTo(_runIndex(b)));

  final List<double> samples = <double>[];
  for (final Directory run in runs) {
    final File info = File('${run.path}/start_up_info.json');
    if (!info.existsSync()) {
      continue;
    }
    final Object? micros = _readJsonObject(info)[_startupMetricKey];
    if (micros is num) {
      samples.add(micros / 1000);
    }
  }
  return samples;
}

/// Extracts the jank metrics from a flutter_driver timeline summary.
///
/// The summary already reports percentiles, so they are read rather than
/// recomputed from raw frame times.
Map<String, Object?> readJankSummary(File summary) {
  if (!summary.existsSync()) {
    return <String, Object?>{'available': false};
  }
  final Map<String, Object?> json = _readJsonObject(summary);
  return <String, Object?>{
    'available': true,
    'frame_count': json['frame_count'],
    'p90_frame_build_ms': json['90th_percentile_frame_build_time_millis'],
    'p90_frame_rasterizer_ms':
        json['90th_percentile_frame_rasterizer_time_millis'],
    'missed_frame_build_budget_count': json['missed_frame_build_budget_count'],
    'missed_frame_rasterizer_budget_count':
        json['missed_frame_rasterizer_budget_count'],
  };
}

/// Extracts peak resident memory from a DevTools memory profile.
///
/// The profile is produced by DevTools rather than by this repository, so an
/// unrecognised shape yields an unavailable result instead of a fabricated
/// number that would silently enter the trend history.
Map<String, Object?> readMemorySummary(File profile) {
  if (!profile.existsSync()) {
    return <String, Object?>{'available': false};
  }
  final Object? decoded = jsonDecode(profile.readAsStringSync());
  final List<Object?> samples = switch (decoded) {
    final List<Object?> list => list,
    final Map<String, Object?> map => switch (map['samples']) {
      final List<Object?> list => list,
      _ => const <Object?>[],
    },
    _ => const <Object?>[],
  };

  final List<num> rss = samples
      .whereType<Map<String, Object?>>()
      .map((Map<String, Object?> sample) => sample['rss'])
      .whereType<num>()
      .toList();
  if (rss.isEmpty) {
    return <String, Object?>{'available': false};
  }
  return <String, Object?>{
    'available': true,
    'peak_rss_kb': rss.reduce((num a, num b) => a > b ? a : b) / 1024,
    'sample_count': rss.length,
  };
}

/// Returns the median of [values], or null when there is nothing to summarise.
///
/// The median is used rather than the mean because a single scheduling stall on
/// the device otherwise drags the whole run's headline number with it.
double? median(List<double> values) {
  if (values.isEmpty) {
    return null;
  }
  final List<double> sorted = List<double>.of(values)..sort();
  final int middle = sorted.length ~/ 2;
  if (sorted.length.isOdd) {
    return sorted[middle];
  }
  return (sorted[middle - 1] + sorted[middle]) / 2;
}

Map<String, Object?> _summariseStartup(List<double> samples) {
  return <String, Object?>{
    'median': median(samples),
    'samples': samples,
  };
}

int _runIndex(Directory directory) {
  final String? digits = RegExp(r'run-(\d+)$')
      .firstMatch(directory.path)
      ?.group(1);
  return digits == null ? 0 : int.parse(digits);
}

Map<String, Object?> _readJsonObject(File file) {
  final Object? decoded = jsonDecode(file.readAsStringSync());
  return decoded is Map<String, Object?> ? decoded : <String, Object?>{};
}
