import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../../../scripts/perf/build_perf_report.dart';

void main() {
  late Directory capture;

  setUp(() {
    capture = Directory.systemTemp.createTempSync('perf_report_test');
  });

  tearDown(() {
    capture.deleteSync(recursive: true);
  });

  /// Writes [json] to [relativePath] inside the fake capture directory.
  void writeArtifact(String relativePath, Object json) {
    final File file = File('${capture.path}/$relativePath');
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(jsonEncode(json));
  }

  void writeMeta({String journey = 'pre_login_v1'}) {
    writeArtifact('meta.json', <String, Object?>{
      'journey': journey,
      'device_id': 'lab-pixel-01',
      'flavor': 'fishfood',
      'iterations': 2,
      'flutter_version': 'Flutter 3.44.4',
      'commit': 'abc123',
      'captured_at': '2026-08-19T00:00:00Z',
    });
  }

  void writeStartup(String phase, int run, int micros) {
    writeArtifact('$phase/run-$run/start_up_info.json', <String, Object?>{
      'engineEnterTimestampMicros': 1000,
      'timeToFirstFrameRasterizedMicros': micros,
    });
  }

  Map<String, Object?> metricsOf(Map<String, Object?> report) {
    return report['metrics'] as Map<String, Object?>;
  }

  group('buildPerfReport', () {
    test('records the schema version and the journey from meta.json', () {
      writeMeta(journey: 'post_login_v1');

      final Map<String, Object?> report = buildPerfReport(capture);

      expect(report['schema_version'], perfRunSchemaVersion);
      expect(report['journey'], 'post_login_v1');
      expect(report['commit'], 'abc123');
    });

    test('reports the device model as unknown when it is not registered', () {
      writeMeta();

      final Map<String, Object?> report = buildPerfReport(capture);
      final Map<String, Object?> device = report['device'] as Map<String, Object?>;

      expect(device['id'], 'lab-pixel-01');
      expect(device['model'], isNull);
    });

    test('converts startup micros to millis and takes the median', () {
      writeMeta();
      writeStartup('cold', 1, 900000);
      writeStartup('cold', 2, 700000);
      writeStartup('cold', 3, 800000);

      final Map<String, Object?> cold =
          metricsOf(buildPerfReport(capture))['cold_start_ms']
              as Map<String, Object?>;

      expect(cold['median'], 800.0);
      expect(cold['samples'], <double>[900.0, 700.0, 800.0]);
    });

    test('averages the middle two samples for an even sample count', () {
      writeMeta();
      writeStartup('warm', 1, 100000);
      writeStartup('warm', 2, 200000);

      final Map<String, Object?> warm =
          metricsOf(buildPerfReport(capture))['warm_start_ms']
              as Map<String, Object?>;

      expect(warm['median'], 150.0);
    });

    test('orders runs numerically rather than lexicographically', () {
      writeMeta();
      writeStartup('cold', 2, 200000);
      writeStartup('cold', 10, 100000);

      final Map<String, Object?> cold =
          metricsOf(buildPerfReport(capture))['cold_start_ms']
              as Map<String, Object?>;

      expect(cold['samples'], <double>[200.0, 100.0]);
    });

    test('reads jank percentiles from the timeline summary', () {
      writeMeta();
      writeArtifact('jank/pre_login_v1.timeline_summary.json', <String, Object?>{
        'frame_count': 120,
        '90th_percentile_frame_build_time_millis': 9.5,
        '90th_percentile_frame_rasterizer_time_millis': 12.25,
        'missed_frame_build_budget_count': 3,
        'missed_frame_rasterizer_budget_count': 5,
      });

      final Map<String, Object?> jank =
          metricsOf(buildPerfReport(capture))['jank'] as Map<String, Object?>;

      expect(jank['available'], isTrue);
      expect(jank['frame_count'], 120);
      expect(jank['p90_frame_build_ms'], 9.5);
      expect(jank['p90_frame_rasterizer_ms'], 12.25);
      expect(jank['missed_frame_build_budget_count'], 3);
    });

    test('marks jank unavailable when the timeline summary is missing', () {
      writeMeta();

      final Map<String, Object?> jank =
          metricsOf(buildPerfReport(capture))['jank'] as Map<String, Object?>;

      expect(jank['available'], isFalse);
    });

    test('reports peak resident memory from the recorded samples', () {
      writeMeta();
      writeArtifact('memory/memory_profile.json', <String, Object?>{
        'samples': <Object?>[
          <String, Object?>{'rss': 1024},
          <String, Object?>{'rss': 4096},
          <String, Object?>{'rss': 2048},
        ],
      });

      final Map<String, Object?> memory =
          metricsOf(buildPerfReport(capture))['memory'] as Map<String, Object?>;

      expect(memory['available'], isTrue);
      expect(memory['peak_rss_kb'], 4.0);
      expect(memory['sample_count'], 3);
    });

    test('does not invent a number when the memory profile shape is unknown', () {
      writeMeta();
      writeArtifact('memory/memory_profile.json', <String, Object?>{
        'unexpected': 'shape',
      });

      final Map<String, Object?> memory =
          metricsOf(buildPerfReport(capture))['memory'] as Map<String, Object?>;

      expect(memory['available'], isFalse);
      expect(memory.containsKey('peak_rss_kb'), isFalse);
    });
  });

  group('median', () {
    test('returns null for no samples so an empty run reports nothing', () {
      expect(median(<double>[]), isNull);
    });

    test('ignores ordering of the supplied samples', () {
      expect(median(<double>[5, 1, 3]), 3.0);
    });
  });
}
