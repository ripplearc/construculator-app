// Reduces one CUJ run's per-attempt JUnit XML to a single e2e-run.json.
//
// Knows nothing about git or CI; .github/workflows/e2e_cuj.yml snapshots each
// `patrol test` attempt's results into its own directory and hands this tool
// the parent. Parsing lives in scripts/e2e/junit_results.dart, so the pass and
// flake rules below are testable without constructing XML.
//
// Mirrors the capture/report/publish split CA-782 uses for the performance
// harness (scripts/perf/build_perf_report.dart).
//
// Usage:
//   dart scripts/e2e/build_e2e_report.dart \
//     --attempts-dir <dir> --output <file> \
//     [--suite <id>] [--commit <sha>] [--captured-at <iso8601>]

import 'dart:convert';
import 'dart:io';

import 'junit_results.dart';

/// Version of the `e2e-run.json` contract.
///
/// The trend store keeps every historical run, so consumers need to know which
/// shape they are reading. Bump this whenever a field changes meaning; adding a
/// new optional field does not require a bump.
const int e2eRunSchemaVersion = 1;

/// Identifier for the CUJ suite whose results are being recorded.
///
/// Runs are partitioned by suite in the trend store for the same reason perf
/// runs are partitioned by journey: a result is only comparable against other
/// results for the same body of tests, so changing the suite materially should
/// start a new series rather than corrupt the existing one.
const String defaultSuite = 'cuj_v1';

Future<void> main(List<String> args) async {
  final Map<String, String> options = <String, String>{};
  for (int i = 0; i + 1 < args.length; i += 2) {
    options[args[i]] = args[i + 1];
  }
  final String? attemptsDir = options['--attempts-dir'];
  final String? output = options['--output'];
  if (attemptsDir == null || output == null) {
    stderr.writeln(
      'Usage: build_e2e_report.dart --attempts-dir <dir> --output <file> '
      '[--suite <id>] [--commit <sha>] [--captured-at <iso8601>]',
    );
    exitCode = 1;
    return;
  }

  final Map<String, Object?> report = buildE2eReport(
    Directory(attemptsDir),
    suite: options['--suite'] ?? defaultSuite,
    commit: options['--commit'],
    capturedAt:
        options['--captured-at'] ?? DateTime.now().toUtc().toIso8601String(),
  );

  final File outputFile = File(output)..parent.createSync(recursive: true);
  outputFile.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(report)}\n',
  );
  stdout.writeln('✅ Wrote ${outputFile.path}');
}

/// Assembles the `e2e-run.json` record from a directory of attempt snapshots.
Map<String, Object?> buildE2eReport(
  Directory attemptsDir, {
  required String suite,
  required String capturedAt,
  String? commit,
}) {
  return assembleReport(
    readAttempts(attemptsDir),
    suite: suite,
    capturedAt: capturedAt,
    commit: commit,
  );
}

/// Assembles the `e2e-run.json` record from already-parsed attempts.
Map<String, Object?> assembleReport(
  List<AttemptResults> attempts, {
  required String suite,
  required String capturedAt,
  String? commit,
}) {
  final List<Map<String, Object?>> cases = summariseCases(attempts);
  return <String, Object?>{
    'schema_version': e2eRunSchemaVersion,
    'suite': suite,
    'captured_at': capturedAt,
    'commit': commit,
    'attempt_count': attempts.length,
    'duration_ms': attempts.isEmpty ? null : attempts.last.durationMs,
    'total_duration_ms': attempts.fold<double>(
      0,
      (double sum, AttemptResults a) => sum + a.durationMs,
    ),
    'totals': summariseTotals(cases),
    'cases': cases,
  };
}

/// Collapses every attempt of each case into one record with a final status.
///
/// A case is `flaked` when it ends green but was red on an earlier attempt —
/// the suite reports such a run as a pass, so without this the pass rate hides
/// exactly the instability the trend exists to surface.
List<Map<String, Object?>> summariseCases(List<AttemptResults> attempts) {
  final Map<String, List<CaseAttempt>> byCase = <String, List<CaseAttempt>>{};
  for (final AttemptResults attempt in attempts) {
    attempt.cases.forEach((String key, CaseAttempt result) {
      byCase.putIfAbsent(key, () => <CaseAttempt>[]).add(result);
    });
  }

  final List<MapEntry<String, List<CaseAttempt>>> ordered =
      byCase.entries.toList()
        ..sort(
          (
            MapEntry<String, List<CaseAttempt>> a,
            MapEntry<String, List<CaseAttempt>> b,
          ) => a.key.compareTo(b.key),
        );
  return ordered.map((MapEntry<String, List<CaseAttempt>> entry) {
    final List<CaseAttempt> results = entry.value;
    final CaseAttempt last = results.last;
    final bool everFailed = results.any(
      (CaseAttempt r) => r.status == CaseStatus.failed,
    );
    final String status = switch (last.status) {
      CaseStatus.passed when everFailed => 'flaked',
      final CaseStatus s => s.name,
    };
    return <String, Object?>{
      'name': last.name,
      'classname': last.className,
      'status': status,
      'duration_ms': last.durationMs,
      'attempts': results.map((CaseAttempt r) => r.toJson()).toList(),
    };
  }).toList();
}

/// Counts outcomes and derives the two headline rates.
///
/// Skipped cases are excluded from both denominators: a case that never ran is
/// neither a pass nor a failure, and counting it as either moves the rates
/// without anything about the suite's health having changed.
Map<String, Object?> summariseTotals(List<Map<String, Object?>> cases) {
  int passed = 0;
  int failed = 0;
  int flaked = 0;
  int skipped = 0;
  for (final Map<String, Object?> testCase in cases) {
    switch (testCase['status']) {
      case 'passed':
        passed++;
      case 'flaked':
        flaked++;
      case 'failed':
        failed++;
      default:
        skipped++;
    }
  }
  final int ran = passed + flaked + failed;
  return <String, Object?>{
    'cases': cases.length,
    'ran': ran,
    'passed': passed,
    'flaked': flaked,
    'failed': failed,
    'skipped': skipped,
    // A flaked case ends green, so it counts towards the pass rate CI reports.
    // Plotting flake_rate alongside it is what tells the two apart.
    'pass_rate': _rate(passed + flaked, ran),
    'flake_rate': _rate(flaked, ran),
  };
}

double? _rate(int numerator, int denominator) => denominator == 0
    ? null
    : (numerator / denominator * 10000).round() / 10000;
