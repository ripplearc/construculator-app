import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/features/estimation/presentation/bloc/equipment_cost_form_bloc/equipment_cost_form_bloc.dart';
import 'package:construculator/features/estimation/presentation/bloc/labour_cost_form_bloc/labour_cost_form_bloc.dart';
import 'package:construculator/features/estimation/presentation/bloc/material_cost_form_bloc/material_cost_form_bloc.dart';
import 'package:construculator/features/estimation/presentation/pages/cost_estimation_details_page.dart';
import 'package:construculator/features/estimation/presentation/pages/cost_item_form_screen.dart';
import 'package:construculator/libraries/auth/auth_library_module.dart';
import 'package:construculator/libraries/auth/interfaces/auth_manager.dart';
import 'package:construculator/libraries/router/guards/auth_guard.dart';
import 'package:construculator/libraries/router/interfaces/app_router.dart';
import 'package:construculator/libraries/router/routes/estimation_routes.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
    AuthLibraryModule(appBootstrap),
    EstimationModule(appBootstrap),
  ];

  @override
  void routes(RouteManager r) {
    r.child(
      estimationDetailsRoute,
      guards: [AuthGuard(() => Modular.get<AuthManager>())],
      child: (context) {
        final estimationId = Modular.args.params['estimationId'];

        if (estimationId == null || estimationId.isEmpty) {
          throw ArgumentError(
            'estimationId is required for CostEstimationDetailsPage. '
            'Ensure the route includes a valid estimationId parameter.',
          );
        }

        return CostEstimationDetailsPage(
          estimationId: estimationId,
          router: Modular.get<AppRouter>(),
        );
      },
    );

    r.child(
      addMaterialCostRoute,
      guards: [AuthGuard(() => Modular.get<AuthManager>())],
      child: (context) {
        final estimationId = Modular.args.params['estimationId'];
        if (estimationId == null || estimationId.isEmpty) {
          throw ArgumentError(
            'estimationId is required for CostItemFormScreen. '
            'Ensure the route includes a valid estimationId parameter.',
          );
        }
        return BlocProvider<MaterialCostFormBloc>(
          create: (_) => Modular.get<MaterialCostFormBloc>(),
          child: CostItemFormScreen(
            type: CostItemType.material,
            estimationId: estimationId,
            router: Modular.get<AppRouter>(),
          ),
        );
      },
    );

    r.child(
      addLabourCostRoute,
      guards: [AuthGuard(() => Modular.get<AuthManager>())],
      child: (context) {
        final estimationId = Modular.args.params['estimationId'];
        if (estimationId == null || estimationId.isEmpty) {
          throw ArgumentError(
            'estimationId is required for CostItemFormScreen. '
            'Ensure the route includes a valid estimationId parameter.',
          );
        }
        return BlocProvider<LabourCostFormBloc>(
          create: (_) => Modular.get<LabourCostFormBloc>(),
          child: CostItemFormScreen(
            type: CostItemType.labor,
            estimationId: estimationId,
            router: Modular.get<AppRouter>(),
          ),
        );
      },
    );

    r.child(
      addEquipmentCostRoute,
      guards: [AuthGuard(() => Modular.get<AuthManager>())],
      child: (context) {
        final estimationId = Modular.args.params['estimationId'];
        if (estimationId == null || estimationId.isEmpty) {
          throw ArgumentError(
            'estimationId is required for CostItemFormScreen. '
            'Ensure the route includes a valid estimationId parameter.',
          );
        }
        return BlocProvider<EquipmentCostFormBloc>(
          create: (_) => Modular.get<EquipmentCostFormBloc>(),
          child: CostItemFormScreen(
            type: CostItemType.equipment,
            estimationId: estimationId,
            router: Modular.get<AppRouter>(),
          ),
        );
      },
    );
  }
}
