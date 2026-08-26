import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../../../scripts/dashboard/e2e_data.dart';
import '../../../../scripts/dashboard/trend_series.dart';

void main() {
  late Directory store;

  setUp(() {
    store = Directory.systemTemp.createTempSync('e2e_data_test');
  });

  tearDown(() {
    store.deleteSync(recursive: true);
  });

  void writeJson(String relativePath, Object? content) {
    final File file = File('${store.path}/$relativePath');
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(jsonEncode(content));
  }

  Map<String, Object?> indexEntry({
    String suite = 'cuj_v1',
    String capturedAt = '2026-08-24T03:00:00Z',
    String commit = 'abc1234',
    double passRate = 1.0,
    double flakeRate = 0.0,
  }) {
    return <String, Object?>{
      'path': 'runs/$suite/$capturedAt-$commit.json',
      'suite': suite,
      'captured_at': capturedAt,
      'commit': commit,
      'pass_rate': passRate,
      'flake_rate': flakeRate,
      'duration_ms': 20000.0,
    };
  }

  void writeIndex(List<Map<String, Object?>> runs) {
    writeJson('index.json', <String, Object?>{'runs': runs});
  }

  void writeRun(
    List<Map<String, Object?>> cases, {
    String suite = 'cuj_v1',
    String capturedAt = '2026-08-24T03:00:00Z',
    String commit = 'abc1234',
  }) {
    writeJson('runs/$suite/$capturedAt-$commit.json', <String, Object?>{
      'suite': suite,
      'captured_at': capturedAt,
      'commit': commit,
      'cases': cases,
    });
  }

  Map<String, Object?> caseRow(String name, String status) {
    return <String, Object?>{'name': name, 'status': status};
  }

  double? valueOf(E2eGroup group, String id) {
    return group.metrics
        .firstWhere((MetricSeries m) => m.id == id)
        .points
        .single
        .value;
  }

  test('converts stored rates to percentages and duration to seconds', () {
    writeIndex(<Map<String, Object?>>[
      indexEntry(passRate: 0.9, flakeRate: 0.25),
    ]);
    writeRun(<Map<String, Object?>>[]);

    final E2eGroup group = loadE2e(store).single;

    expect(valueOf(group, 'pass_rate'), 90.0);
    expect(valueOf(group, 'flake_rate'), 25.0);
    expect(valueOf(group, 'duration_ms'), 20.0);
  });

  test('plots a run with no recorded rate as a gap', () {
    writeIndex(<Map<String, Object?>>[
      <String, Object?>{
        'path': 'runs/cuj_v1/x.json',
        'suite': 'cuj_v1',
        'captured_at': '2026-08-24T03:00:00Z',
      },
    ]);

    expect(valueOf(loadE2e(store).single, 'pass_rate'), isNull);
  });

  test('counts failures and flakes per CUJ across runs', () {
    writeIndex(<Map<String, Object?>>[
      indexEntry(commit: 'first'),
      indexEntry(capturedAt: '2026-08-31T03:00:00Z', commit: 'second'),
    ]);
    writeRun(<Map<String, Object?>>[
      caseRow('cuj1', 'failed'),
      caseRow('cuj2', 'passed'),
    ], commit: 'first');
    writeRun(<Map<String, Object?>>[
      caseRow('cuj1', 'flaked'),
      caseRow('cuj2', 'passed'),
    ], capturedAt: '2026-08-31T03:00:00Z', commit: 'second');

    final CujSummary cuj1 = loadE2e(store).single.cujs.firstWhere(
      (CujSummary c) => c.name == 'cuj1',
    );

    expect(cuj1.runs, 2);
    expect(cuj1.failures, 1);
    expect(cuj1.flakes, 1);
    expect(cuj1.lastStatus, 'flaked');
    expect(cuj1.failuresPerRun, <int>[1, 0]);
  });

  test('keeps a CUJ that only ever flaked out of the failure count', () {
    writeIndex(<Map<String, Object?>>[indexEntry()]);
    writeRun(<Map<String, Object?>>[caseRow('cuj1', 'flaked')]);

    final CujSummary cuj1 = loadE2e(store).single.cujs.single;

    expect(cuj1.failures, 0);
    expect(cuj1.flakes, 1);
  });

  test('lists CUJs alphabetically so rows are stable between builds', () {
    writeIndex(<Map<String, Object?>>[indexEntry()]);
    writeRun(<Map<String, Object?>>[
      caseRow('zebra', 'passed'),
      caseRow('alpha', 'passed'),
    ]);

    expect(
      loadE2e(store).single.cujs.map((CujSummary c) => c.name).toList(),
      <String>['alpha', 'zebra'],
    );
  });

  test('keeps suites as separate series', () {
    writeIndex(<Map<String, Object?>>[
      indexEntry(),
      indexEntry(suite: 'cuj_v2', commit: 'def5678'),
    ]);
    writeRun(<Map<String, Object?>>[]);
    writeRun(<Map<String, Object?>>[], suite: 'cuj_v2', commit: 'def5678');

    expect(loadE2e(store).map((E2eGroup g) => g.suite).toSet(), <String>{
      'cuj_v1',
      'cuj_v2',
    });
  });

  test('returns nothing for a store that has never been written', () {
    expect(loadE2e(store), isEmpty);
  });
}
