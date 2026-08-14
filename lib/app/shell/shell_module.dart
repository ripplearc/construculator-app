import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/app/shell/app_shell_bloc/app_shell_bloc.dart';
import 'package:construculator/app/shell/app_shell_page.dart';
import 'package:construculator/app/shell/tab_module_manager.dart';
import 'package:construculator/features/app_header/app_header_module.dart';
import 'package:construculator/features/calculator/calculator_module.dart';
import 'package:construculator/features/dashboard/dashboard_module.dart';
import 'package:construculator/features/dashboard/domain/usecases/watch_recent_estimations_usecase.dart';
import 'package:construculator/features/dashboard/presentation/bloc/dashboard_bloc/dashboard_bloc.dart';
import 'package:construculator/features/dashboard/presentation/bloc/project_dropdown_bloc/project_dropdown_bloc.dart';
import 'package:construculator/features/dashboard/presentation/bloc/project_search_bloc/project_search_bloc.dart';
import 'package:construculator/features/dashboard/presentation/bloc/recent_estimations_bloc/recent_estimations_bloc.dart';
import 'package:construculator/features/dashboard/presentation/pages/project_search_page.dart';
import 'package:construculator/features/estimation/estimation_routes_module.dart';
import 'package:construculator/features/global_search/global_search_module.dart';
import 'package:construculator/features/project_settings/project_settings_routes_module.dart';
import 'package:construculator/libraries/auth/auth_library_module.dart';
import 'package:construculator/libraries/auth/interfaces/auth_manager.dart';
import 'package:construculator/libraries/config/env_constants.dart';
import 'package:construculator/libraries/consent/consent_library_module.dart';
import 'package:construculator/libraries/consent/domain/usecases/check_consent_status_usecase.dart';
import 'package:construculator/libraries/estimation/estimation_library_module.dart';
import 'package:construculator/libraries/project/interfaces/current_project_notifier.dart';
import 'package:construculator/libraries/project/presentation/project_ui_provider.dart';
import 'package:construculator/libraries/project/project_library_module.dart';
import 'package:construculator/libraries/router/guards/auth_guard.dart';
import 'package:construculator/libraries/router/guards/consent_guard.dart';
import 'package:construculator/libraries/router/interfaces/app_router.dart';
import 'package:construculator/libraries/router/routes/calculator_routes.dart';
import 'package:construculator/libraries/router/routes/estimation_routes.dart';
import 'package:construculator/libraries/router/routes/global_search_routes.dart';
import 'package:construculator/libraries/router/routes/project_search_routes.dart';
import 'package:construculator/libraries/router/routes/project_settings_routes.dart';
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
    ConsentLibraryModule(appBootstrap),
    DashboardModule(appBootstrap),
    AppHeaderModule(),
  ];

  /// Guards protecting the authenticated shell.
  ///
  /// [AuthGuard] is unconditional and always first, so [ConsentGuard] only
  /// ever evaluates for a signed-in user. The consent gate is opt-in until
  /// CA-971 lands — see [consentGateEnabledKey] for why enabling it against
  /// the in-memory stand-in would lock users out.
  List<RouteGuard> get _shellGuards => [
    AuthGuard(() => Modular.get<AuthManager>()),
    if (appBootstrap.envLoader.get(consentGateEnabledKey) == 'true')
      ConsentGuard(() => Modular.get<CheckConsentStatusUseCase>()),
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
      child: (_) => MultiBlocProvider(
        providers: [
          BlocProvider<DashboardBloc>(
            create: (_) => Modular.get<DashboardBloc>()..add(const DashboardStarted()),
          ),
          BlocProvider<AppShellBloc>(
            create: (_) => Modular.get<AppShellBloc>(),
          ),
          BlocProvider<ProjectDropdownBloc>.value(
            value: Modular.get<ProjectDropdownBloc>(),
          ),
          BlocProvider<RecentEstimationsBloc>(
            create: (_) => Modular.get<RecentEstimationsBloc>()
                ..add(const RecentEstimationsWatchStarted()),
          ),
        ],
        child: AppShellPage(
          projectUIProvider: Modular.get<ProjectUIProvider>(),
          currentProjectNotifier: Modular.get<CurrentProjectNotifier>(),
          router: Modular.get<AppRouter>(),
        ),
      ),
      guards: _shellGuards,
      children: [
        ModuleRoute(calculatorBaseRoute, module: CalculatorModule()),
        ModuleRoute(
          estimationBaseRoute,
          module: EstimationRoutesModule(appBootstrap),
        ),
        ModuleRoute(
          projectSettingsBaseRoute,
          module: ProjectSettingsRoutesModule(appBootstrap),
        ),
      ],
    );
    r.child(
      projectSearchRoute,
      guards: [AuthGuard(() => Modular.get<AuthManager>())],
      child: (_) => ProjectSearchPage(
        router: Modular.get<AppRouter>(),
        blocFactory: () => Modular.get<ProjectSearchBloc>(),
      ),
    );
    r.module(globalSearchBaseRoute, module: GlobalSearchModule(appBootstrap));
  }
}
