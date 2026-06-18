import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/libraries/powersync/data/connectors/supabase_powersync_connector.dart';
import 'package:construculator/libraries/powersync/interfaces/powersync_manager.dart';
import 'package:construculator/libraries/powersync/powersync_manager_impl.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:powersync/powersync.dart';

/// Modular module that wires up the PowerSync backend connector.
/// Wires the PowerSync stack: the opened local database, the Supabase-backed
/// connector, and the [PowerSyncManager] that drives the sync lifecycle.
///
/// The database is opened during app bootstrap (see `openPowerSyncDatabase`)
/// and passed in via [AppBootstrap], because opening it is asynchronous and
/// must complete before the module graph is built.
class PowerSyncModule extends Module {
  final AppBootstrap appBootstrap;
  PowerSyncModule(this.appBootstrap);

  @override
  void exportedBinds(Injector i) {
    i.addLazySingleton<PowerSyncBackendConnector>(
      () => SupabasePowerSyncConnector(
        supabaseWrapper: appBootstrap.supabaseWrapper,
        envLoader: appBootstrap.envLoader,
      ),
    );

    i.addLazySingleton<PowerSyncDatabase>(() => appBootstrap.powerSyncDatabase);

    // Eager singleton: instantiated when the module is committed at app
    // startup (see auto_injector's startSingletons), so the manager immediately
    // subscribes to auth changes and drives connect/disconnect over the app's
    // lifetime — without any caller needing to resolve it explicitly.
    i.addSingleton<PowerSyncManager>(
      () => PowerSyncManagerImpl(
        database: appBootstrap.powerSyncDatabase,
        connector: i(),
        supabaseWrapper: appBootstrap.supabaseWrapper,
      ),
    );
  }
}
