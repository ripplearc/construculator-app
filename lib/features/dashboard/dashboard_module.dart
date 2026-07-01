import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/app/shell/app_shell_bloc/app_shell_bloc.dart';
import 'package:construculator/features/dashboard/domain/usecases/watch_recent_estimations_usecase.dart';
import 'package:construculator/features/dashboard/presentation/bloc/dashboard_bloc/dashboard_bloc.dart';
import 'package:construculator/features/dashboard/presentation/bloc/project_search_bloc/project_search_bloc.dart';
import 'package:construculator/features/dashboard/presentation/bloc/project_settings_bloc/project_settings_bloc.dart';
import 'package:construculator/features/dashboard/presentation/bloc/recent_estimations_bloc/recent_estimations_bloc.dart';
import 'package:construculator/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:construculator/features/dashboard/presentation/pages/project_search_page.dart';
import 'package:construculator/libraries/auth/auth_library_module.dart';
import 'package:construculator/libraries/auth/interfaces/auth_manager.dart';
import 'package:construculator/libraries/auth/interfaces/auth_notifier.dart';
import 'package:construculator/libraries/estimation/estimation_library_module.dart';
import 'package:construculator/libraries/project/project_library_module.dart';
import 'package:construculator/libraries/router/guards/auth_guard.dart';
import 'package:construculator/libraries/router/interfaces/app_router.dart';
import 'package:construculator/libraries/router/router_module.dart';
import 'package:construculator/libraries/router/routes/dashboard_routes.dart';
import 'package:construculator/libraries/router/routes/project_search_routes.dart';
import 'package:flutter_modular/flutter_modular.dart';

class DashboardModule extends Module {
  final AppBootstrap appBootstrap;
  DashboardModule(this.appBootstrap);
  @override
  List<Module> get imports => [
    AuthLibraryModule(appBootstrap),
    ProjectLibraryModule(appBootstrap),
    EstimationLibraryModule(appBootstrap),
    RouterModule(),
  ];

  @override
  void binds(Injector i) {
    i.add<WatchRecentEstimationsUseCase>(
      () => WatchRecentEstimationsUseCase(i(), i()),
    );
    i.add<RecentEstimationsBloc>(
      () => RecentEstimationsBloc(
        watchRecentEstimationsUseCase: i(),
        currentProjectNotifier: i(),
      ),
    );
    i.add<DashboardBloc>(
      () => DashboardBloc(
        projectRepository: i(),
        currentProjectNotifier: i(),
      ),
    );
    i.add<ProjectSettingsBloc>(
      () => ProjectSettingsBloc(repository: i()),
    );
    i.add<ProjectSearchBloc>(
      () => ProjectSearchBloc(repository: i(), authManager: i()),
    );
  }

  @override
  void routes(RouteManager r) {
    r.child(
      dashboardRoute,
      guards: [AuthGuard(() => Modular.get<AuthManager>())],
      child: (context) => DashboardPage(
        authNotifier: Modular.get<AuthNotifier>(),
        authManager: Modular.get<AuthManager>(),
        router: Modular.get<AppRouter>(),
        recentEstimationsBloc: Modular.get<RecentEstimationsBloc>(),
        appShellBloc: Modular.get<AppShellBloc>(),
      ),
    );
    r.child(
      projectSearchRoute,
      guards: [AuthGuard(() => Modular.get<AuthManager>())],
      child: (_) => ProjectSearchPage(
        router: Modular.get<AppRouter>(),
        blocFactory: () => Modular.get<ProjectSearchBloc>(),
      ),
    );
  }
}
