import 'package:construculator/app/app_bootstrap.dart';

/// Provides a way to lazily load a feature/module for a shell tab
abstract class TabModuleProvider {
  /// Called when the tab's module should be loaded.
  /// Implementations should bind or register their module with the DI system.
  Future<void> load(AppBootstrap appBootstrap);
}
