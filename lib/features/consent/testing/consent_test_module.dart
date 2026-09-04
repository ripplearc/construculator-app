// coverage:ignore-file
import 'package:construculator/features/consent/presentation/bloc/consent_gate_bloc/consent_gate_bloc.dart';
import 'package:construculator/libraries/consent/domain/repositories/consent_repository.dart';
import 'package:construculator/libraries/consent/domain/usecases/check_consent_status_usecase.dart';
import 'package:construculator/libraries/consent/domain/usecases/record_consent_usecase.dart';
import 'package:construculator/libraries/consent/domain/usecases/verify_consent_status_usecase.dart';
import 'package:construculator/libraries/consent/domain/usecases/watch_consent_status_usecase.dart';
import 'package:construculator/libraries/consent/domain/usecases/withdraw_consent_usecase.dart';
import 'package:construculator/libraries/consent/testing/fake_consent_repository.dart';
import 'package:construculator/libraries/router/testing/router_test_module.dart';
import 'package:flutter_modular/flutter_modular.dart';

/// Test module for the consent gate feature.
///
/// Binds the real use cases and BLoC over a [FakeConsentRepository], so tests
/// exercise the actual state machine and only the storage boundary is faked.
/// Resolve the repository with `Modular.get<ConsentRepository>()` to drive a
/// scenario.
class ConsentTestModule extends Module {
  @override
  List<Module> get imports => [RouterTestModule()];

  @override
  void binds(Injector i) {
    // Mirrors ConsentLibraryModule's BindConfig, so the dispose path
    // production relies on is exercised somewhere rather than only declared.
    // FakeConsentRepository.dispose() records the call rather than closing a
    // controller, which is what makes it assertable: a test can check
    // disposeCallCount after Modular.destroy and catch a production bind that
    // drops the config.
    i.addSingleton<ConsentRepository>(
      FakeConsentRepository.new,
      config: BindConfig(onDispose: (repository) => repository.dispose()),
    );

    i.add<CheckConsentStatusUseCase>(() => CheckConsentStatusUseCase(i()));
    i.add<WatchConsentStatusUseCase>(() => WatchConsentStatusUseCase(i()));
    i.add<VerifyConsentStatusUseCase>(() => VerifyConsentStatusUseCase(i()));
    i.add<RecordConsentUseCase>(() => RecordConsentUseCase(i()));
    i.add<WithdrawConsentUseCase>(() => WithdrawConsentUseCase(i()));

    i.add<ConsentGateBloc>(
      () => ConsentGateBloc(
        checkConsentStatusUseCase: i(),
        watchConsentStatusUseCase: i(),
        verifyConsentStatusUseCase: i(),
        recordConsentUseCase: i(),
      ),
    );
  }
}
