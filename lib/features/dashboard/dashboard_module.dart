import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/dashboard/domain/usecases/watch_recent_estimations_usecase.dart';
import 'package:construculator/features/dashboard/presentation/bloc/project_dropdown_bloc/project_dropdown_bloc.dart';
import 'package:construculator/features/dashboard/presentation/bloc/recent_estimations_bloc/recent_estimations_bloc.dart';
import 'package:construculator/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/features/global_search/global_search_module.dart';
import 'package:construculator/libraries/auth/auth_library_module.dart';
import 'package:construculator/libraries/project/project_library_module.dart';
import 'package:construculator/libraries/router/guards/auth_guard.dart';
import 'package:construculator/libraries/router/router_module.dart';
import 'package:construculator/libraries/router/routes/dashboard_routes.dart';
import 'package:flutter_modular/flutter_modular.dart';

class DashboardModule extends Module {
  final AppBootstrap appBootstrap;
  DashboardModule(this.appBootstrap);
  @override
  List<Module> get imports => [
    AuthLibraryModule(appBootstrap),
    GlobalSearchModule(appBootstrap),
    ProjectLibraryModule(appBootstrap),
    EstimationModule(appBootstrap),
    RouterModule(),
  ];

  @override
  void binds(Injector i) {
    i.add<ProjectDropdownBloc>(
      () => ProjectDropdownBloc(projectRepository: i(), authManager: i()),
    );
    i.add<WatchRecentEstimationsUseCase>(
      () => WatchRecentEstimationsUseCase(i(), i()),
    );
    i.add<RecentEstimationsBloc>(
      () => RecentEstimationsBloc(
        watchRecentEstimationsUseCase: i(),
        currentProjectNotifier: i(),
      ),
    );
  }

  @override
  void routes(RouteManager r) {
    r.child(
      dashboardRoute,
      guards: [AuthGuard()],
      child: (context) => const DashboardPage(),
    );
  }
}
