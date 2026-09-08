import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../../../scripts/dashboard/trend_series.dart';

void main() {
  late Directory store;

  setUp(() {
    store = Directory.systemTemp.createTempSync('trend_series_test');
  });

  tearDown(() {
    store.deleteSync(recursive: true);
  });

  void writeJson(String relativePath, Object? content) {
    final File file = File('${store.path}/$relativePath');
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(jsonEncode(content));
  }

  Map<String, Object?> entry(String capturedAt, String commit) {
    return <String, Object?>{
      'path': 'runs/pre_login_v1/$capturedAt-$commit.json',
      'journey': 'pre_login_v1',
      'captured_at': capturedAt,
      'commit': commit,
    };
  }

  group('readIndexRuns', () {
    test('orders entries oldest first regardless of stored order', () {
      writeJson('index.json', <String, Object?>{
        'runs': <Object?>[
          entry('2026-08-31T03:00:00Z', 'later'),
          entry('2026-08-24T03:00:00Z', 'earlier'),
        ],
      });

      expect(
        readIndexRuns(store).map((Map<String, Object?> e) => e['commit']),
        <String>['earlier', 'later'],
      );
    });

    test('returns nothing for a store that has never been written', () {
      expect(readIndexRuns(store), isEmpty);
    });

    test('returns nothing when the index was caught mid-write', () {
      File('${store.path}/index.json').writeAsStringSync('{"runs": [');

      expect(readIndexRuns(store), isEmpty);
    });

    test('ignores index entries that are not objects', () {
      writeJson('index.json', <String, Object?>{
        'runs': <Object?>['not-a-run', entry('2026-08-24T03:00:00Z', 'ok')],
      });

      expect(readIndexRuns(store), hasLength(1));
    });
  });

  group('readRunRecord', () {
    test('prefers the full run file over the index entry', () {
      final Map<String, Object?> indexEntry = entry(
        '2026-08-24T03:00:00Z',
        'abc',
      );
      writeJson('${indexEntry['path']}', <String, Object?>{
        'commit': 'abc',
        'metrics': <String, Object?>{'cold_start_ms': <String, Object?>{}},
      });

      expect(readRunRecord(store, indexEntry).containsKey('metrics'), isTrue);
    });

    test('falls back to the index entry when the run file is missing', () {
      final Map<String, Object?> indexEntry = entry(
        '2026-08-24T03:00:00Z',
        'abc',
      );

      expect(readRunRecord(store, indexEntry), same(indexEntry));
    });

    test('falls back to the index entry when the run file is unreadable', () {
      final Map<String, Object?> indexEntry = entry(
        '2026-08-24T03:00:00Z',
        'abc',
      );
      final File file = File('${store.path}/${indexEntry['path']}');
      file.parent.createSync(recursive: true);
      file.writeAsStringSync('{ truncated');

      expect(readRunRecord(store, indexEntry), same(indexEntry));
    });

    test('falls back to the index entry when the run file is invalid UTF-8', () {
      final Map<String, Object?> indexEntry = entry(
        '2026-08-24T03:00:00Z',
        'abc',
      );
      final File file = File('${store.path}/${indexEntry['path']}');
      file.parent.createSync(recursive: true);
      file.writeAsBytesSync(<int>[0x7B, 0x22, 0xFF, 0xFE]);

      expect(readRunRecord(store, indexEntry), same(indexEntry));
    });
  });

  group('groupRunsBy', () {
    test('keeps each key in its own group', () {
      final Map<String, List<Map<String, Object?>>> grouped = groupRunsBy(
        <Map<String, Object?>>[
          <String, Object?>{'suite': 'cuj_v1'},
          <String, Object?>{'suite': 'cuj_v2'},
          <String, Object?>{'suite': 'cuj_v1'},
        ],
        'suite',
      );

      expect(grouped.keys.toSet(), <String>{'cuj_v1', 'cuj_v2'});
      expect(grouped['cuj_v1'], hasLength(2));
    });

    test('groups entries missing the key under a single bucket', () {
      final Map<String, List<Map<String, Object?>>> grouped = groupRunsBy(
        <Map<String, Object?>>[<String, Object?>{}, <String, Object?>{}],
        'suite',
      );

      expect(grouped, hasLength(1));
    });
  });

  group('MetricSeries', () {
    test('reports no data when every point is a gap', () {
      final MetricSeries series = MetricSeries(
        id: 'ttid_ms',
        label: 'TTID',
        unit: 'ms',
        points: <SeriesPoint>[
          SeriesPoint(capturedAt: '2026-08-24T03:00:00Z'),
        ],
      );

      expect(series.hasData, isFalse);
    });

    test('reports data when any point carries a value', () {
      final MetricSeries series = MetricSeries(
        id: 'cold_start_ms',
        label: 'Cold start',
        unit: 'ms',
        points: <SeriesPoint>[
          SeriesPoint(capturedAt: '2026-08-24T03:00:00Z'),
          SeriesPoint(capturedAt: '2026-08-31T03:00:00Z', value: 800),
        ],
      );

      expect(series.hasData, isTrue);
    });
  });
}
