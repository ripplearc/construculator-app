import 'package:flutter_modular/flutter_modular.dart';
import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/app/shell/default_tab_providers.dart';
import 'package:construculator/app/shell/module_model.dart';

/// Represents the tabs available in the app shell's bottom navigation bar.
enum ShellTab {
  /// The home/dashboard tab.
  home,

  /// The calculations feature tab.
  calculations,

  /// The cost estimation feature tab.
  estimation,

  /// The team members feature tab.
  members,
}

class TabModuleManager {
  final AppBootstrap appBootstrap;
  final Set<ShellTab> _loadedTabs = {};

  TabModuleManager(this.appBootstrap);

  /// Ensures the module for [tab] is loaded, calling its provider exactly once.
  /// Subsequent calls for the same tab are no-ops.
  Future<void> ensureTabModuleLoaded(ShellTab tab) async {
    if (_loadedTabs.contains(tab)) return;
    switch (tab) {
      case ShellTab.home:
        Modular.bindModule(DashboardModule(appBootstrap));
        break;
      case ShellTab.calculations:
        Modular.bindModule(CalculationsModule());
        break;
      case ShellTab.estimation:
        Modular.bindModule(EstimationModule(appBootstrap));
        break;
      case ShellTab.members:
        Modular.bindModule(MembersModule());
        break;
    }
    _loadedTabs.add(tab);
  }

  /// Returns `true` if the module for [tab] has already been loaded.
  bool isLoaded(ShellTab tab) => _loadedTabs.contains(tab);
}
