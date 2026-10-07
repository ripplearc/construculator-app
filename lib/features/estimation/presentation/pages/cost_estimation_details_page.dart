import 'dart:async';

import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/presentation/bloc/equipment_cost_form_bloc/equipment_cost_form_bloc.dart';
import 'package:construculator/features/estimation/presentation/bloc/estimate_summary_bloc/estimate_summary_bloc.dart';
import 'package:construculator/features/estimation/presentation/bloc/your_rates_bloc/your_rates_bloc.dart';
import 'package:construculator/features/estimation/presentation/pages/cost_item_form_screen.dart';
import 'package:construculator/features/estimation/presentation/widgets/added_to_estimate_toast.dart';
import 'package:construculator/features/estimation/presentation/widgets/cost_estimation_details_tab_view.dart';
import 'package:construculator/features/estimation/presentation/widgets/sheet_surface.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/estimation/domain/entities/cost_estimate_entity.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:construculator/libraries/router/interfaces/app_router.dart';
import 'package:construculator/libraries/router/routes/estimation_routes.dart';
import 'package:construculator/libraries/time/interfaces/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// The cost estimation details page.
///
/// Displays a tabbed view of [CostEstimationDetailsTabView] (Materials,
/// Labours, Equipments) with a custom app bar, context-aware FAB for adding
/// cost items, and a bottom bar with lock and preview actions.
class CostEstimationDetailsPage extends StatefulWidget {
  final String estimationId;

  /// Router used for navigation (e.g. popping this page).
  final AppRouter router;

  /// Builds an [EquipmentCostFormBloc] for the equipment cost sheet the FAB
  /// launches. Injected rather than resolved with `Modular.get` here, since
  /// this page isn't a module file.
  final EquipmentCostFormBloc Function() equipmentCostFormBlocFactory;

  /// Builds the [EstimateSummaryBloc] that loads this estimate's name and
  /// total for the equipment cost sheet. Same not-a-module-file reasoning as
  /// [equipmentCostFormBlocFactory].
  final EstimateSummaryBloc Function() estimateSummaryBlocFactory;

  /// Backs the equipment form's "Save as my rate" and look-up-a-rate
  /// features. Same not-a-module-file reasoning as
  /// [equipmentCostFormBlocFactory].
  final YourRatesBloc Function() yourRatesBlocFactory;

  /// Backs the equipment form's "Save as my rate" timestamp. Same
  /// not-a-module-file reasoning as [equipmentCostFormBlocFactory].
  final Clock clock;

  const CostEstimationDetailsPage({
    super.key,
    required this.estimationId,
    required this.router,
    required this.equipmentCostFormBlocFactory,
    required this.estimateSummaryBlocFactory,
    required this.yourRatesBlocFactory,
    required this.clock,
  });

  @override
  State<CostEstimationDetailsPage> createState() =>
      _CostEstimationDetailsPageState();
}

class _CostEstimationDetailsPageState extends State<CostEstimationDetailsPage> {
  CostEstimationTab _selectedTab = CostEstimationTab.material;
  late final EstimateSummaryBloc _summaryBloc;
  var _isOpeningSheet = false;

  @override
  void initState() {
    super.initState();
    _summaryBloc = widget.estimateSummaryBlocFactory()
      ..add(EstimateSummaryRequested(widget.estimationId));
  }

  @override
  void dispose() {
    unawaited(_summaryBloc.close());
    super.dispose();
  }

  Future<CostEstimate?> _loadEstimate() async {
    final current = _summaryBloc.state;
    if (current is! EstimateSummaryLoaded &&
        current is! EstimateSummaryLoading) {
      _summaryBloc.add(EstimateSummaryRequested(widget.estimationId));
    }
    final settled = current is EstimateSummaryLoaded
        ? current
        : await _summaryBloc.stream.firstWhere(
            (s) => s is EstimateSummaryLoaded || s is EstimateSummaryFailure,
            orElse: () => _summaryBloc.state,
          );
    return settled is EstimateSummaryLoaded ? settled.estimate : null;
  }

  Future<void> _openEquipmentSheet() async {
    if (_isOpeningSheet) return;
    _isOpeningSheet = true;
    try {
      final l10n = context.l10n;
      final estimate = await _loadEstimate();
      if (!mounted) return;
      if (estimate == null) {
        CoreToast.showError(
          context,
          l10n.estimateSummaryLoadFailedError,
          l10n.closeLabel,
        );
        return;
      }
      final formBloc = widget.equipmentCostFormBlocFactory();
      try {
        await CoreQuickSheet.show<void>(
          context: context,
          backgroundColor: sheetSurface(context),
          child: BlocProvider<EquipmentCostFormBloc>.value(
            value: formBloc,
            child: CostItemFormScreen(
              type: CostItemType.equipment,
              estimationId: widget.estimationId,
              router: widget.router,
              presentAsSheet: true,
              yourRatesBlocFactory: widget.yourRatesBlocFactory,
              clock: widget.clock,
              estimate: estimate,
            ),
          ),
        );
        if (formBloc.state is EquipmentCostFormSubmitting) {
          await formBloc.stream.firstWhere(
            (s) => s is! EquipmentCostFormSubmitting,
            orElse: () => formBloc.state,
          );
        }
      } finally {
        unawaited(formBloc.close());
      }
      if (!mounted) return;
      _summaryBloc.add(EstimateSummaryRequested(widget.estimationId));
      switch (formBloc.state) {
        case EquipmentCostFormSuccess():
          CoreToast.showCustomToast(
            context,
            (_) => AddedToEstimateToast(
              message: l10n.addedToEstimateToast(estimate.estimateName),
            ),
            duration: const Duration(seconds: 4),
          );
        case EquipmentCostFormFailure():
          CoreToast.showError(
            context,
            l10n.addToEstimateFailedError,
            l10n.closeLabel,
          );
        default:
          break;
      }
    } finally {
      _isOpeningSheet = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final colorTheme = context.colorTheme;
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: colorTheme.pageBackground,
      appBar: CoreAppBar(
        height: CoreSpacing.space12,
        padding: const EdgeInsets.only(
          top: CoreSpacing.space2,
          bottom: CoreSpacing.space2,
          right: CoreSpacing.space4,
        ),
        centerTitle: false,
        titleSpacing: CoreSpacing.space1,
        leading: CoreIconWidget(
          key: const Key('back_button'),
          icon: CoreIcons.backspaceLeft,
          color: colorTheme.iconDark,
          padding: EdgeInsets.all(CoreSpacing.space3),
          size: 24,
          semanticLabel: l10n.backLabel,
          onTap: widget.router.pop,
        ),
        // TODO: [CA-154] [Cost Estimation] Implement Rename Estimation Logic https://ripplearc.youtrack.cloud/issue/CA-154/Cost-Estimation-Implement-Rename-Estimation-Logic
        title: Row(
          children: [
            Flexible(
              child: Text(
                'Estimation Details',
                style: textTheme.titleMediumSemiBold.copyWith(
                  color: colorTheme.textHeadline,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            CoreIconWidget(
              key: const Key('edit_estimation_name_icon'),
              icon: CoreIcons.edit,
              padding: EdgeInsets.all(CoreSpacing.space3),
              color: colorTheme.iconDark,
              semanticLabel: l10n.editEstimationNameLabel,
            ),
          ],
        ),
        actions: [
          CoreIconWidget(
            key: const Key('more_options_icon'),
            icon: CoreIcons.moreVert,
            size: 24,
            padding: EdgeInsets.all(CoreSpacing.space3),
            color: colorTheme.iconDark,
            semanticLabel: l10n.moreOptionsLabel,
          ),
        ],
      ),
      body: CostEstimationDetailsTabView(
        onTabChanged: (tab) => setState(() => _selectedTab = tab),
      ),
      floatingActionButton: _buildFab(context, l10n),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: CoreSpacing.space4,
            vertical: CoreSpacing.space2,
          ),
          decoration: BoxDecoration(
            boxShadow: CoreShadows.sticky,
            color: colorTheme.pageBackground,
          ),
          child: Row(
            spacing: CoreSpacing.space4,
            children: [
              // TODO: [CA-160] [Cost Estimation] Implement Lock/Unlock Button Logic
              DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: colorTheme.lineLight),
                ),
                child: CoreIconWidget(
                  key: const Key('lock_icon'),
                  icon: CoreIcons.lock,
                  size: 24,
                  padding: EdgeInsets.all(CoreSpacing.space3),
                  color: colorTheme.iconDark,
                  semanticLabel: l10n.lockLabel,
                ),
              ),
              // TODO: [CA-186] [Cost Estimation] Implement Preview Button Logic https://ripplearc.youtrack.cloud/issue/CA-186/Cost-Estimation-Implement-Preview-Button-Logic
              Expanded(
                child: CoreButton(
                  key: const Key('preview_button'),
                  label: l10n.previewButton,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFab(BuildContext context, AppLocalizations l10n) {
    return switch (_selectedTab) {
      CostEstimationTab.labour => CoreButton(
        key: const Key('add_labour_cost_button'),
        label: l10n.addLabourCostButton,
        variant: CoreButtonVariant.secondary,
        icon: CoreIconWidget(icon: CoreIcons.add),
        size: CoreButtonSize.medium,
        fullWidth: false,
        onPressed: () => widget.router.pushNamed(
          '$fullAddLabourCostRoute/${widget.estimationId}',
        ),
      ),
      CostEstimationTab.equipment => CoreButton(
        key: const Key('add_equipment_cost_button'),
        label: l10n.addEquipmentCostButton,
        variant: CoreButtonVariant.secondary,
        icon: CoreIconWidget(icon: CoreIcons.add),
        size: CoreButtonSize.medium,
        fullWidth: false,
        onPressed: _openEquipmentSheet,
      ),
      CostEstimationTab.material => CoreButton(
        key: const Key('add_material_cost_button'),
        label: l10n.addMaterialCostButton,
        variant: CoreButtonVariant.secondary,
        icon: CoreIconWidget(icon: CoreIcons.add),
        size: CoreButtonSize.medium,
        fullWidth: false,
        onPressed: () => widget.router.pushNamed(
          '$fullAddMaterialCostRoute/${widget.estimationId}',
        ),
      ),
    };
  }
}
