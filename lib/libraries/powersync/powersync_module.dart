import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/libraries/powersync/data/connectors/supabase_powersync_connector.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:powersync/powersync.dart';

/// Modular module that wires up the PowerSync backend connector.
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
  }
}
