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

  /// [CoreBottomNavBar] (CA-874) only supports 2-4 tabs. This is a real,
  /// unconditional check (not `assert`, which release/profile builds strip)
  /// so a registry that would render an unsupported nav fails at DI-bind
  /// time instead of shipping silently.
  static const int minSupportedTabs = 2;

  TabModuleManager(
    this.appBootstrap, {
    Map<ShellTab, TabModuleProvider>? providers,
  }) : _providers = providers ?? _defaultProviders() {
    if (_providers.length < minSupportedTabs) {
      throw StateError(
        'TabModuleManager requires at least $minSupportedTabs tab '
        'providers to render a supported CoreBottomNavBar (2-4 tabs), but '
        'only ${_providers.length} were registered: '
        '${_providers.keys.map((t) => t.name).join(', ')}.',
      );
    }
  }

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

  /// The [ShellTab]s to actually render, in [ShellTab.values] order.
  ///
  /// [ShellTab] stays a stable identity enum; this is the dynamic subset
  /// that has a registered provider. Bottom nav, the Offstage tab stack, and
  /// navigator keys all derive their rendered set from this getter instead
  /// of iterating [ShellTab.values] directly.
  List<ShellTab> get activeTabs =>
      ShellTab.values.where(_providers.containsKey).toList(growable: false);
}
