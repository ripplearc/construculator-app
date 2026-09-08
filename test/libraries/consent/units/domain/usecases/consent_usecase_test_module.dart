import 'package:construculator/libraries/consent/domain/repositories/consent_repository.dart';
import 'package:construculator/libraries/consent/domain/usecases/check_consent_status_usecase.dart';
import 'package:construculator/libraries/consent/domain/usecases/record_consent_usecase.dart';
import 'package:construculator/libraries/consent/domain/usecases/verify_consent_status_usecase.dart';
import 'package:construculator/libraries/consent/domain/usecases/watch_consent_status_usecase.dart';
import 'package:construculator/libraries/consent/domain/usecases/withdraw_consent_usecase.dart';
import 'package:construculator/libraries/consent/testing/fake_consent_repository.dart';
import 'package:flutter_modular/flutter_modular.dart';

/// Binds the consent use cases over [FakeConsentRepository].
///
/// A local module rather than `ConsentLibraryModule`, which does not exist
/// until the wiring PR later in this stack. Subjects are resolved from it so
/// these tests exercise the same construction path production uses, rather
/// than newing the use cases up directly.
class ConsentUseCaseTestModule extends Module {
  @override
  void binds(Injector i) {
    i.addSingleton<ConsentRepository>(FakeConsentRepository.new);
    i.add<CheckConsentStatusUseCase>(() => CheckConsentStatusUseCase(i()));
    i.add<WatchConsentStatusUseCase>(() => WatchConsentStatusUseCase(i()));
    i.add<VerifyConsentStatusUseCase>(() => VerifyConsentStatusUseCase(i()));
    i.add<RecordConsentUseCase>(() => RecordConsentUseCase(i()));
    i.add<WithdrawConsentUseCase>(() => WithdrawConsentUseCase(i()));
  }
}

/// Initialises [ConsentUseCaseTestModule] and returns the bound fake.
///
/// Call [Modular.destroy] in `tearDown`; the fake is a singleton, so a shared
/// module would otherwise carry one test's scenario into the next.
FakeConsentRepository initConsentUseCaseModule() {
  Modular.init(ConsentUseCaseTestModule());
  return Modular.get<ConsentRepository>() as FakeConsentRepository;
}
