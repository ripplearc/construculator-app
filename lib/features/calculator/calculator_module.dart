import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/calculator/data/data_source/interfaces/local_trade_stores_data_source.dart';
import 'package:construculator/features/calculator/data/data_source/powersync_local_trade_stores_data_source.dart';
import 'package:construculator/features/calculator/data/repositories/calculator_preferences_repository_impl.dart';
import 'package:construculator/features/calculator/data/repositories/trade_stores_repository_impl.dart';
import 'package:construculator/features/calculator/domain/repositories/calculator_preferences_repository.dart';
import 'package:construculator/features/calculator/domain/repositories/trade_stores_repository.dart';
import 'package:construculator/features/calculator/presentation/pages/calculator_page.dart';
import 'package:construculator/libraries/auth/auth_library_module.dart';
import 'package:construculator/libraries/powersync/powersync_module.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:powersync/powersync.dart';

class CalculatorModule extends Module {
  final AppBootstrap appBootstrap;

  CalculatorModule(this.appBootstrap);

  @override
  List<Module> get imports => [
    AuthLibraryModule(appBootstrap),
    PowerSyncModule(appBootstrap),
  ];

  @override
  void binds(Injector i) {
    i.addLazySingleton<CalculatorPreferencesRepository>(
      () => CalculatorPreferencesRepositoryImpl(
        authNotifier: i(),
        authManager: i(),
      ),
      config: BindConfig(onDispose: (repository) => repository.dispose()),
    );
    i.addLazySingleton<LocalTradeStoresDataSource>(
      () => PowerSyncLocalTradeStoresDataSource(
        database: Modular.get<PowerSyncDatabase>(),
      ),
      config: BindConfig(onDispose: (source) => source.dispose()),
    );
    i.addLazySingleton<TradeStoresRepository>(
      () => TradeStoresRepositoryImpl(dataSource: i()),
      config: BindConfig(onDispose: (repository) => repository.dispose()),
    );
  }

  @override
  void routes(RouteManager r) {
    r.child('/', child: (_) => const CalculatorPage());
  }
}
