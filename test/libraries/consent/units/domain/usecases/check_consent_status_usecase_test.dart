import 'package:construculator/libraries/consent/domain/entities/consent_status_entity.dart';
import 'package:construculator/libraries/consent/domain/types/consent_types.dart';
import 'package:construculator/libraries/consent/domain/usecases/check_consent_status_usecase.dart';
import 'package:construculator/libraries/consent/domain/usecases/params/consent_usecase_params.dart';
import 'package:construculator/libraries/consent/testing/fake_consent_repository.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import 'consent_usecase_test_module.dart';

void main() {
  late FakeConsentRepository repository;
  late CheckConsentStatusUseCase useCase;

  setUp(() {
    repository = initConsentUseCaseModule();
    useCase = Modular.get<CheckConsentStatusUseCase>();
  });

  tearDown(Modular.destroy);

  group('CheckConsentStatusUseCase', () {
    test('returns the status the repository resolved', () async {
      repository.cachedStatusToReturn = const ConsentIndeterminate();

      final result = await useCase(
        const ConsentStatusParams(consentType: ConsentType.termsAndPrivacy),
      );

      expect(result, const ConsentIndeterminate());
    });

    test('asks about each consent type it is given', () async {
      // Both directions on purpose: probing with a single type cannot tell a
      // correct routing apart from one hardcoded to that same type.
      await useCase(
        const ConsentStatusParams(consentType: ConsentType.analytics),
      );
      await useCase(
        const ConsentStatusParams(consentType: ConsentType.termsAndPrivacy),
      );

      expect(repository.cachedStatusRequests, [
        ConsentType.analytics,
        ConsentType.termsAndPrivacy,
      ]);
    });
  });
}
