import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/app/shell/module_model.dart';
import 'package:construculator/features/calculations/calculations_tab_provider.dart';
import 'package:construculator/features/estimation/estimation_tab_provider.dart';

export 'package:construculator/app/shell/module_model.dart' show ShellTab;

/// Manages lazy loading of feature modules for each shell tab.
///
/// Modules are provided via [TabModuleProvider]. Tests can supply lightweight
/// fake providers; production uses one real provider per feature by default.
class TabModuleManager {
  final AppBootstrap appBootstrap;
  final Map<ShellTab, TabModuleProvider> _providers;
  final Set<ShellTab> _loadedTabs = {};

  TabModuleManager(
    this.appBootstrap, {
    Map<ShellTab, TabModuleProvider>? providers,
  }) : _providers = providers ?? _defaultProviders();

  static Map<ShellTab, TabModuleProvider> _defaultProviders() => {
    ShellTab.calculations: const CalculationsTabProvider(),
    ShellTab.estimates: const EstimationTabProvider(),
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

  /// Returns the [TabModuleProvider] registered for [tab], or `null` if no
  /// provider is registered — a well-defined case a tab with no provider
  /// (i.e. excluded from this build) is expected to hit.
  TabModuleProvider? providerFor(ShellTab tab) => _providers[tab];
}
