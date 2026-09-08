import 'package:construculator/features/auth/presentation/widgets/auth_provider_buttons.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/screenshot/font_loader.dart';

void main() {
  final size = const Size(390, 300);
  final ratio = 1.0;
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await loadAppFonts();
  });

  Future<void> pumpAuthProviderButtons({
    required WidgetTester tester,
    required bool isEmailAuth,
    required ThemeData theme,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (ctx) => Scaffold(
            backgroundColor: ctx.colorTheme.pageBackground,
            body: Container(
              margin: const EdgeInsets.only(top: 16),
              child: AuthProviderButtons(
                onPressed: (_) {},
                isEmailAuth: isEmailAuth,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  screenshotThemeGroups('AuthProviderButtons Screenshot Tests', (
    theme,
    suffix,
  ) {
    testWidgets('renders email auth mode correctly', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);
      await pumpAuthProviderButtons(
        tester: tester,
        isEmailAuth: true,
        theme: theme,
      );

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile(
          'goldens/auth_provider_buttons/${size.width}x${size.height}/auth_provider_buttons_email_auth$suffix.png',
        ),
      );
    });

    testWidgets('renders phone auth mode correctly', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);
      await pumpAuthProviderButtons(
        tester: tester,
        isEmailAuth: false,
        theme: theme,
      );

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile(
          'goldens/auth_provider_buttons/${size.width}x${size.height}/auth_provider_buttons_phone_auth$suffix.png',
        ),
      );
    });
  });
}
