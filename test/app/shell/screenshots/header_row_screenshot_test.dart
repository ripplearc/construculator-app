import 'package:construculator/app/shell/widgets/header_row.dart';
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

  group('HeaderRow Screenshot Tests', () {
    testWidgets('renders default state with no notifications and no user', (
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
          home: Scaffold(
            appBar: HeaderRow(),
            body: const SizedBox.shrink(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.awaitImages();

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

      await tester.pumpWidget(
        MaterialApp(
          theme: createTestTheme(),
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            appBar: HeaderRow(unreadNotificationCount: 5),
            body: const SizedBox.shrink(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.awaitImages();

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

      await tester.pumpWidget(
        MaterialApp(
          theme: createTestTheme(),
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            appBar: HeaderRow(userName: 'John Doe'),
            body: const SizedBox.shrink(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.awaitImages();

      await expectLater(
        find.byType(HeaderRow),
        matchesGoldenFile(
          'goldens/$testName/${size.width}x${size.height}/${testName}_with_username.png',
        ),
      );
    });
  });
}
