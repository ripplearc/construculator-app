import 'package:construculator/libraries/consent/domain/entities/consent_status_entity.dart';
import 'package:construculator/libraries/consent/domain/types/consent_types.dart';
import 'package:construculator/libraries/consent/domain/usecases/params/consent_usecase_params.dart';
import 'package:construculator/libraries/consent/domain/usecases/watch_consent_status_usecase.dart';
import 'package:construculator/libraries/consent/testing/fake_consent_repository.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import 'consent_usecase_test_module.dart';

void main() {
  late FakeConsentRepository repository;
  late WatchConsentStatusUseCase useCase;

  setUp(() {
    repository = initConsentUseCaseModule();
    useCase = Modular.get<WatchConsentStatusUseCase>();
  });

  tearDown(Modular.destroy);

  group('WatchConsentStatusUseCase', () {
    test('emits each status the repository publishes', () async {
      repository.statusStreamToReturn = Stream.fromIterable(const [
        ConsentSatisfied(1),
        ConsentIndeterminate(ConsentType.termsAndPrivacy),
      ]);

      final emitted = await useCase(
        const ConsentStatusParams(consentType: ConsentType.termsAndPrivacy),
      ).toList();

      expect(emitted, const [
        ConsentSatisfied(1),
        ConsentIndeterminate(ConsentType.termsAndPrivacy),
      ]);
    });

    test('observes each consent type it is given', () async {
      // Both directions on purpose: probing with a single type cannot tell a
      // correct routing apart from one hardcoded to that same type. The
      // subscription lives for the session, so a mis-route would gate the app
      // on an analytics opt-out until the next restart.
      await useCase(
        const ConsentStatusParams(consentType: ConsentType.analytics),
      ).toList();
      await useCase(
        const ConsentStatusParams(consentType: ConsentType.termsAndPrivacy),
      ).toList();

      expect(repository.watchRequests, [
        ConsentType.analytics,
        ConsentType.termsAndPrivacy,
      ]);
    });
  });
}
