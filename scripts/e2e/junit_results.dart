// Reads the instrumentation runner's JUnit XML into per-attempt results.
//
// This is the parsing half of the E2E reporting split: it turns a directory of
// `attempt-<n>/` snapshots into typed results and makes no judgement about what
// they mean. scripts/e2e/build_e2e_report.dart owns the aggregation, which is
// what makes the pass/flake rules testable without any XML.

import 'dart:io';

import 'package:xml/xml.dart';

/// Outcome of a single test case within a single attempt.
enum CaseStatus { passed, failed, skipped }

/// One test case's result in one attempt of the suite.
class CaseAttempt {
  CaseAttempt({
    required this.attempt,
    required this.name,
    required this.status,
    this.className,
    this.durationMs,
    this.failure,
  });

  final int attempt;
  final String name;
  final String? className;
  final CaseStatus status;
  final double? durationMs;
  final String? failure;

  Map<String, Object?> toJson() => <String, Object?>{
    'attempt': attempt,
    'status': status.name,
    'duration_ms': durationMs,
    if (failure != null) 'failure': failure,
  };
}

/// Every case result one attempt of the suite produced.
class AttemptResults {
  AttemptResults({
    required this.attempt,
    required this.cases,
    required this.durationMs,
  });

  final int attempt;

  /// Case key (`classname#name`) to that case's result in this attempt.
  final Map<String, CaseAttempt> cases;

  /// Wall time the suite itself reported for this attempt.
  final double durationMs;
}

/// Reads each `attempt-<n>/` snapshot under [attemptsDir], in attempt order.
///
/// Every attempt is read rather than only the last one, because a case that
/// failed and then passed on retry is the only flake signal the suite emits.
List<AttemptResults> readAttempts(Directory attemptsDir) {
  if (!attemptsDir.existsSync()) {
    return <AttemptResults>[];
  }
  final List<Directory> dirs =
      attemptsDir.listSync().whereType<Directory>().toList()
        ..sort(
          (Directory a, Directory b) =>
              _attemptIndex(a).compareTo(_attemptIndex(b)),
        );

  final List<AttemptResults> attempts = <AttemptResults>[];
  for (final Directory dir in dirs) {
    final List<File> reports =
        dir
            .listSync(recursive: true)
            .whereType<File>()
            .where((File file) => file.path.endsWith('.xml'))
            .toList()
          ..sort((File a, File b) => a.path.compareTo(b.path));
    if (reports.isEmpty) {
      continue;
    }
    final int attempt = _attemptIndex(dir);
    final Map<String, CaseAttempt> cases = <String, CaseAttempt>{};
    double durationMs = 0;
    for (final File report in reports) {
      durationMs += _readSuite(report, attempt, cases);
    }
    attempts.add(
      AttemptResults(attempt: attempt, cases: cases, durationMs: durationMs),
    );
  }
  return attempts;
}

/// Parses one JUnit report into [cases] and returns the suite time it reports.
double _readSuite(File report, int attempt, Map<String, CaseAttempt> cases) {
  final XmlDocument document;
  try {
    document = XmlDocument.parse(report.readAsStringSync());
  } on XmlException {
    // A truncated report means the run died mid-write. Dropping it loses one
    // attempt's detail; treating it as a suite of zero passes would invent a
    // green result that was never observed.
    stderr.writeln('⚠️  Skipping unparseable JUnit report: ${report.path}');
    return 0;
  }

  double durationMs = 0;
  for (final XmlElement suite in document.findAllElements('testsuite')) {
    durationMs += _seconds(suite.getAttribute('time'));
  }
  for (final XmlElement testCase in document.findAllElements('testcase')) {
    final String name = testCase.getAttribute('name') ?? 'unknown';
    final String? className = testCase.getAttribute('classname');
    final XmlElement? failure =
        testCase.getElement('failure') ?? testCase.getElement('error');
    final CaseStatus status = switch (failure) {
      null when testCase.getElement('skipped') != null => CaseStatus.skipped,
      null => CaseStatus.passed,
      _ => CaseStatus.failed,
    };
    cases['${className ?? ''}#$name'] = CaseAttempt(
      attempt: attempt,
      name: name,
      className: className,
      status: status,
      durationMs: _seconds(testCase.getAttribute('time')),
      failure: failure == null ? null : _failureMessage(failure),
    );
  }
  return durationMs;
}

String _failureMessage(XmlElement failure) {
  final String message =
      failure.getAttribute('message') ?? failure.innerText.trim();
  return message.length <= 500 ? message : '${message.substring(0, 500)}…';
}

double _seconds(String? value) =>
    ((double.tryParse(value ?? '') ?? 0) * 1000).roundToDouble();

/// Extracts the trailing integer from an `attempt-<n>` directory name.
int _attemptIndex(Directory directory) {
  final String? digits = RegExp(r'(\d+)$').firstMatch(directory.path)?.group(1);
  return digits == null ? 0 : int.parse(digits);
}
