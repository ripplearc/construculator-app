import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/app/shell/app_shell_bloc/app_shell_bloc.dart';
import 'package:construculator/app/shell/app_shell_page.dart';
import 'package:construculator/app/shell/tab_module_manager.dart';
import 'package:construculator/features/dashboard/domain/usecases/watch_recent_estimations_usecase.dart';
import 'package:construculator/features/dashboard/presentation/bloc/project_dropdown_bloc/project_dropdown_bloc.dart';
import 'package:construculator/features/dashboard/presentation/bloc/recent_estimations_bloc/recent_estimations_bloc.dart';
import 'package:construculator/features/estimation/estimation_routes_module.dart';
import 'package:construculator/features/global_search/global_search_module.dart';
import 'package:construculator/libraries/auth/auth_library_module.dart';
import 'package:construculator/libraries/auth/interfaces/auth_manager.dart';
import 'package:construculator/libraries/auth/interfaces/auth_notifier.dart';
import 'package:construculator/libraries/estimation/estimation_library_module.dart';
import 'package:construculator/libraries/project/interfaces/current_project_notifier.dart';
import 'package:construculator/libraries/project/presentation/project_ui_provider.dart';
import 'package:construculator/libraries/project/project_library_module.dart';
import 'package:construculator/libraries/router/guards/auth_guard.dart';
import 'package:construculator/libraries/router/interfaces/app_router.dart';
import 'package:construculator/libraries/router/routes/estimation_routes.dart';
import 'package:construculator/libraries/router/routes/global_search_routes.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';

/// Modular module that owns the app shell's dependency bindings and root route.
class ShellModule extends Module {
  final AppBootstrap appBootstrap;
  ShellModule(this.appBootstrap);

  @override
  List<Module> get imports => [
    AuthLibraryModule(appBootstrap),
    ProjectLibraryModule(appBootstrap),
    EstimationLibraryModule(appBootstrap),
  ];

  @override
  void binds(Injector i) {
    i.addSingleton<TabModuleManager>(() => TabModuleManager(appBootstrap));
    i.add<AppShellBloc>(
      () => AppShellBloc(moduleLoader: i.get()),
    );
    i.addLazySingleton<ProjectDropdownBloc>(
      () => ProjectDropdownBloc(
        projectRepository: i(),
        authManager: i(),
      ),
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
      '/',
      // TODO: [CA-708] Remove authNotifier, authManager, router once DashboardPage reads auth from the module directly.
      // https://ripplearc.youtrack.cloud/issue/CA-708
      child: (_) => MultiBlocProvider(
        providers: [
          BlocProvider<AppShellBloc>(
            create: (_) => Modular.get<AppShellBloc>(),
          ),
          BlocProvider<ProjectDropdownBloc>(
            create: (_) => Modular.get<ProjectDropdownBloc>(),
          ),
          BlocProvider<RecentEstimationsBloc>(
            create: (_) => Modular.get<RecentEstimationsBloc>(),
          ),
        ],
        child: AppShellPage(
          projectUIProvider: Modular.get<ProjectUIProvider>(),
          currentProjectNotifier: Modular.get<CurrentProjectNotifier>(),
          authNotifier: Modular.get<AuthNotifier>(),
          authManager: Modular.get<AuthManager>(),
          router: Modular.get<AppRouter>(),
        ),
      ),
      guards: [AuthGuard(() => Modular.get<AuthManager>())],
      children: [
        ModuleRoute(
          estimationBaseRoute,
          module: EstimationRoutesModule(appBootstrap),
        ),
      ],
    );
    r.module(globalSearchBaseRoute, module: GlobalSearchModule(appBootstrap));
  }
}
