import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/app/shell/app_shell_bloc/app_shell_bloc.dart';
import 'package:construculator/features/dashboard/presentation/bloc/dashboard_bloc/dashboard_bloc.dart';
import 'package:construculator/features/dashboard/presentation/bloc/project_settings_bloc/project_settings_bloc.dart';
import 'package:construculator/features/dashboard/presentation/bloc/recent_estimations_bloc/recent_estimations_bloc.dart';
import 'package:construculator/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:construculator/libraries/auth/auth_library_module.dart';
import 'package:construculator/libraries/auth/interfaces/auth_manager.dart';
import 'package:construculator/libraries/auth/interfaces/auth_notifier.dart';
import 'package:construculator/libraries/project/project_library_module.dart';
import 'package:construculator/libraries/router/guards/auth_guard.dart';
import 'package:construculator/libraries/router/interfaces/app_router.dart';
import 'package:construculator/libraries/router/router_module.dart';
import 'package:construculator/libraries/router/routes/dashboard_routes.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';

class DashboardModule extends Module {
  final AppBootstrap appBootstrap;
  DashboardModule(this.appBootstrap);
  @override
  List<Module> get imports => [
    AuthLibraryModule(appBootstrap),
    ProjectLibraryModule(appBootstrap),
    RouterModule(),
  ];

  @override
  void binds(Injector i) {
    i.add<DashboardBloc>(
      () => DashboardBloc(
        projectRepository: i(),
        currentProjectNotifier: i(),
      ),
    );
    i.add<ProjectSettingsBloc>(
      () => ProjectSettingsBloc(repository: i()),
    );
  }

  @override
  void routes(RouteManager r) {
    r.child(
      dashboardRoute,
      guards: [AuthGuard(() => Modular.get<AuthManager>())],
      // TODO: [CA-708] Remove authNotifier, authManager once DashboardPage reads auth from the module directly.
      // https://ripplearc.youtrack.cloud/issue/CA-708
      child: (context) => MultiBlocProvider(
        providers: [
          BlocProvider<RecentEstimationsBloc>(
            create: (_) => Modular.get<RecentEstimationsBloc>(),
          ),
          BlocProvider<AppShellBloc>(
            create: (_) => Modular.get<AppShellBloc>(),
          ),
        ],
        child: DashboardPage(
          authNotifier: Modular.get<AuthNotifier>(),
          authManager: Modular.get<AuthManager>(),
          router: Modular.get<AppRouter>(),
        ),
      ),
    );
  }
}
