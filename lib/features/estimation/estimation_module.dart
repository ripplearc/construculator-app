import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/auth/auth_module.dart';
import 'package:construculator/features/estimation/data/data_source/remote_cost_estimation_data_source.dart';
import 'package:construculator/features/estimation/data/repositories/cost_estimation_repository_impl.dart';
import 'package:construculator/features/estimation/domain/repositories/cost_estimation_repository.dart';
import 'package:construculator/features/estimation/domain/usecases/get_estimations_usecase.dart';
import 'package:construculator/features/estimation/presentation/bloc/cost_estimation_list_bloc/cost_estimation_list_bloc.dart';
import 'package:construculator/features/estimation/presentation/pages/cost_estimation_landing_page.dart';
import 'package:construculator/features/project_settings/project_settings_module.dart';
import 'package:construculator/libraries/auth/auth_library_module.dart';
import 'package:construculator/libraries/router/guards/auth_guard.dart';
import 'package:construculator/libraries/router/router_module.dart';
import 'package:construculator/libraries/router/routes/estimation_routes.dart';
import 'package:construculator/libraries/supabase/supabase_module.dart';
import 'package:flutter/material.dart';
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
      if (projectId == null || projectId.isEmpty) {
        throw Exception('Project ID is required for cost estimation');
      }
      
      return CostEstimationLandingPage(projectId: projectId);
    }, [
      AuthGuard(),
    ]),
  ];

  List<RouteDefinition> get routeDefinitions => _routeDefinitions;

  @override
  List<Module> get imports => [
    AuthLibraryModule(appBootstrap), AuthModule(appBootstrap), 
    RouterModule(), 
    ProjectSettingsModule(appBootstrap),
    SupabaseModule(appBootstrap),
  ];

  @override
  void binds(Injector i) {
    // Data sources
    i.addLazySingleton<CostEstimationRepository>(
      () => CostEstimationRepositoryImpl(
        dataSource: RemoteCostEstimationDataSource(supabaseWrapper: i.get()),
      ),
    );

    // Use cases
    i.addLazySingleton<GetEstimationsUseCase>(
      () => GetEstimationsUseCase(i.get()),
    );

    // BLoCs
    i.addLazySingleton<CostEstimationListBloc>(
      () => CostEstimationListBloc(
        getEstimationsUseCase: i.get(),
        projectId: 'default-project-id',
      ),
    );
  }

  @override
  void routes(RouteManager r) {
    for (final routeDef in _routeDefinitions) {
      r.child(routeDef.route, guards: routeDef.guards, child: routeDef.widget);
    }
  }
}
