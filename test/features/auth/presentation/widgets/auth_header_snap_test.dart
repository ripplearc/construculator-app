import 'package:construculator/features/auth/presentation/widgets/auth_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/screenshot/font_loader.dart';

void main() {
  final size = const Size(390, 130);
  final ratio = 1.0;
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await loadAppFonts();
  });

  group('AuthHeader Screenshot Tests', () {
    Future<void> pumpAuthHeader({
      required WidgetTester tester,
      required String title,
      required String description,
      String? contact,
      VoidCallback? onContactPressed,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
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

    testWidgets('renders auth header without contact correctly', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;

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
}
