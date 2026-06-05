import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/app/shell/app_shell_bloc/app_shell_bloc.dart';
import 'package:construculator/app/shell/app_shell_page.dart';
import 'package:construculator/app/shell/tab_module_manager.dart';
import 'package:construculator/features/estimation/estimation_routes_module.dart';
import 'package:construculator/features/global_search/global_search_module.dart';
import 'package:construculator/libraries/project/interfaces/current_project_notifier.dart';
import 'package:construculator/libraries/router/guards/auth_guard.dart';
import 'package:construculator/libraries/router/routes/estimation_routes.dart';
import 'package:construculator/libraries/router/routes/global_search_routes.dart';
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
        currentProjectNotifier: Modular.get<CurrentProjectNotifier>(),
      ),
    );
  }

  @override
  void routes(RouteManager r) {
    r.child(
      '/',
      child: (_) => const AppShellPage(),
      guards: [AuthGuard()],
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
