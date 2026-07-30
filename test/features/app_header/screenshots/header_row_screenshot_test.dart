import 'package:construculator/features/app_header/presentation/widgets/header_row.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/screenshot/await_images_extension.dart';
import '../../../utils/screenshot/font_loader.dart';

void main() {
  const size = Size(390, 64);
  const ratio = 1.0;
  const testName = 'header_row';
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await loadAppFontsAll();
  });

  Future<void> pumpHeaderRow({
    required WidgetTester tester,
    ThemeData? theme,
    int? unreadNotificationCount,
    String? userName,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme ?? createTestTheme(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          appBar: HeaderRow(
            unreadNotificationCount: unreadNotificationCount ?? 0,
            userName: userName ?? '',
          ),
          body: const SizedBox.shrink(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.awaitImages();
  }

  group('HeaderRow Screenshot Tests - Light', () {
    testWidgets('renders default state with no notifications and no user', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);

      await pumpHeaderRow(tester: tester);

      await expectLater(
        find.byType(HeaderRow),
        matchesGoldenFile(
          'goldens/$testName/${size.width}x${size.height}/${testName}_default.png',
        ),
      );
    });

    testWidgets('renders with unread notification badge', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);

      await pumpHeaderRow(tester: tester, unreadNotificationCount: 5);

      await expectLater(
        find.byType(HeaderRow),
        matchesGoldenFile(
          'goldens/$testName/${size.width}x${size.height}/${testName}_with_badge.png',
        ),
      );
    });

    testWidgets('renders with username for profile letter avatar', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);

      await pumpHeaderRow(tester: tester, userName: 'John Doe');

      await expectLater(
        find.byType(HeaderRow),
        matchesGoldenFile(
          'goldens/$testName/${size.width}x${size.height}/${testName}_with_username.png',
        ),
      );
    });
  });

  group('HeaderRow Screenshot Tests - Dark', () {
    testWidgets('renders default state with no notifications and no user', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);

      await pumpHeaderRow(tester: tester, theme: createTestThemeDark());

      await expectLater(
        find.byType(HeaderRow),
        matchesGoldenFile(
          'goldens/$testName/${size.width}x${size.height}/${testName}_default_dark.png',
        ),
      );
    });

    testWidgets('renders with unread notification badge', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);

      await pumpHeaderRow(
        tester: tester,
        unreadNotificationCount: 5,
        theme: createTestThemeDark(),
      );

      await expectLater(
        find.byType(HeaderRow),
        matchesGoldenFile(
          'goldens/$testName/${size.width}x${size.height}/${testName}_with_badge_dark.png',
        ),
      );
    });

    testWidgets('renders with username for profile letter avatar', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);

      await pumpHeaderRow(
        tester: tester,
        userName: 'John Doe',
        theme: createTestThemeDark(),
      );

      await expectLater(
        find.byType(HeaderRow),
        matchesGoldenFile(
          'goldens/$testName/${size.width}x${size.height}/${testName}_with_username_dark.png',
        ),
      );
    });
  });
}
