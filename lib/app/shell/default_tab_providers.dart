import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/app/shell/module_model.dart';
import 'package:flutter/material.dart';

/// Default provider that does nothing. Useful as a safe fallback when
/// feature-specific modules are not available.
class NoOpTabModuleProvider implements TabModuleProvider {
  const NoOpTabModuleProvider();

  @override
  Future<void> load(AppBootstrap appBootstrap) async {
    return;
  }

  @override
  Widget buildRoot(BuildContext context) => const SizedBox.shrink();
}
