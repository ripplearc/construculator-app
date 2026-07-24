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
    ThemeData? theme,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme ?? createTestTheme(),
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

  group('AuthFooter Screenshot Tests - Light', () {
    testWidgets('renders register footer correctly', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);
      await pumpAuthFooter(
        tester: tester,
        text: "Don't have an account?",
        actionText: 'Register',
      );

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile(
          'goldens/auth_footer/${size.width}x${size.height}/auth_footer_register.png',
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
      );

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile(
          'goldens/auth_footer/${size.width}x${size.height}/auth_footer_login.png',
        ),
      );
    });
  });

  group('AuthFooter Screenshot Tests - Dark', () {
    testWidgets('renders register footer correctly', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);
      await pumpAuthFooter(
        tester: tester,
        text: "Don't have an account?",
        actionText: 'Register',
        theme: createTestThemeDark(),
      );

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile(
          'goldens/auth_footer/${size.width}x${size.height}/auth_footer_register_dark.png',
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
        theme: createTestThemeDark(),
      );

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile(
          'goldens/auth_footer/${size.width}x${size.height}/auth_footer_login_dark.png',
        ),
      );
    });
  });
}
