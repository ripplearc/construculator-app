import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/libraries/estimation/data/data_source/interfaces/cost_estimation_data_source.dart';
import 'package:construculator/libraries/estimation/data/data_source/remote_cost_estimation_data_source.dart';
import 'package:construculator/libraries/estimation/data/repositories/cost_estimation_repository_impl.dart';
import 'package:construculator/libraries/estimation/domain/repositories/cost_estimation_repository.dart';
import 'package:construculator/libraries/supabase/supabase_module.dart';
import 'package:flutter_modular/flutter_modular.dart';

/// Modular module that registers estimation data-layer dependencies
/// as exported bindings so any importing module gains access to
/// [CostEstimationDataSource] and [CostEstimationRepository].
class EstimationLibraryModule extends Module {
  final AppBootstrap appBootstrap;

  EstimationLibraryModule(this.appBootstrap);

  @override
  List<Module> get imports => [SupabaseModule(appBootstrap)];

  @override
  void exportedBinds(Injector i) {
    i.addLazySingleton<CostEstimationDataSource>(
      () => RemoteCostEstimationDataSource(supabaseWrapper: i.get()),
    );

    i.addLazySingleton<CostEstimationRepository>(
      () => CostEstimationRepositoryImpl(dataSource: i.get()),
      config: BindConfig(onDispose: (repository) => repository.dispose()),
    );
  }
}
