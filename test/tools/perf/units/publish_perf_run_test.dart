import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../../../scripts/perf/publish_perf_run.dart';

void main() {
  late Directory store;

  setUp(() {
    store = Directory.systemTemp.createTempSync('perf_store_test');
  });

  tearDown(() {
    store.deleteSync(recursive: true);
  });

  Map<String, Object?> runRecord({
    String journey = 'pre_login_v1',
    String capturedAt = '2026-08-19T03:00:00Z',
    String commit = 'abc123',
    double coldMedian = 800,
  }) {
    return <String, Object?>{
      'schema_version': 1,
      'journey': journey,
      'captured_at': capturedAt,
      'commit': commit,
      'device': <String, Object?>{'id': 'lab-01', 'model': null},
      'metrics': <String, Object?>{
        'cold_start_ms': <String, Object?>{'median': coldMedian},
        'warm_start_ms': <String, Object?>{'median': 300.0},
      },
    };
  }

  File writeRunFile(Map<String, Object?> run) {
    final File file = File('${store.path}/incoming/perf-run.json');
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(jsonEncode(run));
    return file;
  }

  Map<String, Object?> readIndex() {
    final Object? decoded = jsonDecode(
      File('${store.path}/index.json').readAsStringSync(),
    );
    return decoded as Map<String, Object?>;
  }

  List<Object?> indexRuns() {
    return readIndex()['runs'] as List<Object?>;
  }

  group('runRelativePath', () {
    test('partitions runs by journey so series stay separate', () {
      expect(
        runRelativePath(runRecord(journey: 'post_login_v1')),
        'runs/post_login_v1/2026-08-19T03-00-00Z-abc123.json',
      );
    });

    test('files a record with no journey under a stable placeholder', () {
      expect(
        runRelativePath(<String, Object?>{'commit': 'abc'}),
        'runs/unknown/unknown-abc.json',
      );
    });

    test('replaces characters that are unsafe in a filename', () {
      final String path = runRelativePath(
        runRecord(capturedAt: '2026/08/19 03:00'),
      );

      expect(path.contains('/2026-08-19-03-00-'), isTrue);
    });
  });

  group('publishRun', () {
    test('writes the run to its canonical location', () {
      final File published = publishRun(writeRunFile(runRecord()), store);

      expect(published.existsSync(), isTrue);
      expect(
        published.path,
        '${store.path}/runs/pre_login_v1/2026-08-19T03-00-00Z-abc123.json',
      );
    });

    test('overwrites rather than duplicating when the same run is retried', () {
      final File runFile = writeRunFile(runRecord());
      publishRun(runFile, store);
      publishRun(runFile, store);
      rebuildIndex(store);

      expect(indexRuns().length, 1);
    });
  });

  group('rebuildIndex', () {
    test('summarises every stored run', () {
      publishRun(writeRunFile(runRecord()), store);
      rebuildIndex(store);

      final Map<String, Object?> entry = indexRuns().first as Map<String, Object?>;

      expect(entry['journey'], 'pre_login_v1');
      expect(entry['commit'], 'abc123');
      expect(entry['device_id'], 'lab-01');
      expect(entry['cold_start_median_ms'], 800.0);
      expect(entry['warm_start_median_ms'], 300.0);
      expect(entry['path'], 'runs/pre_login_v1/2026-08-19T03-00-00Z-abc123.json');
    });

    test('orders runs chronologically across journeys', () {
      publishRun(
        writeRunFile(
          runRecord(capturedAt: '2026-08-26T03:00:00Z', commit: 'later'),
        ),
        store,
      );
      publishRun(
        writeRunFile(
          runRecord(
            journey: 'post_login_v1',
            capturedAt: '2026-08-12T03:00:00Z',
            commit: 'earlier',
          ),
        ),
        store,
      );
      rebuildIndex(store);

      final List<Object?> runs = indexRuns();
      final Map<String, Object?> first = runs.first as Map<String, Object?>;
      final Map<String, Object?> last = runs.last as Map<String, Object?>;

      expect(runs.length, 2);
      expect(first['commit'], 'earlier');
      expect(last['commit'], 'later');
    });

    test('reports an empty store rather than failing', () {
      expect(rebuildIndex(store), 0);
      expect(readIndex()['run_count'], 0);
      expect(indexRuns(), isEmpty);
    });

    test('repairs an index that was hand-edited', () {
      publishRun(writeRunFile(runRecord()), store);
      File('${store.path}/index.json').writeAsStringSync('{"runs": "garbage"}');

      expect(rebuildIndex(store), 1);
      expect(indexRuns().length, 1);
    });
  });
}
