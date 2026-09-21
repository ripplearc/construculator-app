import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/app/shell/app_shell_bloc/app_shell_bloc.dart';
import 'package:construculator/app/shell/app_shell_page.dart';
import 'package:construculator/app/shell/feature_unavailable_module.dart';
import 'package:construculator/app/shell/tab_module_manager.dart';
import 'package:construculator/features/app_header/app_header_module.dart';
import 'package:construculator/features/calculator/calculator_module.dart';
import 'package:construculator/features/dashboard/dashboard_module.dart';
import 'package:construculator/features/dashboard/presentation/bloc/project_dropdown_bloc/project_dropdown_bloc.dart';
import 'package:construculator/features/dashboard/presentation/bloc/project_search_bloc/project_search_bloc.dart';
import 'package:construculator/features/dashboard/presentation/pages/project_search_page.dart';
import 'package:construculator/features/estimation/estimation_routes_module.dart';
import 'package:construculator/features/global_search/global_search_module.dart';
import 'package:construculator/features/project_settings/project_settings_routes_module.dart';
import 'package:construculator/libraries/analytics/feature_flag_module.dart';
import 'package:construculator/libraries/auth/auth_library_module.dart';
import 'package:construculator/libraries/auth/interfaces/auth_manager.dart';
import 'package:construculator/libraries/config/build_features.dart';
import 'package:construculator/libraries/config/feature_availability.dart';
import 'package:construculator/libraries/consent/consent_gate_readiness.dart';
import 'package:construculator/libraries/consent/consent_library_module.dart';
import 'package:construculator/libraries/consent/domain/usecases/check_consent_status_usecase.dart';
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

  /// Seam for [consentGateEnabled]'s `persistenceReady`; the app never
  /// passes it, so the shell always gets the compile-time answer.
  final bool persistenceReady;

  ShellModule(
    this.appBootstrap, {
    this.persistenceReady = consentPersistenceReady,
  });

  @override
  List<Module> get imports => [
    AuthLibraryModule(appBootstrap),
    ProjectLibraryModule(appBootstrap),
    ConsentLibraryModule(appBootstrap),
    DashboardModule(appBootstrap),
    AppHeaderModule(),
    FeatureFlagModule(appBootstrap),
  ];

  /// Guards protecting the authenticated shell.
  ///
  /// [AuthGuard] is unconditional and always first, so [ConsentGuard] only
  /// ever evaluates for a signed-in user. The consent gate additionally
  /// requires [consentPersistenceReady], so no `.env` value alone can mount
  /// a gate this build cannot durably record an acceptance for.
  List<RouteGuard> get _shellGuards => [
    AuthGuard(() => Modular.get<AuthManager>()),
    if (consentGateEnabled(
      appBootstrap.envLoader,
      persistenceReady: persistenceReady,
    ))
      ConsentGuard(() => Modular.get<CheckConsentStatusUseCase>()),
  ];

  @override
  void binds(Injector i) {
    i.addSingleton<TabModuleManager>(() => TabModuleManager(appBootstrap));
    i.add<AppShellBloc>(
      () => AppShellBloc(moduleLoader: i.get(), featureFlagRepository: i.get()),
    );
  }

  @override
  void routes(RouteManager r) {
    r.child(
      '/',
      child: (_) => BlocProvider<AppShellBloc>(
        create: (_) => Modular.get<AppShellBloc>(),
        child: DashboardModule.buildDashboardScope(
          child: AppShellPage(
            projectUIProvider: Modular.get<ProjectUIProvider>(),
            currentProjectNotifier: Modular.get<CurrentProjectNotifier>(),
            router: Modular.get<AppRouter>(),
            tabModuleManager: Modular.get<TabModuleManager>(),
          ),
        ),
      ),
      guards: _shellGuards,
    );
    // Estimation, project-settings, and calculator destinations are
    // full-screen pushes, so they must be top-level routes like the search
    // pages below: AppShellPage renders no RouterOutlet, and a child route
    // resolved under '/' has no outlet to mount into — Modular swallows the
    // push with no transition and no error (CA-900). The estimation and
    // project-settings inner routes carry their own AuthGuards, so the
    // top-level guards there are defence in depth for future inner routes;
    // the calculator's root route has no own guard, so its top-level guard
    // is load-bearing — it replaces the shell guard the route inherited
    // while nested.
    r.module(
      estimationBaseRoute,
      module: EstimationRoutesModule(appBootstrap),
      guards: [AuthGuard(() => Modular.get<AuthManager>())],
    );
    r.module(
      projectSettingsBaseRoute,
      module: ProjectSettingsRoutesModule(appBootstrap),
      guards: [AuthGuard(() => Modular.get<AuthManager>())],
    );
    // Calculator is an optional feature. The bare `BuildFeatures.calculator`
    // const is tested first so that on a build with `ENABLE_CALCULATOR: false`
    // the whole condition folds to false and the AOT compiler drops this call
    // and `CalculatorModule` with it. On every other build the const is true
    // and `FeatureAvailability.isEnabled` decides, which is the point the
    // exclusion tests flip.
    //
    // When the feature is absent, a route module at the same path renders the
    // fallback page, so a `/calculator` deep link resolves to a real page
    // instead of failing route resolution. It has to be a route module, not a
    // child route, for the same reason the calculator route itself is one:
    // AppShellPage renders no RouterOutlet, so a child route under `/` is
    // swallowed with no transition (CA-900).
    //
    // A global `WildcardRoute` is not used for this. Its `/**` pattern is
    // matched before Modular's trailing-slash retry, so it would also swallow
    // `/calculator` on a build that includes the calculator.
    if (BuildFeatures.calculator &&
        FeatureAvailability.isEnabled(Feature.calculator)) {
      r.module(
        calculatorBaseRoute,
        module: CalculatorModule(),
        guards: [AuthGuard(() => Modular.get<AuthManager>())],
      );
    } else {
      r.module(
        calculatorBaseRoute,
        module: FeatureUnavailableModule(),
        guards: [AuthGuard(() => Modular.get<AuthManager>())],
      );
    }
    r.child(
      projectSearchRoute,
      guards: [AuthGuard(() => Modular.get<AuthManager>())],
      child: (_) => ProjectSearchPage(
        router: Modular.get<AppRouter>(),
        blocFactory: () => Modular.get<ProjectSearchBloc>(),
        projectDropdownBloc: Modular.get<ProjectDropdownBloc>(),
      ),
    );
    r.module(globalSearchBaseRoute, module: GlobalSearchModule(appBootstrap));
  }
}
