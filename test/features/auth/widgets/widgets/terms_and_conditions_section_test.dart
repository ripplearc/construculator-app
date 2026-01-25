import 'package:construculator/features/auth/presentation/widgets/terms_and_conditions_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../screenshots/font_loader.dart';

void main() {
  const termsAndConditionsText =
      'By selecting agree and continue. I agree to Construculator ';
  const termsAndServicesLink = 'terms & services';
  const privacyPolicyLink = 'privacy policy';
  const andAcknowledge = 'and acknowledge ';

  Future<void> pumpTermsAndConditionsWidget({
    required WidgetTester tester,
    required VoidCallback onTermsAndConditionsLinkPressed,
    required VoidCallback onPrivacyPolicyLinkPressed,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: createTestTheme(),
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: TermsAndConditionsSection(
              termsAndConditionsText: termsAndConditionsText,
              termsAndServicesLink: termsAndServicesLink,
              privacyPolicyLink: privacyPolicyLink,
              andAcknowledge: andAcknowledge,
              onTermsAndConditionsLinkPressed: onTermsAndConditionsLinkPressed,
              onPrivacyPolicyLinkPressed: onPrivacyPolicyLinkPressed,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('TermsAndConditions Widget Tests', () {
    testWidgets('renders all text parts correctly', (tester) async {
      await pumpTermsAndConditionsWidget(
        tester: tester,
        onTermsAndConditionsLinkPressed: () {},
        onPrivacyPolicyLinkPressed: () {},
      );

      expect(find.textContaining(termsAndConditionsText), findsOneWidget);
      expect(find.textContaining(termsAndServicesLink), findsOneWidget);
      expect(find.textContaining(privacyPolicyLink), findsOneWidget);
      expect(find.textContaining(andAcknowledge), findsOneWidget);
    });
    testWidgets('tapping on terms and services link triggers callback', (
      tester,
    ) async {
      bool termsLinkTapped = false;

      await pumpTermsAndConditionsWidget(
        tester: tester,
        onTermsAndConditionsLinkPressed: () => termsLinkTapped = true,
        onPrivacyPolicyLinkPressed: () {},
      );

      final termsLinkFinder = find.text(termsAndServicesLink);
      expect(termsLinkFinder, findsOneWidget);

      await tester.tap(termsLinkFinder);
      await tester.pump();

      expect(termsLinkTapped, isTrue);
    });

    testWidgets('tapping on privacy policy link triggers callback', (
      tester,
    ) async {
      bool privacyLinkTapped = false;

      await pumpTermsAndConditionsWidget(
        tester: tester,
        onTermsAndConditionsLinkPressed: () {},
        onPrivacyPolicyLinkPressed: () => privacyLinkTapped = true,
      );

      final privacyLinkFinder = find.text(privacyPolicyLink);
      expect(privacyLinkFinder, findsOneWidget);

      await tester.tap(privacyLinkFinder);
      await tester.pump();

      expect(privacyLinkTapped, isTrue);
    });
  });
}
