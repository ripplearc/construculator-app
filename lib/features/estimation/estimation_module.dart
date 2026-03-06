import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/auth/auth_module.dart';
import 'package:construculator/features/estimation/data/data_source/interfaces/cost_estimation_data_source.dart';
import 'package:construculator/features/estimation/data/data_source/interfaces/cost_estimation_log_data_source.dart';
import 'package:construculator/features/estimation/data/data_source/remote_cost_estimation_data_source.dart';
import 'package:construculator/features/estimation/data/data_source/remote_cost_estimation_log_data_source.dart';
import 'package:construculator/features/estimation/data/repositories/cost_estimation_log_repository_impl.dart';
import 'package:construculator/features/estimation/data/repositories/cost_estimation_repository_impl.dart';
import 'package:construculator/features/estimation/domain/repositories/cost_estimation_log_repository.dart';
import 'package:construculator/features/estimation/domain/repositories/cost_estimation_repository.dart';
import 'package:construculator/features/estimation/domain/usecases/add_cost_estimation_usecase.dart';
import 'package:construculator/features/estimation/presentation/bloc/cost_estimation_list_bloc/cost_estimation_list_bloc.dart';
import 'package:construculator/features/estimation/presentation/bloc/add_cost_estimation_bloc/add_cost_estimation_bloc.dart';
import 'package:construculator/features/estimation/presentation/bloc/delete_cost_estimation_bloc/delete_cost_estimation_bloc.dart';
import 'package:construculator/features/estimation/presentation/bloc/change_lock_status_bloc/change_lock_status_bloc.dart';
import 'package:construculator/features/estimation/presentation/bloc/rename_estimation_bloc/rename_estimation_bloc.dart';
import 'package:construculator/features/estimation/presentation/pages/cost_estimation_landing_page.dart';
import 'package:construculator/features/estimation/presentation/pages/cost_estimation_details_page.dart';
import 'package:construculator/libraries/router/guards/auth_guard.dart';
import 'package:construculator/libraries/router/routes/estimation_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';

class RouteDefinition {
  final String route;
  final WidgetBuilder widget;
  final List<RouteGuard> guards;

  RouteDefinition(this.route, this.widget, this.guards);
}

class EstimationModule extends Module {
  final AppBootstrap appBootstrap;
  EstimationModule(this.appBootstrap);

  final List<RouteDefinition> _routeDefinitions = [
    RouteDefinition(estimationLandingRoute, (context) {
      final projectId = Modular.args.params['projectId'];
      // TODO: https://ripplearc.youtrack.cloud/issue/CA-119/Dashboard-Enable-Project-Selection-and-Switching (Fall back to the currently selected project id)
      if (projectId == null || projectId.isEmpty) {
        return const SizedBox.shrink();
      }

      return MultiBlocProvider(
        providers: [
          BlocProvider<CostEstimationListBloc>(
            create: (context) {
              return Modular.get<CostEstimationListBloc>()
                ..add(CostEstimationListStartWatching(projectId: projectId));
            },
          ),
          BlocProvider(
            create: (context) => Modular.get<AddCostEstimationBloc>(),
          ),
          BlocProvider(
            create: (context) => Modular.get<DeleteCostEstimationBloc>(),
          ),
          BlocProvider(
            create: (context) => Modular.get<ChangeLockStatusBloc>(),
          ),
          BlocProvider(
            create: (context) => Modular.get<RenameEstimationBloc>(),
          ),
        ],
        child: CostEstimationLandingPage(projectId: projectId),
      );
    }, [AuthGuard()]),

    RouteDefinition(estimationDetailsRoute, (context) {
      final estimationId = Modular.args.params['estimationId'];

      if (estimationId == null || estimationId.isEmpty) {
        throw ArgumentError(
          'estimationId is required for CostEstimationDetailsPage. '
          'Ensure the route includes a valid estimationId parameter.',
        );
      }

      return CostEstimationDetailsPage(estimationId: estimationId);
    }, [AuthGuard()]),
  ];

  @override
  List<Module> get imports => [AuthModule(appBootstrap)];

  @override
  void binds(Injector i) {
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
  }

  @override
  void routes(RouteManager r) {
    for (final routeDef in _routeDefinitions) {
      r.child(routeDef.route, guards: routeDef.guards, child: routeDef.widget);
    }
  }
}
