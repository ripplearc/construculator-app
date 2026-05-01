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
    ShellTab.home: const NoOpTabModuleProvider(),
    ShellTab.calculations: const NoOpTabModuleProvider(),
    ShellTab.estimation: const NoOpTabModuleProvider(),
    ShellTab.members: const NoOpTabModuleProvider(),
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
