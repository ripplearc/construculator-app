import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/app/shell/app_shell_bloc/app_shell_bloc.dart';
import 'package:construculator/app/shell/app_shell_page.dart';
import 'package:construculator/app/shell/tab_module_manager.dart';
import 'package:construculator/features/dashboard/presentation/bloc/project_dropdown_bloc/project_dropdown_bloc.dart';
import 'package:construculator/features/estimation/estimation_routes_module.dart';
import 'package:construculator/features/global_search/global_search_module.dart';
import 'package:construculator/libraries/auth/interfaces/auth_manager.dart';
import 'package:construculator/libraries/auth/interfaces/auth_notifier.dart';
import 'package:construculator/libraries/project/presentation/project_ui_provider.dart';
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
  void binds(Injector i) {
    i.addSingleton<TabModuleManager>(() => TabModuleManager(appBootstrap));
    i.add<AppShellBloc>(
      () => AppShellBloc(
        moduleLoader: i.get(),
        projectDropdownBlocFactory: () => Modular.get<ProjectDropdownBloc>(),
      ),
    );
  }

  @override
  void routes(RouteManager r) {
    r.child(
      '/',
      child: (_) => BlocProvider<AppShellBloc>(
        create: (_) => Modular.get<AppShellBloc>(),
        // TODO: [CA-708] Remove authNotifier, authManager, and router from AppShellPage once DashboardPage reads them from the module directly.
        // https://ripplearc.youtrack.cloud/issue/CA-708
        child: AppShellPage(
          projectUIProvider: Modular.get<ProjectUIProvider>(),
          authNotifier: Modular.get<AuthNotifier>(),
          authManager: Modular.get<AuthManager>(),
          router: Modular.get<AppRouter>(),
        ),
      ),
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
