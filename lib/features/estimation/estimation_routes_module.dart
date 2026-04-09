import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/auth/auth_module.dart';
import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/features/estimation/presentation/pages/cost_estimation_details_page.dart';
import 'package:construculator/libraries/router/guards/auth_guard.dart';
import 'package:construculator/libraries/router/routes/estimation_routes.dart';
import 'package:flutter_modular/flutter_modular.dart';

/// Modular module owning Tier-1 (full-screen) routes for the Estimation feature.
///
/// Imports [EstimationModule] for shared data-layer bindings, and registers
/// the [CostEstimationDetailsPage] route behind an [AuthGuard].
class EstimationRoutesModule extends Module {
  final AppBootstrap appBootstrap;
  EstimationRoutesModule(this.appBootstrap);

  @override
  List<Module> get imports => [
    AuthModule(appBootstrap),
    EstimationModule(appBootstrap),
  ];

  @override
  void routes(RouteManager r) {
    r.child(
      estimationDetailsRoute,
      guards: [AuthGuard()],
      child: (context) {
        final estimationId = Modular.args.params['estimationId'];

        if (estimationId == null || estimationId.isEmpty) {
          throw ArgumentError(
            'estimationId is required for CostEstimationDetailsPage. '
            'Ensure the route includes a valid estimationId parameter.',
          );
        }

        return CostEstimationDetailsPage(estimationId: estimationId);
      },
    );
  }
}
