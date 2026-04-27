import 'package:construculator/app/app_bootstrap.dart';

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

/// Provides a way to lazily load a feature/module for a shell tab
abstract class TabModuleProvider {
  /// Called when the tab's module should be loaded.
  /// Implementations should bind or register their module with the DI system.
  Future<void> load(AppBootstrap appBootstrap);
}
