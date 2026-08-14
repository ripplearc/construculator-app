import 'package:construculator/libraries/consent/domain/entities/user_consent_entity.dart';
import 'package:construculator/libraries/consent/domain/types/consent_types.dart';
import 'package:construculator/libraries/consent/domain/usecases/params/consent_usecase_params.dart';
import 'package:construculator/libraries/consent/domain/usecases/withdraw_consent_usecase.dart';
import 'package:construculator/libraries/consent/testing/fake_consent_repository.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import 'consent_usecase_test_module.dart';

void main() {
  late FakeConsentRepository repository;
  late WithdrawConsentUseCase useCase;

  setUp(() {
    repository = initConsentUseCaseModule();
    useCase = Modular.get<WithdrawConsentUseCase>();
  });

  tearDown(Modular.destroy);

  group('WithdrawConsentUseCase', () {
    test('records a withdrawal for the type it was given', () async {
      await useCase(
        const WithdrawConsentParams(consentType: ConsentType.analytics),
      );

      expect(repository.recordedWithdrawals, [ConsentType.analytics]);
    });

    test('returns the withdrawal record on success', () async {
      final result = await useCase(
        const WithdrawConsentParams(
          consentType: ConsentType.termsAndPrivacy,
        ),
      );

      final record = result.getRightOrNull() as UserConsent;
      expect(record.action, ConsentAction.withdrawn);
      expect(record.consentType, ConsentType.termsAndPrivacy);
    });
  });
}
