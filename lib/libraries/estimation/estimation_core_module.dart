import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/estimation/data/data_source/interfaces/cost_estimation_data_source.dart';
import 'package:construculator/features/estimation/data/data_source/interfaces/cost_estimation_log_data_source.dart';
import 'package:construculator/features/estimation/data/data_source/remote_cost_estimation_data_source.dart';
import 'package:construculator/features/estimation/data/data_source/remote_cost_estimation_log_data_source.dart';
import 'package:construculator/features/estimation/data/repositories/cost_estimation_log_repository_impl.dart';
import 'package:construculator/features/estimation/data/repositories/cost_estimation_repository_impl.dart';
import 'package:construculator/features/estimation/domain/repositories/cost_estimation_log_repository.dart';
import 'package:construculator/features/estimation/domain/repositories/cost_estimation_repository.dart';
import 'package:construculator/features/estimation/domain/usecases/add_cost_estimation_usecase.dart';
import 'package:construculator/libraries/auth/auth_library_module.dart';
import 'package:construculator/libraries/time/clock_module.dart';
import 'package:flutter_modular/flutter_modular.dart';

class EstimationCoreModule extends Module {
  final AppBootstrap appBootstrap;
  EstimationCoreModule(this.appBootstrap);

  @override
  List<Module> get imports => [AuthLibraryModule(appBootstrap), ClockModule()];

  @override
  void exportedBinds(Injector i) {
    i.addLazySingleton<CostEstimationDataSource>(
      () => RemoteCostEstimationDataSource(
        supabaseWrapper: appBootstrap.supabaseWrapper,
      ),
    );

    i.addLazySingleton<CostEstimationLogDataSource>(
      () => RemoteCostEstimationLogDataSource(
        supabaseWrapper: appBootstrap.supabaseWrapper,
      ),
    );

    i.addLazySingleton<CostEstimationRepository>(
      () => CostEstimationRepositoryImpl(dataSource: i.get()),
      config: BindConfig(onDispose: (repository) => repository.dispose()),
    );

    i.addLazySingleton<CostEstimationLogRepository>(
      () => CostEstimationLogRepositoryImpl(dataSource: i.get()),
      config: BindConfig(onDispose: (repository) => repository.dispose()),
    );

    i.addLazySingleton<AddCostEstimationUseCase>(
      () => AddCostEstimationUseCase(i.get(), i.get(), i.get()),
    );
  }
}
