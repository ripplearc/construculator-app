import 'package:construculator/features/auth/presentation/widgets/auth_provider_buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';

import '../../../../helpers/screenshot/font_loader.dart';

void main() {
  final size = const Size(390, 300);
  final ratio = 1.0;
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await loadAppFonts();
  });

  group('AuthProviderButtons Screenshot Tests', () {
    Future<void> pumpAuthProviderButtons({
      required WidgetTester tester,
      required bool isEmailAuth,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en')],
          home: Scaffold(
            body: Container(
              margin: const EdgeInsets.only(top: 16),
              child: AuthProviderButtons(
                onPressed: (_) {},
                isEmailAuth: isEmailAuth,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('renders email auth mode correctly', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      await pumpAuthProviderButtons(tester: tester, isEmailAuth: true);

      await expectLater(
        find.byType(AuthProviderButtons),
        matchesGoldenFile(
          'goldens/auth_provider_buttons/${size.width}x${size.height}/auth_provider_buttons_email_auth.png',
        ),
      );
    });

    testWidgets('renders phone auth mode correctly', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      await pumpAuthProviderButtons(tester: tester, isEmailAuth: false);

      await expectLater(
        find.byType(AuthProviderButtons),
        matchesGoldenFile(
          'goldens/auth_provider_buttons/${size.width}x${size.height}/auth_provider_buttons_phone_auth.png',
        ),
      );
    });
  });
}
