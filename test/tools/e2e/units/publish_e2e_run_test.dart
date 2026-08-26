import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../../../scripts/e2e/publish_e2e_run.dart';

void main() {
  late Directory store;

  setUp(() {
    store = Directory.systemTemp.createTempSync('e2e_store_test');
  });

  tearDown(() {
    store.deleteSync(recursive: true);
  });

  Map<String, Object?> runRecord({
    String suite = 'cuj_v1',
    String capturedAt = '2026-08-24T03:00:00Z',
    String commit = 'abc1234',
    double passRate = 1.0,
    double flakeRate = 0.0,
  }) {
    return <String, Object?>{
      'schema_version': 1,
      'suite': suite,
      'captured_at': capturedAt,
      'commit': commit,
      'attempt_count': 1,
      'duration_ms': 20000.0,
      'totals': <String, Object?>{
        'cases': 2,
        'ran': 2,
        'passed': 2,
        'flaked': 0,
        'failed': 0,
        'pass_rate': passRate,
        'flake_rate': flakeRate,
      },
      'cases': <Object?>[],
    };
  }

  File writeRunFile(Map<String, Object?> run) {
    final File file = File('${store.path}/incoming/e2e-run.json');
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(jsonEncode(run));
    return file;
  }

  List<Object?> indexRuns() {
    final Object? decoded = jsonDecode(
      File('${store.path}/index.json').readAsStringSync(),
    );
    return (decoded as Map<String, Object?>)['runs'] as List<Object?>;
  }

  group('runRelativePath', () {
    test('partitions runs by suite so series stay separate', () {
      expect(
        runRelativePath(runRecord(suite: 'cuj_v2')),
        'runs/cuj_v2/2026-08-24T03-00-00Z-abc1234.json',
      );
    });

    test('files a record with no suite under a stable placeholder', () {
      expect(
        runRelativePath(<String, Object?>{'commit': 'abc'}),
        'runs/unknown/unknown-abc.json',
      );
    });

    test('replaces characters that are unsafe in a filename', () {
      expect(
        runRelativePath(runRecord(capturedAt: '2026/08/24 03:00')),
        contains('/2026-08-24-03-00-'),
      );
    });
  });

  group('publishRun', () {
    test('writes the run to its canonical location', () {
      final File published = publishRun(writeRunFile(runRecord()), store);

      expect(
        published.path,
        '${store.path}/runs/cuj_v1/2026-08-24T03-00-00Z-abc1234.json',
      );
    });

    test('overwrites rather than duplicating when the same run is retried', () {
      final File runFile = writeRunFile(runRecord());
      publishRun(runFile, store);
      publishRun(runFile, store);
      rebuildIndex(store);

      expect(indexRuns(), hasLength(1));
    });
  });

  group('rebuildIndex', () {
    test('lifts the headline rates so the dashboard need not open runs', () {
      publishRun(writeRunFile(runRecord(passRate: 0.9, flakeRate: 0.2)), store);
      rebuildIndex(store);

      final Map<String, Object?> entry =
          indexRuns().single as Map<String, Object?>;

      expect(entry['suite'], 'cuj_v1');
      expect(entry['commit'], 'abc1234');
      expect(entry['pass_rate'], 0.9);
      expect(entry['flake_rate'], 0.2);
      expect(entry['duration_ms'], 20000.0);
      expect(entry['path'], 'runs/cuj_v1/2026-08-24T03-00-00Z-abc1234.json');
    });

    test('orders runs chronologically across suites', () {
      publishRun(
        writeRunFile(
          runRecord(
            suite: 'cuj_v2',
            capturedAt: '2026-08-31T03:00:00Z',
            commit: 'later',
          ),
        ),
        store,
      );
      publishRun(
        writeRunFile(
          runRecord(capturedAt: '2026-08-24T03:00:00Z', commit: 'earlier'),
        ),
        store,
      );
      rebuildIndex(store);

      expect(
        indexRuns()
            .cast<Map<String, Object?>>()
            .map((Map<String, Object?> e) => e['commit'])
            .toList(),
        <String>['earlier', 'later'],
      );
    });

    test('repairs an index that was truncated mid-write', () {
      publishRun(writeRunFile(runRecord()), store);
      File('${store.path}/index.json').writeAsStringSync('{"runs": [');

      expect(rebuildIndex(store), 1);
      expect(indexRuns(), hasLength(1));
    });

    test('writes an empty index when the store holds no runs', () {
      expect(rebuildIndex(store), 0);
      expect(indexRuns(), isEmpty);
    });

    test('records nulls rather than guesses for a run missing its totals', () {
      final Map<String, Object?> run = runRecord()..remove('totals');
      publishRun(writeRunFile(run), store);
      rebuildIndex(store);

      final Map<String, Object?> entry =
          indexRuns().single as Map<String, Object?>;

      expect(entry.containsKey('pass_rate'), isTrue);
      expect(entry['pass_rate'], isNull);
    });
  });
}
