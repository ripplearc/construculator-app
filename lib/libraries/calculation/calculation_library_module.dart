import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/libraries/calculation/data/data_source/interfaces/local_calculation_session_data_source.dart';
import 'package:construculator/libraries/calculation/data/data_source/powersync_local_calculation_session_data_source.dart';
import 'package:construculator/libraries/calculation/data/repositories/calculation_session_repository_impl.dart';
import 'package:construculator/libraries/calculation/domain/repositories/calculation_session_repository.dart';
import 'package:construculator/libraries/powersync/powersync_module.dart';
import 'package:construculator/libraries/supabase/supabase_module.dart';
import 'package:construculator/libraries/time/clock_module.dart';
import 'package:flutter_modular/flutter_modular.dart';

/// Modular module that registers the calculator's history as exported
/// bindings, so any importing module gains access to
/// [LocalCalculationSessionDataSource] and [CalculationSessionRepository].
class CalculationLibraryModule extends Module {
  final AppBootstrap appBootstrap;

  /// Creates a [CalculationLibraryModule] with the given [appBootstrap]
  /// used to configure the Supabase and PowerSync dependencies.
  CalculationLibraryModule(this.appBootstrap);

  @override
  List<Module> get imports => [
    SupabaseModule(appBootstrap),
    PowerSyncModule(appBootstrap),
    ClockModule(),
  ];

  @override
  void exportedBinds(Injector i) {
    i.addLazySingleton<LocalCalculationSessionDataSource>(
      () => PowerSyncLocalCalculationSessionDataSource(database: i.get()),
      config: BindConfig(onDispose: (source) => source.dispose()),
    );
    i.addLazySingleton<CalculationSessionRepository>(
      () => CalculationSessionRepositoryImpl(
        dataSource: i.get(),
        supabaseWrapper: appBootstrap.supabaseWrapper,
        clock: i.get(),
      ),
      config: BindConfig(onDispose: (repository) => repository.dispose()),
    );
  }
}
