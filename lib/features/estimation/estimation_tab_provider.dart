import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/app/shell/module_model.dart';
import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

/// Loads the Estimation feature module and builds its tab root widget.
///
/// The only file outside the Estimation feature permitted to name
/// [EstimationModule].
class EstimationTabProvider implements TabModuleProvider {
  /// Creates an [EstimationTabProvider].
  const EstimationTabProvider();

  /// Binds [EstimationModule] with the DI system.
  @override
  Future<void> load(AppBootstrap appBootstrap) async {
    Modular.bindModule(EstimationModule(appBootstrap));
  }

  /// Builds the Estimation tab's root widget.
  @override
  Widget buildRoot(BuildContext context) => EstimationModule.landingPage();
}
