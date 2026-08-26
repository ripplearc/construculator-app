// Builds the trend dashboard page from both raw stores.
//
// Knows nothing about git; scripts/dashboard/build_and_publish_dashboard.sh
// checks the two store branches out and hands this tool their directories.
//
// A store directory that does not exist reads as empty rather than failing, so
// the page can be built and published before either store has its first run.
//
// Usage:
//   dart scripts/dashboard/build_dashboard.dart \
//     --perf-store <dir> --e2e-store <dir> --output <file>

import 'dart:io';

import 'e2e_data.dart';
import 'render_dashboard.dart';
import 'system_health_data.dart';

Future<void> main(List<String> args) async {
  final Map<String, String> options = <String, String>{};
  for (int i = 0; i + 1 < args.length; i += 2) {
    options[args[i]] = args[i + 1];
  }
  final String? output = options['--output'];
  if (output == null) {
    stderr.writeln(
      'Usage: build_dashboard.dart --output <file> '
      '[--perf-store <dir>] [--e2e-store <dir>]',
    );
    exitCode = 1;
    return;
  }

  final String html = renderDashboard(
    systemHealth: loadSystemHealth(Directory(options['--perf-store'] ?? '')),
    e2e: loadE2e(Directory(options['--e2e-store'] ?? '')),
    generatedAt: DateTime.now().toUtc().toIso8601String(),
  );

  final File outputFile = File(output)..parent.createSync(recursive: true);
  outputFile.writeAsStringSync(html);
  stdout.writeln('✅ Wrote ${outputFile.path} (${html.length} bytes)');
}
