import 'package:construculator/app/shell/widgets/notification_icon.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
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

  group('NotificationIcon Screenshot Tests', () {
    testWidgets('renders without badge when unreadCount is zero', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;

      await tester.pumpWidget(
        MaterialApp(
          theme: createTestTheme(),
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: Center(child: NotificationIcon(unreadCount: 0)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.awaitImages();

      await expectLater(
        find.byType(NotificationIcon),
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

      await tester.pumpWidget(
        MaterialApp(
          theme: createTestTheme(),
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: Center(child: NotificationIcon(unreadCount: 3)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.awaitImages();

      await expectLater(
        find.byType(NotificationIcon),
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

      await tester.pumpWidget(
        MaterialApp(
          theme: createTestTheme(),
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: Center(child: NotificationIcon(unreadCount: 123)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.awaitImages();

      await expectLater(
        find.byType(NotificationIcon),
        matchesGoldenFile(
          'goldens/$testName/${size.width}x${size.height}/${testName}_overflow_badge.png',
        ),
      );
    });
  });
}
