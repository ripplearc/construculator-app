import 'package:construculator/features/auth/presentation/widgets/auth_footer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../font_loader.dart';

void main() {
  final size = const Size(390, 844);
  final ratio = 1.0;
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await loadAppFonts();
  });

  group('AuthFooter Screenshot Tests', () {
    Future<void> pumpAuthFooter({
      required WidgetTester tester,
      required String text,
      required String actionText,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuthFooter(
              text: text,
              actionText: actionText,
              onPressed: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('renders register footer correctly', (tester) async {   
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      await pumpAuthFooter(
        tester: tester,
        text: "Don't have an account?",
        actionText: 'Register',
      );

      await expectLater(
        find.byType(AuthFooter),
        matchesGoldenFile('goldens/auth_footer/auth_footer_register.png'),
      );
    });

    testWidgets('renders login footer correctly', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      await pumpAuthFooter(
        tester: tester,
        text: 'Already have an account?',
        actionText: 'Login',
      );

      await expectLater(
        find.byType(AuthFooter),
        matchesGoldenFile('goldens/auth_footer/auth_footer_login.png'),
      );
    });
  });
}
