import 'package:construculator/features/auth/presentation/widgets/auth_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../../utils/screenshot/font_loader.dart';

void main() {
  const title = 'Welcome Back';
  const description = 'Enter your details to log in to your account';
  const contact = 'user@example.com';

  Future<void> pumpAuthHeader({
    required WidgetTester tester,
    required String title,
    required String description,
    String? contact,
    VoidCallback? onContactPressed,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: createTestTheme(),
        home: Scaffold(
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
    );
    await tester.pumpAndSettle();
  }

  group('AuthHeader Widget Tests', () {
    testWidgets('renders title and description correctly', (tester) async {
      await pumpAuthHeader(
        tester: tester,
        title: title,
        description: description,
      );

      expect(find.byKey(Key('text_title')), findsOneWidget);
      expect(find.byKey(Key('text_description')), findsOneWidget);
    });

    testWidgets('renders contact with edit icon when contact is provided', (
      tester,
    ) async {
      await pumpAuthHeader(
        tester: tester,
        title: title,
        description: description,
        contact: contact,
      );

      expect(find.byKey(Key('text_title')), findsOneWidget);
      expect(find.byKey(Key('rich_text_description')), findsOneWidget);
    });

    testWidgets('renders description as RichText when contact is provided', (
      tester,
    ) async {
      await pumpAuthHeader(
        tester: tester,
        title: title,
        description: description,
        contact: contact,
      );

      expect(find.byKey(Key('text_title')), findsOneWidget);
      expect(find.byKey(Key('rich_text_description')), findsOneWidget);
    });

    testWidgets(
      'renders description as simple Text when contact is not provided',
      (tester) async {
        await pumpAuthHeader(
          tester: tester,
          title: title,
          description: description,
        );

        expect(find.byKey(Key('text_title')), findsOneWidget);
        expect(find.byKey(Key('text_description')), findsOneWidget);
      },
    );

    testWidgets('tapping on contact triggers callback', (tester) async {
      bool contactTapped = false;

      await pumpAuthHeader(
        tester: tester,
        title: title,
        description: description,
        contact: contact,
        onContactPressed: () => contactTapped = true,
      );

      final contactFinder = find.byKey(Key('edit_link'));
      expect(contactFinder, findsOneWidget);

      await tester.tap(contactFinder);
      await tester.pump();

      expect(contactTapped, isTrue);
    });

    testWidgets('contact and edit icon are properly aligned', (tester) async {
      await pumpAuthHeader(
        tester: tester,
        title: title,
        description: description,
        contact: contact,
      );

      final rowFinder = find.byType(Row);
      expect(rowFinder, findsOneWidget);

      final row = tester.widget<Row>(rowFinder);
      expect(row.mainAxisSize, MainAxisSize.min);
    });
  });
}
