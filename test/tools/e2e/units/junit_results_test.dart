import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../../../scripts/e2e/junit_results.dart';

void main() {
  late Directory attempts;

  setUp(() {
    attempts = Directory.systemTemp.createTempSync('junit_results_test');
  });

  tearDown(() {
    attempts.deleteSync(recursive: true);
  });

  String testCase(String name, {bool failed = false, double time = 1.5}) {
    final String body = failed
        ? '<failure message="expected true">stack</failure>'
        : '';
    return '<testcase name="$name" classname="CujTest" time="$time">'
        '$body</testcase>';
  }

  void writeAttempt(
    int attempt,
    String cases, {
    double time = 10,
    String file = 'TEST-cuj.xml',
  }) {
    final File report = File('${attempts.path}/attempt-$attempt/$file');
    report.parent.createSync(recursive: true);
    report.writeAsStringSync(
      '<?xml version="1.0"?><testsuite name="cuj" time="$time">$cases</testsuite>',
    );
  }

  CaseAttempt caseNamed(AttemptResults results, String name) {
    return results.cases.values.firstWhere(
      (CaseAttempt attempt) => attempt.name == name,
    );
  }

  test('reads every case in an attempt', () {
    writeAttempt(1, '${testCase('cuj1')}${testCase('cuj2')}');

    final AttemptResults results = readAttempts(attempts).single;

    expect(results.cases, hasLength(2));
    expect(caseNamed(results, 'cuj1').status, CaseStatus.passed);
    expect(caseNamed(results, 'cuj1').className, 'CujTest');
    expect(caseNamed(results, 'cuj1').durationMs, 1500.0);
  });

  test('reports the suite time as the attempt duration', () {
    writeAttempt(1, testCase('cuj1'), time: 42);

    expect(readAttempts(attempts).single.durationMs, 42000.0);
  });

  test('sums suite time across several reports in one attempt', () {
    writeAttempt(1, testCase('cuj1'), time: 10);
    writeAttempt(1, testCase('cuj2'), time: 5, file: 'TEST-other.xml');

    expect(readAttempts(attempts).single.durationMs, 15000.0);
  });

  test('captures the failure message on a failing case', () {
    writeAttempt(1, testCase('cuj1', failed: true));

    final CaseAttempt result = caseNamed(readAttempts(attempts).single, 'cuj1');

    expect(result.status, CaseStatus.failed);
    expect(result.failure, 'expected true');
  });

  test('treats an error element as a failure', () {
    writeAttempt(
      1,
      '<testcase name="cuj1" classname="CujTest" time="1">'
      '<error message="crashed"/></testcase>',
    );

    expect(caseNamed(readAttempts(attempts).single, 'cuj1').status,
        CaseStatus.failed);
  });

  test('distinguishes a skipped case from a passing one', () {
    writeAttempt(
      1,
      '<testcase name="cuj1" classname="CujTest" time="0"><skipped/></testcase>',
    );

    expect(caseNamed(readAttempts(attempts).single, 'cuj1').status,
        CaseStatus.skipped);
  });

  test('orders attempts numerically rather than lexically', () {
    for (int attempt = 1; attempt <= 10; attempt++) {
      writeAttempt(attempt, testCase('cuj1'));
    }

    expect(
      readAttempts(attempts).map((AttemptResults r) => r.attempt).toList(),
      <int>[1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
    );
  });

  test('skips an unparseable report rather than scoring it as a pass', () {
    final File report = File('${attempts.path}/attempt-1/TEST-cuj.xml');
    report.parent.createSync(recursive: true);
    report.writeAsStringSync('<testsuite><testcase name="cut off"');

    expect(readAttempts(attempts).single.cases, isEmpty);
  });

  test('ignores an attempt directory that produced no XML', () {
    Directory('${attempts.path}/attempt-1').createSync(recursive: true);

    expect(readAttempts(attempts), isEmpty);
  });

  test('returns nothing when the attempts directory was never created', () {
    expect(readAttempts(Directory('${attempts.path}/missing')), isEmpty);
  });

  test('truncates an overlong failure message', () {
    writeAttempt(
      1,
      '<testcase name="cuj1" classname="CujTest" time="1">'
      '<failure message="${'x' * 600}"/></testcase>',
    );

    expect(caseNamed(readAttempts(attempts).single, 'cuj1').failure,
        hasLength(501));
  });
}
