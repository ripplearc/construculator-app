import 'package:construculator/features/auth/presentation/widgets/auth_footer.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/screenshot/font_loader.dart';

void main() {
  final size = const Size(390, 64);
  final ratio = 1.0;
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await loadAppFonts();
  });

  Future<void> pumpAuthFooter({
    required WidgetTester tester,
    required String text,
    required String actionText,
    required ThemeData theme,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Builder(
          builder: (ctx) => Scaffold(
            backgroundColor: ctx.colorTheme.pageBackground,
            body: AuthFooter(
              text: text,
              actionText: actionText,
              onPressed: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  screenshotThemeGroups('AuthFooter Screenshot Tests', (theme, suffix) {
    testWidgets('renders register footer correctly', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);
      await pumpAuthFooter(
        tester: tester,
        text: "Don't have an account?",
        actionText: 'Register',
        theme: theme,
      );

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile(
          'goldens/auth_footer/${size.width}x${size.height}/auth_footer_register$suffix.png',
        ),
      );
    });

    testWidgets('renders login footer correctly', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);
      await pumpAuthFooter(
        tester: tester,
        text: 'Already have an account?',
        actionText: 'Login',
        theme: theme,
      );

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile(
          'goldens/auth_footer/${size.width}x${size.height}/auth_footer_login$suffix.png',
        ),
      );
    });
  });
}
