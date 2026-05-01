import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/app/shell/module_model.dart';

/// Default provider that does nothing. Useful as a safe fallback when
/// feature-specific modules are not available.
class NoOpTabModuleProvider implements TabModuleProvider {
  const NoOpTabModuleProvider();

  @override
  Future<void> load(AppBootstrap appBootstrap) async {
    return;
  }
}
