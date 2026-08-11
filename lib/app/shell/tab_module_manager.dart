import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/app/shell/module_model.dart';
import 'package:construculator/features/calculations/calculations_module.dart';
import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:flutter_modular/flutter_modular.dart';

export 'package:construculator/app/shell/module_model.dart' show ShellTab;

/// Manages lazy loading of feature modules for each shell tab.
///
/// Modules are provided via [TabModuleProvider]. Tests can supply lightweight
/// fake providers; production uses [_ProductionTabModuleProvider] by default.
class TabModuleManager {
  final AppBootstrap appBootstrap;
  final Map<ShellTab, TabModuleProvider> _providers;
  final Set<ShellTab> _loadedTabs = {};

  TabModuleManager(
    this.appBootstrap, {
    Map<ShellTab, TabModuleProvider>? providers,
  }) : _providers = providers ?? _defaultProviders();

  static Map<ShellTab, TabModuleProvider> _defaultProviders() => {
    ShellTab.calculations: const _ProductionTabModuleProvider(ShellTab.calculations),
    ShellTab.estimates: const _ProductionTabModuleProvider(ShellTab.estimates),
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

/// A private provider implementation that lazily instantiates feature modules.
///
/// While real instances are generally encouraged, this provider defers the
/// construction of heavy feature modules (like [CalculationsModule],
/// [EstimationModule], etc.) until their tab is explicitly loaded. This avoids
/// the overhead of constructing all module instances sequentially on fresh launch.
class _ProductionTabModuleProvider implements TabModuleProvider {
  final ShellTab tab;

  const _ProductionTabModuleProvider(this.tab);

  @override
  Future<void> load(AppBootstrap appBootstrap) async {
    switch (tab) {
      case ShellTab.calculations:
        Modular.bindModule(CalculationsModule());
        break;
      case ShellTab.estimates:
        Modular.bindModule(EstimationModule(appBootstrap));
        break;
    }
  }
}
