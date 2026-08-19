// Files one perf-run.json into the trend store and rebuilds its index.
//
// Knows nothing about git; scripts/perf/publish_perf_run.sh owns the perf-data
// branch mechanics and hands this tool a checked-out directory.
//
// Usage:
//   dart scripts/perf/publish_perf_run.dart --run-file <file> --data-dir <dir>

import 'dart:convert';
import 'dart:io';

/// Slug for values that are absent from a run record.
///
/// A run missing its journey or commit is still worth keeping, so it is filed
/// under a stable placeholder rather than dropped or given a random name.
const String _unknown = 'unknown';

Future<void> main(List<String> args) async {
  final Map<String, String> options = <String, String>{};
  for (int i = 0; i + 1 < args.length; i += 2) {
    options[args[i]] = args[i + 1];
  }
  final String? runFile = options['--run-file'];
  final String? dataDir = options['--data-dir'];
  if (runFile == null || dataDir == null) {
    stderr.writeln(
      'Usage: publish_perf_run.dart --run-file <file> --data-dir <dir>',
    );
    exitCode = 1;
    return;
  }

  final Directory data = Directory(dataDir);
  final File destination = publishRun(File(runFile), data);
  final int count = rebuildIndex(data);
  stdout.writeln('✅ Filed ${destination.path} ($count runs indexed)');
}

/// Copies [runFile] into its canonical location under [dataDir].
///
/// Re-publishing the same run overwrites its file rather than appending a
/// duplicate, so a retried CI job cannot double-count a run in the trend.
File publishRun(File runFile, Directory dataDir) {
  final Map<String, Object?> run = _readJsonObject(runFile);
  final File destination = File('${dataDir.path}/${runRelativePath(run)}');
  destination.parent.createSync(recursive: true);
  destination.writeAsStringSync(runFile.readAsStringSync());
  return destination;
}

/// Builds the store-relative path a run record is filed under.
///
/// Runs are partitioned by journey so that a journey change starts a visibly
/// separate series instead of interleaving incomparable numbers.
String runRelativePath(Map<String, Object?> run) {
  final String journey = _slug(run['journey']);
  final String capturedAt = _slug(run['captured_at']);
  final String commit = _slug(run['commit']);
  return 'runs/$journey/$capturedAt-$commit.json';
}

/// Rewrites `index.json` from every run currently in the store.
///
/// The index is derived, never appended to, so a hand-edited or partially
/// written index repairs itself on the next publish.
int rebuildIndex(Directory dataDir) {
  final Directory runsDir = Directory('${dataDir.path}/runs');
  final List<Map<String, Object?>> entries = <Map<String, Object?>>[];

  if (runsDir.existsSync()) {
    final List<File> files =
        runsDir
            .listSync(recursive: true)
            .whereType<File>()
            .where((File file) => file.path.endsWith('.json'))
            .toList()
          ..sort((File a, File b) => a.path.compareTo(b.path));

    for (final File file in files) {
      final Map<String, Object?> run = _readJsonObject(file);
      final Map<String, Object?> metrics =
          run['metrics'] is Map<String, Object?>
          ? run['metrics'] as Map<String, Object?>
          : <String, Object?>{};
      entries.add(<String, Object?>{
        'path': file.path
            .substring(dataDir.path.length)
            .replaceFirst(RegExp('^/'), ''),
        'journey': run['journey'],
        'captured_at': run['captured_at'],
        'commit': run['commit'],
        'device_id': _deviceId(run),
        'cold_start_median_ms': _median(metrics['cold_start_ms']),
        'warm_start_median_ms': _median(metrics['warm_start_ms']),
      });
    }
  }

  entries.sort((Map<String, Object?> a, Map<String, Object?> b) {
    return '${a['captured_at']}'.compareTo('${b['captured_at']}');
  });

  File('${dataDir.path}/index.json').writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(<String, Object?>{
      'schema_version': 1,
      'run_count': entries.length,
      'runs': entries,
    })}\n',
  );
  return entries.length;
}

Object? _median(Object? phase) {
  return phase is Map<String, Object?> ? phase['median'] : null;
}

Object? _deviceId(Map<String, Object?> run) {
  final Object? device = run['device'];
  return device is Map<String, Object?> ? device['id'] : null;
}

/// Reduces [value] to a filesystem-safe slug.
String _slug(Object? value) {
  final String text = '$value';
  if (value == null || text.isEmpty) {
    return _unknown;
  }
  return text.replaceAll(RegExp('[^A-Za-z0-9._-]'), '-');
}

Map<String, Object?> _readJsonObject(File file) {
  final Object? decoded = jsonDecode(file.readAsStringSync());
  return decoded is Map<String, Object?> ? decoded : <String, Object?>{};
}
