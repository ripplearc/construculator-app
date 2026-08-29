import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/libraries/consent/data/data_source/in_memory_local_consent_data_source.dart';
import 'package:construculator/libraries/consent/data/data_source/interfaces/local_consent_data_source.dart';
import 'package:construculator/libraries/consent/data/data_source/interfaces/remote_consent_data_source.dart';
import 'package:construculator/libraries/consent/data/data_source/retrying_remote_consent_data_source.dart';
import 'package:construculator/libraries/consent/data/data_source/supabase_consent_data_source.dart';
import 'package:construculator/libraries/consent/data/repositories/consent_repository_impl.dart';
import 'package:construculator/libraries/consent/domain/repositories/consent_repository.dart';
import 'package:construculator/libraries/consent/domain/usecases/check_consent_status_usecase.dart';
import 'package:construculator/libraries/consent/domain/usecases/record_consent_usecase.dart';
import 'package:construculator/libraries/consent/domain/usecases/verify_consent_status_usecase.dart';
import 'package:construculator/libraries/consent/domain/usecases/watch_consent_status_usecase.dart';
import 'package:construculator/libraries/consent/domain/usecases/withdraw_consent_usecase.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:construculator/libraries/supabase/supabase_module.dart';
import 'package:construculator/libraries/time/clock_module.dart';
import 'package:construculator/libraries/time/interfaces/clock.dart';
import 'package:flutter_modular/flutter_modular.dart';

/// Wires the consent library.
///
/// Exported binds rather than plain binds because consent is consumed across
/// module boundaries: the shell's route guard, the gate feature, and signup
/// all resolve from here.
class ConsentLibraryModule extends Module {
  final AppBootstrap appBootstrap;

  ConsentLibraryModule(this.appBootstrap);

  @override
  List<Module> get imports => [ClockModule(), SupabaseModule(appBootstrap)];

  @override
  void exportedBinds(Injector i) => _registerDependencies(i);
}

void _registerDependencies(Injector i) {
  // TODO: https://ripplearc.youtrack.cloud/issue/CA-971 - Replace with the
  // offline-first local store. Nothing above LocalConsentDataSource changes
  // when this binding is swapped. Swapping it is only half the ticket: the
  // gate stays compile-time blocked until remoteConsentWritePathLanded flips
  // too (consent_gate_readiness.dart), which needs a write method on
  // RemoteConsentDataSource, a SupabaseConsentDataSource implementation of
  // it, and a backend RPC. A durable store alone still records nothing
  // attributable.
  i.addLazySingleton<LocalConsentDataSource>(
    InMemoryLocalConsentDataSource.new,
  );

  // Wrapped in the retrying decorator so the repository sees a source that has
  // already exhausted its retries — verification failing there means the
  // server is genuinely unreachable, not that one packet was dropped.
  i.addLazySingleton<RemoteConsentDataSource>(
    () => RetryingRemoteConsentDataSource(
      SupabaseConsentDataSource(
        supabaseWrapper: Modular.get<SupabaseWrapper>(),
      ),
    ),
  );

  i.addLazySingleton<ConsentRepository>(
    () => ConsentRepositoryImpl(
      localDataSource: i(),
      remoteDataSource: i(),
      supabaseWrapper: Modular.get<SupabaseWrapper>(),
      clock: Modular.get<Clock>(),
    ),
    config: BindConfig(onDispose: (repository) => repository.dispose()),
  );

  i.add<CheckConsentStatusUseCase>(() => CheckConsentStatusUseCase(i()));
  i.add<WatchConsentStatusUseCase>(() => WatchConsentStatusUseCase(i()));
  i.add<VerifyConsentStatusUseCase>(() => VerifyConsentStatusUseCase(i()));
  i.add<RecordConsentUseCase>(() => RecordConsentUseCase(i()));
  i.add<WithdrawConsentUseCase>(() => WithdrawConsentUseCase(i()));
}
