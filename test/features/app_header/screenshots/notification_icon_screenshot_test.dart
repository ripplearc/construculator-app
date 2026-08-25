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
    required ThemeData theme,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
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

  screenshotThemeGroups('NotificationIcon Screenshot Tests', (theme, suffix) {
    testWidgets('renders without badge when unreadCount is zero', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);

      await pumpNotificationIcon(
        tester: tester,
        unreadCount: 0,
        theme: theme,
      );

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile(
          'goldens/$testName/${size.width}x${size.height}/${testName}_no_badge$suffix.png',
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
        theme: theme,
      );

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile(
          'goldens/$testName/${size.width}x${size.height}/${testName}_with_badge$suffix.png',
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
        theme: theme,
      );

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile(
          'goldens/$testName/${size.width}x${size.height}/${testName}_overflow_badge$suffix.png',
        ),
      );
    });
  });
}
