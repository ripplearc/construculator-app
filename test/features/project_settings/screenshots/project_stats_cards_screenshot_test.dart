import 'package:construculator/features/project_settings/presentation/widgets/project_stats_cards.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/screenshot/font_loader.dart';

void main() {
  const size = Size(390, 90);
  const ratio = 1.0;
  const testName = 'project_stats_cards';
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await loadAppFontsAll();
  });

  Future<void> pumpProjectStatsCards({
    required WidgetTester tester,
    required int estimationCount,
    required int memberCount,
    ThemeData? theme,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme ?? createTestTheme(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (ctx) => Scaffold(
            backgroundColor: ctx.colorTheme.pageBackground,
            body: ProjectStatsCards(
              estimationCount: estimationCount,
              memberCount: memberCount,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('ProjectStatsCards Screenshot Tests - Light', () {
    testWidgets('renders with typical counts correctly', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);

      await pumpProjectStatsCards(
        tester: tester,
        estimationCount: 34,
        memberCount: 12,
      );

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile(
          'goldens/$testName/${size.width}x${size.height}/${testName}_typical_counts.png',
        ),
      );
    });

    testWidgets('renders with zero counts correctly', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);

      await pumpProjectStatsCards(
        tester: tester,
        estimationCount: 0,
        memberCount: 0,
      );

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile(
          'goldens/$testName/${size.width}x${size.height}/${testName}_zero_counts.png',
        ),
      );
    });

    testWidgets('renders with large counts correctly', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);

      await pumpProjectStatsCards(
        tester: tester,
        estimationCount: 1000,
        memberCount: 500,
      );

      await expectLater(
        find.byType(Scaffold),
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
      addTearDown(tester.view.reset);

      await pumpProjectStatsCards(
        tester: tester,
        estimationCount: 999999999999999,
        memberCount: 999999999999999,
      );

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile(
          'goldens/$testName/${size.width}x${size.height}/${testName}_overflow_counts.png',
        ),
      );
    });
  });

  group('ProjectStatsCards Screenshot Tests - Dark', () {
    testWidgets('renders with typical counts correctly', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);

      await pumpProjectStatsCards(
        tester: tester,
        estimationCount: 34,
        memberCount: 12,
        theme: createTestThemeDark(),
      );

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile(
          'goldens/$testName/${size.width}x${size.height}/${testName}_typical_counts_dark.png',
        ),
      );
    });

    testWidgets('renders with zero counts correctly', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);

      await pumpProjectStatsCards(
        tester: tester,
        estimationCount: 0,
        memberCount: 0,
        theme: createTestThemeDark(),
      );

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile(
          'goldens/$testName/${size.width}x${size.height}/${testName}_zero_counts_dark.png',
        ),
      );
    });

    testWidgets('renders with large counts correctly', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);

      await pumpProjectStatsCards(
        tester: tester,
        estimationCount: 1000,
        memberCount: 500,
        theme: createTestThemeDark(),
      );

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile(
          'goldens/$testName/${size.width}x${size.height}/${testName}_large_counts_dark.png',
        ),
      );
    });

    testWidgets('truncates extremely large counts without overflow', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);

      await pumpProjectStatsCards(
        tester: tester,
        estimationCount: 999999999999999,
        memberCount: 999999999999999,
        theme: createTestThemeDark(),
      );

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile(
          'goldens/$testName/${size.width}x${size.height}/${testName}_overflow_counts_dark.png',
        ),
      );
    });
  });
}
