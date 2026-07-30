import 'package:construculator/features/app_header/presentation/widgets/notification_icon.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/screenshot/await_images_extension.dart';
import '../../../utils/screenshot/font_loader.dart';

void main() {
  const size = Size(56, 56);
  const ratio = 1.0;
  const testName = 'notification_icon';
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await loadAppFontsAll();
  });

  Future<void> pumpNotificationIcon({
    required WidgetTester tester,
    required int unreadCount,
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
            body: Center(child: NotificationIcon(unreadCount: unreadCount)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.awaitImages();
  }

  group('NotificationIcon Screenshot Tests - Light', () {
    testWidgets('renders without badge when unreadCount is zero', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);

      await pumpNotificationIcon(tester: tester, unreadCount: 0);

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile(
          'goldens/$testName/${size.width}x${size.height}/${testName}_no_badge.png',
        ),
      );
    });

    testWidgets('renders with badge when unreadCount is greater than zero', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);

      await pumpNotificationIcon(tester: tester, unreadCount: 3);

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile(
          'goldens/$testName/${size.width}x${size.height}/${testName}_with_badge.png',
        ),
      );
    });

    testWidgets('renders 99+ badge when unreadCount exceeds 99', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);

      await pumpNotificationIcon(tester: tester, unreadCount: 123);

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile(
          'goldens/$testName/${size.width}x${size.height}/${testName}_overflow_badge.png',
        ),
      );
    });
  });

  group('NotificationIcon Screenshot Tests - Dark', () {
    testWidgets('renders without badge when unreadCount is zero', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);

      await pumpNotificationIcon(
        tester: tester,
        unreadCount: 0,
        theme: createTestThemeDark(),
      );

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile(
          'goldens/$testName/${size.width}x${size.height}/${testName}_no_badge_dark.png',
        ),
      );
    });

    testWidgets('renders with badge when unreadCount is greater than zero', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);

      await pumpNotificationIcon(
        tester: tester,
        unreadCount: 3,
        theme: createTestThemeDark(),
      );

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile(
          'goldens/$testName/${size.width}x${size.height}/${testName}_with_badge_dark.png',
        ),
      );
    });

    testWidgets('renders 99+ badge when unreadCount exceeds 99', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);

      await pumpNotificationIcon(
        tester: tester,
        unreadCount: 123,
        theme: createTestThemeDark(),
      );

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile(
          'goldens/$testName/${size.width}x${size.height}/${testName}_overflow_badge_dark.png',
        ),
      );
    });
  });
}
