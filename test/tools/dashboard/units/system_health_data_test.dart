import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../../../scripts/dashboard/system_health_data.dart';
import '../../../../scripts/dashboard/trend_series.dart';

void main() {
  late Directory store;

  setUp(() {
    store = Directory.systemTemp.createTempSync('system_health_test');
  });

  tearDown(() {
    store.deleteSync(recursive: true);
  });

  void writeJson(String relativePath, Object? content) {
    final File file = File('${store.path}/$relativePath');
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(jsonEncode(content));
  }

  void writeIndex(List<Map<String, Object?>> runs) {
    writeJson('index.json', <String, Object?>{'runs': runs});
  }

  Map<String, Object?> indexEntry({
    String journey = 'pre_login_v1',
    String capturedAt = '2026-08-24T03:00:00Z',
    String commit = 'abc1234',
  }) {
    return <String, Object?>{
      'path': 'runs/$journey/$capturedAt-$commit.json',
      'journey': journey,
      'captured_at': capturedAt,
      'commit': commit,
    };
  }

  void writeRun({
    String journey = 'pre_login_v1',
    String capturedAt = '2026-08-24T03:00:00Z',
    String commit = 'abc1234',
    double cold = 800,
    Map<String, Object?>? memory,
  }) {
    writeJson('runs/$journey/$capturedAt-$commit.json', <String, Object?>{
      'journey': journey,
      'captured_at': capturedAt,
      'commit': commit,
      'metrics': <String, Object?>{
        'cold_start_ms': <String, Object?>{'median': cold},
        'warm_start_ms': <String, Object?>{'median': 300.0},
        'jank': <String, Object?>{
          'available': true,
          'p90_frame_build_ms': 12.5,
        },
        'memory': memory ?? <String, Object?>{'available': false},
      },
    });
  }

  MetricSeries metric(SystemHealthGroup group, String id) {
    return group.metrics.firstWhere((MetricSeries m) => m.id == id);
  }

  test('plots the five required metrics even when one has no producer', () {
    writeIndex(<Map<String, Object?>>[indexEntry()]);
    writeRun();

    final SystemHealthGroup group = loadSystemHealth(store).single;

    expect(group.metrics.map((MetricSeries m) => m.id).toList(), <String>[
      'cold_start_ms',
      'ttid_ms',
      'warm_start_ms',
      'memory',
      'jank',
    ]);
    expect(metric(group, 'ttid_ms').hasData, isFalse);
    expect(metric(group, 'cold_start_ms').points.single.value, 800.0);
    expect(metric(group, 'jank').points.single.value, 12.5);
  });

  test('reads a metric that reports itself unavailable as a gap', () {
    writeIndex(<Map<String, Object?>>[indexEntry()]);
    writeRun();

    expect(metric(loadSystemHealth(store).single, 'memory').hasData, isFalse);
  });

  test('reads an available metric block', () {
    writeIndex(<Map<String, Object?>>[indexEntry()]);
    writeRun(
      memory: <String, Object?>{'available': true, 'peak_rss_kb': 250000.0},
    );

    expect(
      metric(loadSystemHealth(store).single, 'memory').points.single.value,
      250000.0,
    );
  });

  test('keeps journeys as separate series rather than one trend', () {
    writeIndex(<Map<String, Object?>>[
      indexEntry(),
      indexEntry(journey: 'post_login_v1', commit: 'def5678'),
    ]);
    writeRun();
    writeRun(journey: 'post_login_v1', commit: 'def5678', cold: 1500);

    expect(
      loadSystemHealth(store).map((SystemHealthGroup g) => g.journey).toSet(),
      <String>{'pre_login_v1', 'post_login_v1'},
    );
  });

  test('orders points oldest first', () {
    writeIndex(<Map<String, Object?>>[
      indexEntry(capturedAt: '2026-08-31T03:00:00Z', commit: 'later'),
      indexEntry(capturedAt: '2026-08-24T03:00:00Z', commit: 'earlier'),
    ]);
    writeRun(capturedAt: '2026-08-31T03:00:00Z', commit: 'later');
    writeRun(capturedAt: '2026-08-24T03:00:00Z', commit: 'earlier');

    expect(
      metric(loadSystemHealth(store).single, 'cold_start_ms')
          .points
          .map((SeriesPoint p) => p.commit)
          .toList(),
      <String>['earlier', 'later'],
    );
  });

  test('reports no baseline when none has been recorded', () {
    writeIndex(<Map<String, Object?>>[indexEntry()]);
    writeRun();

    expect(
      metric(loadSystemHealth(store).single, 'cold_start_ms').baseline,
      isNull,
    );
  });

  test('attaches a recorded baseline to its own journey only', () {
    writeJson('baselines.json', <String, Object?>{
      'pre_login_v1': <String, Object?>{'cold_start_ms': 750},
    });
    writeIndex(<Map<String, Object?>>[
      indexEntry(),
      indexEntry(journey: 'post_login_v1', commit: 'def5678'),
    ]);
    writeRun();
    writeRun(journey: 'post_login_v1', commit: 'def5678');

    final List<SystemHealthGroup> groups = loadSystemHealth(store);
    SystemHealthGroup journey(String name) =>
        groups.firstWhere((SystemHealthGroup g) => g.journey == name);

    expect(metric(journey('pre_login_v1'), 'cold_start_ms').baseline, 750.0);
    expect(metric(journey('post_login_v1'), 'cold_start_ms').baseline, isNull);
  });

  test('returns nothing for a store that has never been written', () {
    expect(loadSystemHealth(store), isEmpty);
  });

  test('still plots the metric slots when a run file is missing', () {
    writeIndex(<Map<String, Object?>>[indexEntry()]);

    expect(loadSystemHealth(store).single.metrics, hasLength(5));
  });
}
