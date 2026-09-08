import 'package:construculator/features/auth/presentation/widgets/auth_header.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/screenshot/font_loader.dart';

void main() {
  final size = const Size(390, 130);
  final ratio = 1.0;
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await loadAppFonts();
  });

  Future<void> pumpAuthHeader({
    required WidgetTester tester,
    required String title,
    required String description,
    required ThemeData theme,
    String? contact,
    VoidCallback? onContactPressed,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Builder(
          builder: (ctx) => Scaffold(
            backgroundColor: ctx.colorTheme.pageBackground,
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: AuthHeader(
                title: title,
                description: description,
                contact: contact,
                onContactPressed: onContactPressed,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  screenshotThemeGroups('AuthHeader Screenshot Tests', (theme, suffix) {
    testWidgets('renders auth header without contact correctly', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);

      await pumpAuthHeader(
        tester: tester,
        title: 'Welcome Back',
        description: 'Hey, Enter your details to log in to your account',
        theme: theme,
      );

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile(
          'goldens/auth_header/${size.width}x${size.height}/auth_header_no_contact$suffix.png',
        ),
      );
    });

    testWidgets('renders auth header with contact correctly', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);

      await pumpAuthHeader(
        tester: tester,
        title: 'Enter your password',
        description: 'Enter your password for this account. Your email id is ',
        contact: 'user@example.com',
        onContactPressed: () {},
        theme: theme,
      );

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile(
          'goldens/auth_header/${size.width}x${size.height}/auth_header_with_contact$suffix.png',
        ),
      );
    });
  });
}
