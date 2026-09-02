import 'package:construculator/libraries/consent/domain/types/consent_types.dart';
import 'package:construculator/libraries/consent/domain/usecases/params/consent_usecase_params.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ConsentStatusParams', () {
    test('compares by consent type', () {
      // The whole reason the type is carried rather than defaulted: routing
      // the wrong one would let an analytics opt-out gate the app.
      expect(
        const ConsentStatusParams(consentType: ConsentType.termsAndPrivacy),
        const ConsentStatusParams(consentType: ConsentType.termsAndPrivacy),
      );
      expect(
        const ConsentStatusParams(consentType: ConsentType.termsAndPrivacy),
        isNot(const ConsentStatusParams(consentType: ConsentType.analytics)),
      );
    });
  });

  group('RecordConsentParams', () {
    test('compares by consent type and version', () {
      expect(
        const RecordConsentParams(
          consentType: ConsentType.termsAndPrivacy,
          version: 2,
        ),
        const RecordConsentParams(
          consentType: ConsentType.termsAndPrivacy,
          version: 2,
        ),
      );
    });

    test('distinguishes acceptances of different versions', () {
      // The version is what the user was actually shown, so two acceptances
      // of different versions are not the same request.
      expect(
        const RecordConsentParams(
          consentType: ConsentType.termsAndPrivacy,
          version: 2,
        ),
        isNot(
          const RecordConsentParams(
            consentType: ConsentType.termsAndPrivacy,
            version: 3,
          ),
        ),
      );
    });

    test('distinguishes acceptances of different types', () {
      expect(
        const RecordConsentParams(
          consentType: ConsentType.termsAndPrivacy,
          version: 2,
        ),
        isNot(
          const RecordConsentParams(
            consentType: ConsentType.analytics,
            version: 2,
          ),
        ),
      );
    });
  });

  group('WithdrawConsentParams', () {
    test('compares by consent type', () {
      expect(
        const WithdrawConsentParams(consentType: ConsentType.analytics),
        const WithdrawConsentParams(consentType: ConsentType.analytics),
      );
      expect(
        const WithdrawConsentParams(consentType: ConsentType.analytics),
        isNot(
          const WithdrawConsentParams(
            consentType: ConsentType.termsAndPrivacy,
          ),
        ),
      );
    });
  });
}
