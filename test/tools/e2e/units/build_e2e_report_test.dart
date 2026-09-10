import 'package:flutter_test/flutter_test.dart';

import '../../../../scripts/e2e/build_e2e_report.dart';
import '../../../../scripts/e2e/junit_results.dart';

void main() {
  CaseAttempt result(
    int attempt,
    String name,
    CaseStatus status, {
    double durationMs = 1500,
  }) {
    return CaseAttempt(
      attempt: attempt,
      name: name,
      className: 'CujTest',
      status: status,
      durationMs: durationMs,
    );
  }

  AttemptResults attemptOf(
    int attempt,
    List<CaseAttempt> cases, {
    double durationMs = 10000,
  }) {
    return AttemptResults(
      attempt: attempt,
      durationMs: durationMs,
      cases: <String, CaseAttempt>{
        for (final CaseAttempt c in cases) 'CujTest#${c.name}': c,
      },
    );
  }

  Map<String, Object?> totalsOf(List<AttemptResults> attempts) {
    return summariseTotals(summariseCases(attempts));
  }

  group('summariseCases', () {
    test('marks a case that failed then passed as flaked, not failed', () {
      final List<Map<String, Object?>> cases = summariseCases(<AttemptResults>[
        attemptOf(1, <CaseAttempt>[result(1, 'cuj1', CaseStatus.failed)]),
        attemptOf(2, <CaseAttempt>[result(2, 'cuj1', CaseStatus.passed)]),
      ]);

      expect(cases.single, containsPair('status', 'flaked'));
    });

    test('marks a case that never recovered as failed', () {
      final List<Map<String, Object?>> cases = summariseCases(<AttemptResults>[
        attemptOf(1, <CaseAttempt>[result(1, 'cuj1', CaseStatus.failed)]),
        attemptOf(2, <CaseAttempt>[result(2, 'cuj1', CaseStatus.failed)]),
      ]);

      expect(cases.single, containsPair('status', 'failed'));
    });

    test('marks a case that was green throughout as passed', () {
      final List<Map<String, Object?>> cases = summariseCases(<AttemptResults>[
        attemptOf(1, <CaseAttempt>[result(1, 'cuj1', CaseStatus.passed)]),
        attemptOf(2, <CaseAttempt>[result(2, 'cuj1', CaseStatus.passed)]),
      ]);

      expect(cases.single, containsPair('status', 'passed'));
    });

    test('keeps every attempt of a case for later inspection', () {
      final List<Map<String, Object?>> cases = summariseCases(<AttemptResults>[
        attemptOf(1, <CaseAttempt>[result(1, 'cuj1', CaseStatus.failed)]),
        attemptOf(2, <CaseAttempt>[result(2, 'cuj1', CaseStatus.passed)]),
      ]);
      final List<Object?> attempts = cases.single['attempts'] as List<Object?>;

      expect(attempts, hasLength(2));
      expect((attempts.first as Map<String, Object?>)['status'], 'failed');
      expect((attempts.last as Map<String, Object?>)['status'], 'passed');
    });

    test('takes the duration from the attempt that decided the case', () {
      final List<Map<String, Object?>> cases = summariseCases(<AttemptResults>[
        attemptOf(1, <CaseAttempt>[
          result(1, 'cuj1', CaseStatus.failed, durationMs: 9000),
        ]),
        attemptOf(2, <CaseAttempt>[
          result(2, 'cuj1', CaseStatus.passed, durationMs: 4000),
        ]),
      ]);

      expect(cases.single, containsPair('duration_ms', 4000.0));
    });
  });

  group('summariseTotals', () {
    test('counts a clean run as a full pass rate with no flake', () {
      final Map<String, Object?> totals = totalsOf(<AttemptResults>[
        attemptOf(1, <CaseAttempt>[
          result(1, 'cuj1', CaseStatus.passed),
          result(1, 'cuj2', CaseStatus.passed),
        ]),
      ]);

      expect(totals, containsPair('pass_rate', 1.0));
      expect(totals, containsPair('flake_rate', 0.0));
    });

    test('keeps a flaked case in the pass rate but surfaces it as flake', () {
      final Map<String, Object?> totals = totalsOf(<AttemptResults>[
        attemptOf(1, <CaseAttempt>[
          result(1, 'cuj1', CaseStatus.failed),
          result(1, 'cuj2', CaseStatus.passed),
        ]),
        attemptOf(2, <CaseAttempt>[
          result(2, 'cuj1', CaseStatus.passed),
          result(2, 'cuj2', CaseStatus.passed),
        ]),
      ]);

      expect(totals, containsPair('pass_rate', 1.0));
      expect(totals, containsPair('flake_rate', 0.5));
      expect(totals, containsPair('failed', 0));
    });

    test('drops the pass rate for a case that never recovered', () {
      final Map<String, Object?> totals = totalsOf(<AttemptResults>[
        attemptOf(1, <CaseAttempt>[
          result(1, 'cuj1', CaseStatus.failed),
          result(1, 'cuj2', CaseStatus.passed),
        ]),
      ]);

      expect(totals, containsPair('pass_rate', 0.5));
    });

    test('excludes skipped cases from both rates', () {
      final Map<String, Object?> totals = totalsOf(<AttemptResults>[
        attemptOf(1, <CaseAttempt>[
          result(1, 'cuj1', CaseStatus.passed),
          result(1, 'cuj2', CaseStatus.skipped),
        ]),
      ]);

      expect(totals, containsPair('cases', 2));
      expect(totals, containsPair('ran', 1));
      expect(totals, containsPair('skipped', 1));
      expect(totals, containsPair('pass_rate', 1.0));
    });

    test('reports null rates rather than zero when nothing ran', () {
      expect(totalsOf(<AttemptResults>[]), containsPair('pass_rate', null));
      expect(totalsOf(<AttemptResults>[]), containsPair('flake_rate', null));
    });
  });

  group('buildE2eReport', () {
    test('reports the final attempt as the run duration', () {
      final Map<String, Object?> report = assembleReport(<AttemptResults>[
        attemptOf(1, <CaseAttempt>[
          result(1, 'cuj1', CaseStatus.failed),
        ], durationMs: 30000),
        attemptOf(2, <CaseAttempt>[
          result(2, 'cuj1', CaseStatus.passed),
        ], durationMs: 20000),
      ], suite: 'cuj_v1', capturedAt: '2026-08-24T03:00:00Z', commit: 'abc1234');

      expect(report, containsPair('duration_ms', 20000.0));
      expect(report, containsPair('total_duration_ms', 50000.0));
      expect(report, containsPair('attempt_count', 2));
    });

    test('stamps the record with its schema version and identity', () {
      final Map<String, Object?> report = assembleReport(
        <AttemptResults>[],
        suite: 'cuj_v1',
        capturedAt: '2026-08-24T03:00:00Z',
        commit: 'abc1234',
      );

      expect(report, containsPair('schema_version', e2eRunSchemaVersion));
      expect(report, containsPair('suite', 'cuj_v1'));
      expect(report, containsPair('commit', 'abc1234'));
      expect(report, containsPair('duration_ms', null));
    });
  });
}
