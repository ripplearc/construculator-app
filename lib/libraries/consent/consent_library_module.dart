import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/libraries/consent/data/data_source/interfaces/local_consent_data_source.dart';
import 'package:construculator/libraries/consent/data/data_source/interfaces/remote_consent_data_source.dart';
import 'package:construculator/libraries/consent/data/data_source/powersync_local_consent_data_source.dart';
import 'package:construculator/libraries/consent/data/data_source/retrying_remote_consent_data_source.dart';
import 'package:construculator/libraries/consent/data/data_source/supabase_consent_data_source.dart';
import 'package:construculator/libraries/consent/data/repositories/consent_repository_impl.dart';
import 'package:construculator/libraries/consent/domain/repositories/consent_repository.dart';
import 'package:construculator/libraries/consent/domain/usecases/check_consent_status_usecase.dart';
import 'package:construculator/libraries/consent/domain/usecases/record_consent_usecase.dart';
import 'package:construculator/libraries/consent/domain/usecases/verify_consent_status_usecase.dart';
import 'package:construculator/libraries/consent/domain/usecases/watch_consent_status_usecase.dart';
import 'package:construculator/libraries/consent/domain/usecases/withdraw_consent_usecase.dart';
import 'package:construculator/libraries/powersync/powersync_module.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:construculator/libraries/supabase/supabase_module.dart';
import 'package:construculator/libraries/time/clock_module.dart';
import 'package:construculator/libraries/time/interfaces/clock.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:powersync/powersync.dart';

/// Wires the consent library.
///
/// Exported binds rather than plain binds because consent is consumed across
/// module boundaries: the shell's route guard, the gate feature, and signup
/// all resolve from here.
class ConsentLibraryModule extends Module {
  final AppBootstrap appBootstrap;

  ConsentLibraryModule(this.appBootstrap);

  @override
  List<Module> get imports => [
    ClockModule(),
    PowerSyncModule(appBootstrap),
    SupabaseModule(appBootstrap),
  ];

  @override
  void exportedBinds(Injector i) => _registerDependencies(i);
}

void _registerDependencies(Injector i) {
  // The gate stays compile-time blocked after this swap:
  // remoteConsentWritePathLanded is still false
  // (consent_gate_readiness.dart), so consentPersistenceReady is too. A
  // durable store records a decision that survives restart, but nothing yet
  // carries it to the server, and a local-only record is not attributable.
  //
  // Disposed like the repository above it, since it owns the streams
  // watchLatestUserConsent hands out. The repository forwards its own
  // dispose here, so this config exists for a direct resolve of the data
  // source rather than for the repository's path.
  i.addLazySingleton<LocalConsentDataSource>(
    () => PowerSyncLocalConsentDataSource(
      database: Modular.get<PowerSyncDatabase>(),
      clock: Modular.get<Clock>(),
    ),
    config: BindConfig(onDispose: (source) => source.dispose()),
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
