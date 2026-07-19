import 'package:construculator/features/app_header/presentation/widgets/profile_avatar.dart';
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

  Future<void> pumpProfileAvatar({
    required WidgetTester tester,
    required String name,
    String? imageUrl,
    ThemeData? theme,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme ?? createTestTheme(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: ProfileAvatar(name: name, imageUrl: imageUrl),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.awaitImages();
  }

  group('ProfileAvatar Screenshot Tests - Light', () {
    testWidgets('renders letter avatar for name starting with J', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);

      await pumpProfileAvatar(tester: tester, name: 'John');

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
      addTearDown(tester.view.reset);

      await pumpProfileAvatar(tester: tester, name: 'Alice');

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
      addTearDown(tester.view.reset);

      await pumpProfileAvatar(tester: tester, name: 'Bob', imageUrl: '');

      await expectLater(
        find.byType(ProfileAvatar),
        matchesGoldenFile(
          'goldens/$testName/${size.width}x${size.height}/${testName}_empty_url.png',
        ),
      );
    });
  });

  group('ProfileAvatar Screenshot Tests - Dark', () {
    testWidgets('renders letter avatar for name starting with J', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);

      await pumpProfileAvatar(
        tester: tester,
        name: 'John',
        theme: createTestThemeDark(),
      );

      await expectLater(
        find.byType(ProfileAvatar),
        matchesGoldenFile(
          'goldens/$testName/${size.width}x${size.height}/${testName}_letter_j_dark.png',
        ),
      );
    });

    testWidgets('renders letter avatar for name starting with A', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);

      await pumpProfileAvatar(
        tester: tester,
        name: 'Alice',
        theme: createTestThemeDark(),
      );

      await expectLater(
        find.byType(ProfileAvatar),
        matchesGoldenFile(
          'goldens/$testName/${size.width}x${size.height}/${testName}_letter_a_dark.png',
        ),
      );
    });

    testWidgets('renders letter avatar when imageUrl is empty', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);

      await pumpProfileAvatar(
        tester: tester,
        name: 'Bob',
        imageUrl: '',
        theme: createTestThemeDark(),
      );

      await expectLater(
        find.byType(ProfileAvatar),
        matchesGoldenFile(
          'goldens/$testName/${size.width}x${size.height}/${testName}_empty_url_dark.png',
        ),
      );
    });
  });
}
