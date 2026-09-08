import 'package:construculator/app/app_bootstrap.dart';
import 'package:flutter/material.dart';

/// Represents the tabs available in the app shell's bottom navigation bar.
enum ShellTab {
  /// The calculations feature tab.
  calculations,

  /// The cost estimates feature tab.
  estimates,
}

/// Provides a way to lazily load a feature/module for a shell tab
abstract class TabModuleProvider {
  /// Called when the tab's module should be loaded.
  /// Implementations should bind or register their module with the DI system.
  Future<void> load(AppBootstrap appBootstrap);

  /// Builds the tab's root widget.
  ///
  /// Called once the tab's module has been loaded, to construct the widget
  /// that becomes the root of that tab's navigator stack.
  Widget buildRoot(BuildContext context);
}
