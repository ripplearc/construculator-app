import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/app/shell/module_model.dart';
import 'package:construculator/features/calculations/calculations_module.dart';
import 'package:construculator/features/dashboard/dashboard_module.dart';
import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/features/members/members_module.dart';
import 'package:flutter_modular/flutter_modular.dart';
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

/// Manages lazy loading of modules for shell tabs.
///
/// Modules are provided via `TabModuleProvider`. Feature branches can supply
/// their own providers when constructing this manager. When no providers are
/// supplied the manager uses safe no-op defaults so the main branch can run
/// without depending on feature-specific modules.
class TabModuleManager {
  final AppBootstrap appBootstrap;
  final Map<ShellTab, TabModuleProvider> _providers;
  final Set<ShellTab> _loadedTabs = {};

  TabModuleManager(
    this.appBootstrap, {
    Map<ShellTab, TabModuleProvider>? providers,
  }) : _providers = providers ?? _defaultProviders();

  static Map<ShellTab, TabModuleProvider> _defaultProviders() => {
    ShellTab.home: const _ProductionTabModuleProvider(ShellTab.home),
    ShellTab.calculations: const _ProductionTabModuleProvider(ShellTab.calculations),
    ShellTab.estimation: const _ProductionTabModuleProvider(ShellTab.estimation),
    ShellTab.members: const _ProductionTabModuleProvider(ShellTab.members),
  };

  /// Ensures the module for [tab] is loaded, calling its provider exactly once.
  /// Subsequent calls for the same tab are no-ops.
  Future<void> ensureTabModuleLoaded(ShellTab tab) async {
    if (_loadedTabs.contains(tab)) return;
    final provider = _providers[tab];
    if (provider != null) {
      await provider.load(appBootstrap);
    }
    _loadedTabs.add(tab);
  }

  /// Returns `true` if the module for [tab] has already been loaded.
  bool isLoaded(ShellTab tab) => _loadedTabs.contains(tab);
}

class _ProductionTabModuleProvider implements TabModuleProvider {
  final ShellTab tab;

  const _ProductionTabModuleProvider(this.tab);

  @override
  Future<void> load(AppBootstrap appBootstrap) async {
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
  }
}
