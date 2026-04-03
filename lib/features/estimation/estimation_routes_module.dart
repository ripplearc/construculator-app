import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/auth/auth_module.dart';
import 'package:construculator/features/estimation/presentation/pages/cost_estimation_details_page.dart';
import 'package:construculator/libraries/estimation/estimation_core_module.dart';
import 'package:construculator/libraries/router/guards/auth_guard.dart';
import 'package:construculator/libraries/router/routes/estimation_routes.dart';
import 'package:flutter_modular/flutter_modular.dart';

class EstimationRoutesModule extends Module {
  final AppBootstrap appBootstrap;
  EstimationRoutesModule(this.appBootstrap);

  @override
  List<Module> get imports => [
    AuthModule(appBootstrap),
    EstimationCoreModule(appBootstrap),
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
