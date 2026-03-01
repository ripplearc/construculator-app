import 'package:flutter_modular/flutter_modular.dart';
import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/dashboard/dashboard_module.dart';
import 'package:construculator/features/calculations/calculations_module.dart';
import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/features/members/members_module.dart';

enum ShellTab { home, calculations, estimation, members }

class TabModuleLoader {
  final AppBootstrap appBootstrap;
  final Set<ShellTab> _loadedTabs = {};

  TabModuleLoader(this.appBootstrap);

  Future<void> ensureTabModuleLoaded(ShellTab tab) async {
    if (_loadedTabs.contains(tab)) return;
    switch (tab) {
      case ShellTab.home:
        Modular.bindModule(DashboardModule(appBootstrap));
        break;
      case ShellTab.calculations:
        Modular.bindModule(CalculationsModule(appBootstrap));
        break;
      case ShellTab.estimation:
        Modular.bindModule(EstimationModule(appBootstrap));
        break;
      case ShellTab.members:
        Modular.bindModule(MembersModule(appBootstrap));
        break;
    }
    _loadedTabs.add(tab);
  }

  bool isLoaded(ShellTab tab) => _loadedTabs.contains(tab);
}
