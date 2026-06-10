import 'package:construculator/app/shell/widgets/profile_avatar.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/screenshot/await_images_extension.dart';
import '../../../utils/screenshot/font_loader.dart';

void main() {
  const size = Size(56, 56);
  const ratio = 1.0;
  const testName = 'profile_avatar';
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await loadAppFontsAll();
  });

  group('ProfileAvatar Screenshot Tests', () {
    testWidgets('renders letter avatar for name starting with J', (
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
            body: Center(child: ProfileAvatar(name: 'John')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.awaitImages();

      await expectLater(
        find.byType(ProfileAvatar),
        matchesGoldenFile(
          'goldens/$testName/${size.width}x${size.height}/${testName}_letter_j.png',
        ),
      );
    });

    testWidgets('renders letter avatar for name starting with A', (
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
            body: Center(child: ProfileAvatar(name: 'Alice')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.awaitImages();

      await expectLater(
        find.byType(ProfileAvatar),
        matchesGoldenFile(
          'goldens/$testName/${size.width}x${size.height}/${testName}_letter_a.png',
        ),
      );
    });

    testWidgets('renders letter avatar when imageUrl is empty', (
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
            body: Center(child: ProfileAvatar(name: 'Bob', imageUrl: '')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.awaitImages();

      await expectLater(
        find.byType(ProfileAvatar),
        matchesGoldenFile(
          'goldens/$testName/${size.width}x${size.height}/${testName}_empty_url.png',
        ),
      );
    });
  });
}
