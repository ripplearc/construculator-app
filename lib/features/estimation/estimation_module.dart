import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/estimation/data/data_source/interfaces/cost_estimation_log_data_source.dart';
import 'package:construculator/features/estimation/data/data_source/remote_cost_estimation_log_data_source.dart';
import 'package:construculator/features/estimation/data/repositories/cost_estimation_log_repository_impl.dart';
import 'package:construculator/features/estimation/domain/repositories/cost_estimation_log_repository.dart';
import 'package:construculator/features/estimation/domain/usecases/add_cost_estimation_usecase.dart';
import 'package:construculator/features/estimation/presentation/bloc/add_cost_estimation_bloc/add_cost_estimation_bloc.dart';
import 'package:construculator/features/estimation/presentation/bloc/change_lock_status_bloc/change_lock_status_bloc.dart';
import 'package:construculator/features/estimation/presentation/bloc/cost_estimation_list_bloc/cost_estimation_list_bloc.dart';
import 'package:construculator/features/estimation/presentation/bloc/cost_estimation_log_bloc/cost_estimation_log_bloc.dart';
import 'package:construculator/features/estimation/presentation/bloc/delete_cost_estimation_bloc/delete_cost_estimation_bloc.dart';
import 'package:construculator/features/estimation/presentation/bloc/rename_estimation_bloc/rename_estimation_bloc.dart';
import 'package:construculator/features/estimation/presentation/pages/cost_estimation_landing_page.dart';
import 'package:construculator/libraries/auth/auth_library_module.dart';
import 'package:construculator/libraries/estimation/estimation_library_module.dart';
import 'package:construculator/libraries/time/clock_module.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';

class EstimationModule extends Module {
  final AppBootstrap appBootstrap;
  EstimationModule(this.appBootstrap);

  /// Exposes the Estimation Feature's UI entry point, hiding its Bloc dependencies.
  static Widget landingPage() {
    return MultiBlocProvider(
      providers: [
        BlocProvider<CostEstimationListBloc>(
          create: (context) => Modular.get<CostEstimationListBloc>(),
        ),
        BlocProvider<AddCostEstimationBloc>(
          create: (context) => Modular.get<AddCostEstimationBloc>(),
        ),
        BlocProvider<DeleteCostEstimationBloc>(
          create: (context) => Modular.get<DeleteCostEstimationBloc>(),
        ),
        BlocProvider<ChangeLockStatusBloc>(
          create: (context) => Modular.get<ChangeLockStatusBloc>(),
        ),
        BlocProvider<RenameEstimationBloc>(
          create: (context) => Modular.get<RenameEstimationBloc>(),
        ),
      ],
      child: const CostEstimationLandingPage(),
    );
  }

  @override
  List<Module> get imports => [
    AuthLibraryModule(appBootstrap),
    EstimationLibraryModule(appBootstrap),
    ClockModule(),
  ];

  @override
  void exportedBinds(Injector i) {}

  @override
  void binds(Injector i) {
    i.addLazySingleton<CostEstimationLogDataSource>(
      () => RemoteCostEstimationLogDataSource(
        supabaseWrapper: appBootstrap.supabaseWrapper,
      ),
    );

    i.addLazySingleton<CostEstimationLogRepository>(
      () => CostEstimationLogRepositoryImpl(dataSource: i.get()),
      config: BindConfig(onDispose: (repository) => repository.dispose()),
    );

    i.addLazySingleton<AddCostEstimationUseCase>(
      () => AddCostEstimationUseCase(i.get(), i.get(), i.get()),
    );
    i.add<CostEstimationListBloc>(
      () => CostEstimationListBloc(repository: i.get()),
    );
    i.add<AddCostEstimationBloc>(
      () => AddCostEstimationBloc(addCostEstimationUseCase: i.get()),
    );
    i.add<DeleteCostEstimationBloc>(
      () => DeleteCostEstimationBloc(costEstimationRepository: i.get()),
    );
    i.add<ChangeLockStatusBloc>(
      () => ChangeLockStatusBloc(repository: i.get()),
    );
    i.add<RenameEstimationBloc>(
      () => RenameEstimationBloc(repository: i.get()),
    );
    i.add<CostEstimationLogBloc>(
      () => CostEstimationLogBloc(repository: i.get()),
    );
  }
}
