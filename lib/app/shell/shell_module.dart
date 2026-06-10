import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/app/shell/app_shell_bloc/app_shell_bloc.dart';
import 'package:construculator/app/shell/app_shell_page.dart';
import 'package:construculator/app/shell/tab_module_manager.dart';
import 'package:construculator/features/dashboard/presentation/bloc/project_dropdown_bloc/project_dropdown_bloc.dart';
import 'package:construculator/features/estimation/estimation_routes_module.dart';
import 'package:construculator/libraries/router/guards/auth_guard.dart';
import 'package:construculator/libraries/router/routes/estimation_routes.dart';
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
      child: (_) => const AppShellPage(),
      guards: [AuthGuard()],
      children: [
        ModuleRoute(
          estimationBaseRoute,
          module: EstimationRoutesModule(appBootstrap),
        ),
      ],
    );
  }
}
