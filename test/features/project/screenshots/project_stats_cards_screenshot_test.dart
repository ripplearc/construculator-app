import 'package:construculator/features/project/presentation/widgets/project_stats_cards.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/screenshot/font_loader.dart';

void main() {
  final size = const Size(390, 90);
  final ratio = 1.0;
  final testName = 'project_stats_cards';
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await loadAppFontsAll();
  });

  group('ProjectStatsCards Screenshot Tests', () {
    Future<void> pumpProjectStatsCards({
      required WidgetTester tester,
      required int estimationCount,
      required int memberCount,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: createTestTheme(),
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Material(
            child: ProjectStatsCards(
              estimationCount: estimationCount,
              memberCount: memberCount,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('renders with typical counts correctly', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;

      await pumpProjectStatsCards(
        tester: tester,
        estimationCount: 34,
        memberCount: 12,
      );

      await expectLater(
        find.byType(ProjectStatsCards),
        matchesGoldenFile(
          'goldens/$testName/${size.width}x${size.height}/${testName}_typical_counts.png',
        ),
      );
    });

    testWidgets('renders with zero counts correctly', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;

      await pumpProjectStatsCards(
        tester: tester,
        estimationCount: 0,
        memberCount: 0,
      );

      await expectLater(
        find.byType(ProjectStatsCards),
        matchesGoldenFile(
          'goldens/$testName/${size.width}x${size.height}/${testName}_zero_counts.png',
        ),
      );
    });

    testWidgets('renders with large counts correctly', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;

      await pumpProjectStatsCards(
        tester: tester,
        estimationCount: 1000,
        memberCount: 500,
      );

      await expectLater(
        find.byType(ProjectStatsCards),
        matchesGoldenFile(
          'goldens/$testName/${size.width}x${size.height}/${testName}_large_counts.png',
        ),
      );
    });

    testWidgets('truncates extremely large counts without overflow', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;

      await pumpProjectStatsCards(
        tester: tester,
        estimationCount: 999999999999999,
        memberCount: 999999999999999,
      );

      await expectLater(
        find.byType(ProjectStatsCards),
        matchesGoldenFile(
          'goldens/$testName/${size.width}x${size.height}/${testName}_overflow_counts.png',
        ),
      );
    });
  });
}
