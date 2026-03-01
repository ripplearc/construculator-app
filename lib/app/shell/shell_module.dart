import 'package:flutter_modular/flutter_modular.dart';
import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/app/shell/app_shell_page.dart';
import 'package:construculator/app/shell/tab_module_loader.dart';

class ShellModule extends Module {
  final AppBootstrap appBootstrap;
  ShellModule(this.appBootstrap);

  @override
  void binds(Injector i) {
    i.addSingleton<TabModuleLoader>(() => TabModuleLoader(appBootstrap));
    // Add other shell-specific dependencies here
  }

  @override
  void routes(RouteManager r) {
    r.child('/', child: (_) => const AppShellPage());
    // Add other shell-level routes if needed
  }
}
