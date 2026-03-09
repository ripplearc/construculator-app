import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/app/shell/module_model.dart';
import 'package:construculator/app/shell/default_tab_providers.dart';

enum ShellTab { home, calculations, estimation, members }

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

  Future<void> ensureTabModuleLoaded(ShellTab tab) async {
    if (_loadedTabs.contains(tab)) return;
    final provider = _providers[tab];
    if (provider != null) {
      await provider.load(appBootstrap);
    }
    _loadedTabs.add(tab);
  }

  bool isLoaded(ShellTab tab) => _loadedTabs.contains(tab);
}
