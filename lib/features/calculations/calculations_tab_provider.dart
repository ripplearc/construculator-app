import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/app/shell/module_model.dart';
import 'package:construculator/features/calculations/calculations_module.dart';
import 'package:construculator/features/calculations/presentation/pages/calculations_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

/// Loads the Calculations feature module and builds its tab root widget.
///
/// The only file outside the Calculations feature permitted to name
/// [CalculationsModule] or [CalculationsPage].
class CalculationsTabProvider implements TabModuleProvider {
  /// Creates a [CalculationsTabProvider].
  const CalculationsTabProvider();

  /// Binds [CalculationsModule] with the DI system.
  @override
  Future<void> load(AppBootstrap appBootstrap) async {
    Modular.bindModule(CalculationsModule());
  }

  /// Builds the Calculations tab's root widget.
  @override
  Widget buildRoot(BuildContext context) => const CalculationsPage();
}
