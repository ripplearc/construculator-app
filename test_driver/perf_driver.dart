import 'dart:io';

import 'package:flutter_driver/flutter_driver.dart';
import 'package:integration_test/integration_test_driver.dart';

// The capture script overrides PERF_OUTPUT_DIR per run so each run's
// artifacts land in their own directory instead of overwriting the
// previous run's.
final String _outputDirectory =
    Platform.environment['PERF_OUTPUT_DIR'] ?? 'build/perf';

/// Driver for the performance journeys under `integration_test/perf/`.
///
/// Each entry the journey records via `traceAction` is summarised and written
/// as `<journey>.timeline.json` plus `<journey>.timeline_summary.json`.
Future<void> main() {
  return integrationDriver(
    responseDataCallback: (Map<String, dynamic>? data) async {
      if (data == null) {
        stderr.writeln('No timeline data was reported by the journey.');
        exitCode = 1;
        return;
      }
      for (final MapEntry<String, dynamic> entry in data.entries) {
        final Timeline timeline = Timeline.fromJson(
          entry.value as Map<String, dynamic>,
        );
        await TimelineSummary.summarize(timeline).writeTimelineToFile(
          entry.key,
          destinationDirectory: _outputDirectory,
          pretty: true,
        );
      }
    },
  );
}
