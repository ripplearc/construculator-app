import 'package:construculator/libraries/consent/domain/types/consent_error_type.dart';
import 'package:construculator/libraries/consent/domain/types/consent_types.dart';
import 'package:construculator/libraries/consent/domain/usecases/params/consent_usecase_params.dart';
import 'package:construculator/libraries/consent/domain/usecases/record_consent_usecase.dart';
import 'package:construculator/libraries/consent/testing/fake_consent_repository.dart';
import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import 'consent_usecase_test_module.dart';

void main() {
  late FakeConsentRepository repository;
  late RecordConsentUseCase useCase;

  setUp(() {
    repository = initConsentUseCaseModule();
    useCase = Modular.get<RecordConsentUseCase>();
  });

  tearDown(Modular.destroy);

  group('RecordConsentUseCase', () {
    test('records an acceptance of the version it was given', () async {
      await useCase(
        const RecordConsentParams(
          consentType: ConsentType.termsAndPrivacy,
          version: 4,
        ),
      );

      expect(repository.recordedAcceptances, [
        (consentType: ConsentType.termsAndPrivacy, version: 4),
      ]);
    });

    test('surfaces a write failure to the caller', () async {
      repository.acceptanceResultToReturn = const Left(
        ConsentFailure(errorType: ConsentErrorType.permissionDenied),
      );

      final result = await useCase(
        const RecordConsentParams(
          consentType: ConsentType.termsAndPrivacy,
          version: 4,
        ),
      );

      expect(
        result.getLeftOrNull(),
        const ConsentFailure(errorType: ConsentErrorType.permissionDenied),
      );
    });
  });
}
