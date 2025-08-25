import 'package:construculator/features/auth/presentation/widgets/terms_and_conditions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../font_loader.dart';

void main() {
  final size = const Size(390, 100);
  final ratio = 1.0;
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await loadAppFonts();
  });

  group('TermsAndConditions Screenshot Tests', () {
    Future<void> pumpTermsAndConditions({
      required WidgetTester tester,
      required String termsAndConditionsText,
      required String termsAndServicesLink,
      required String privacyPolicyLink,
      required String andAcknowledge,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: TermsAndConditions(
                termsAndConditionsText: termsAndConditionsText,
                termsAndServicesLink: termsAndServicesLink,
                privacyPolicyLink: privacyPolicyLink,
                andAcknowledge: andAcknowledge,
                onTermsAndConditionsLinkPressed: () {},
                onPrivacyPolicyLinkPressed: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('renders terms and conditions correctly', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      
      await pumpTermsAndConditions(
        tester: tester,
        termsAndConditionsText: 'By selecting agree and continue. I agree to Construculator ',
        termsAndServicesLink: 'terms & services',
        privacyPolicyLink: 'privacy policy',
        andAcknowledge: 'and acknowledge ',
      );

      await expectLater(
        find.byType(TermsAndConditions),
        matchesGoldenFile(
          'goldens/terms_and_conditions/${size.width}x${size.height}/terms_and_conditions_agreement.png',
        ),
      );
    });
  });
} 