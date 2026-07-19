import 'package:construculator/features/auth/presentation/widgets/auth_header.dart';
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
    String? contact,
    VoidCallback? onContactPressed,
    ThemeData? theme,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme ?? createTestTheme(),
        home: Material(
          child: Padding(
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
    );
    await tester.pumpAndSettle();
  }

  group('AuthHeader Screenshot Tests - Light', () {
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
      );

      await expectLater(
        find.byType(AuthHeader),
        matchesGoldenFile(
          'goldens/auth_header/${size.width}x${size.height}/auth_header_no_contact.png',
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
      );

      await expectLater(
        find.byType(AuthHeader),
        matchesGoldenFile(
          'goldens/auth_header/${size.width}x${size.height}/auth_header_with_contact.png',
        ),
      );
    });
  });

  group('AuthHeader Screenshot Tests - Dark', () {
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
        theme: createTestThemeDark(),
      );

      await expectLater(
        find.byType(AuthHeader),
        matchesGoldenFile(
          'goldens/auth_header/${size.width}x${size.height}/auth_header_no_contact_dark.png',
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
        theme: createTestThemeDark(),
      );

      await expectLater(
        find.byType(AuthHeader),
        matchesGoldenFile(
          'goldens/auth_header/${size.width}x${size.height}/auth_header_with_contact_dark.png',
        ),
      );
    });
  });
}
