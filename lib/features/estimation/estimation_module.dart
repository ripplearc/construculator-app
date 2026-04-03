import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/auth/auth_module.dart';
import 'package:construculator/features/estimation/presentation/bloc/add_cost_estimation_bloc/add_cost_estimation_bloc.dart';
import 'package:construculator/features/estimation/presentation/bloc/change_lock_status_bloc/change_lock_status_bloc.dart';
import 'package:construculator/features/estimation/presentation/bloc/cost_estimation_list_bloc/cost_estimation_list_bloc.dart';
import 'package:construculator/features/estimation/presentation/bloc/cost_estimation_log_bloc/cost_estimation_log_bloc.dart';
import 'package:construculator/features/estimation/presentation/bloc/delete_cost_estimation_bloc/delete_cost_estimation_bloc.dart';
import 'package:construculator/features/estimation/presentation/bloc/rename_estimation_bloc/rename_estimation_bloc.dart';
import 'package:construculator/features/estimation/presentation/pages/cost_estimation_landing_page.dart';
import 'package:construculator/libraries/estimation/estimation_core_module.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';

class EstimationModule extends Module {
  final AppBootstrap appBootstrap;
  EstimationModule(this.appBootstrap);

  /// Exposes the Estimation Feature's UI entry point, hiding its Bloc dependencies.
  static Widget landingPage({required String projectId}) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<CostEstimationListBloc>(
          create: (context) =>
              Modular.get<CostEstimationListBloc>()
                ..add(CostEstimationListStartWatching(projectId: projectId)),
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
      child: CostEstimationLandingPage(projectId: projectId),
    );
  }

  @override
  List<Module> get imports => [
    AuthModule(appBootstrap),
    EstimationCoreModule(appBootstrap),
  ];

  @override
  void binds(Injector i) {
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
