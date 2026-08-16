import 'package:construculator/libraries/consent/domain/entities/consent_status_entity.dart';
import 'package:construculator/libraries/consent/domain/types/consent_types.dart';
import 'package:construculator/libraries/consent/domain/usecases/params/consent_usecase_params.dart';
import 'package:construculator/libraries/consent/domain/usecases/verify_consent_status_usecase.dart';
import 'package:construculator/libraries/consent/testing/fake_consent_repository.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import 'consent_usecase_test_module.dart';

void main() {
  late FakeConsentRepository repository;
  late VerifyConsentStatusUseCase useCase;

  setUp(() {
    repository = initConsentUseCaseModule();
    useCase = Modular.get<VerifyConsentStatusUseCase>();
  });

  tearDown(Modular.destroy);

  group('VerifyConsentStatusUseCase', () {
    test('returns the status the verification resolved', () async {
      // The only path that can produce ConsentUnverified: a check that failed
      // with a prior acceptance on file is the one case that fails open.
      repository.verifiedStatusToReturn = const ConsentUnverified(3);

      final result = await useCase(
        const ConsentStatusParams(consentType: ConsentType.termsAndPrivacy),
      );

      expect(result, const ConsentUnverified(3));
    });

    test('verifies each consent type it is given', () async {
      // Both directions on purpose: probing with a single type cannot tell a
      // correct routing apart from one hardcoded to that same type.
      await useCase(
        const ConsentStatusParams(consentType: ConsentType.analytics),
      );
      await useCase(
        const ConsentStatusParams(consentType: ConsentType.termsAndPrivacy),
      );

      expect(repository.verificationRequests, [
        ConsentType.analytics,
        ConsentType.termsAndPrivacy,
      ]);
    });
  });
}
