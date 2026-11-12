import 'dart:async';

import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/presentation/bloc/added_line_highlight_cubit/added_line_highlight_cubit.dart';
import 'package:construculator/features/estimation/presentation/bloc/cost_items_bloc/cost_items_bloc.dart';
import 'package:construculator/features/estimation/presentation/bloc/equipment_cost_form_bloc/equipment_cost_form_bloc.dart';
import 'package:construculator/features/estimation/presentation/bloc/estimate_summary_bloc/estimate_summary_bloc.dart';
import 'package:construculator/features/estimation/presentation/bloc/material_cost_form_bloc/material_cost_form_bloc.dart';
import 'package:construculator/features/estimation/presentation/bloc/your_rates_bloc/your_rates_bloc.dart';
import 'package:construculator/features/estimation/presentation/pages/cost_item_form_screen.dart';
import 'package:construculator/features/estimation/presentation/widgets/add_cost_bottom_bar.dart';
import 'package:construculator/features/estimation/presentation/widgets/add_cost_category_sheet.dart';
import 'package:construculator/features/estimation/presentation/widgets/added_to_estimate_toast.dart';
import 'package:construculator/features/estimation/presentation/widgets/cost_sections_list.dart';
import 'package:construculator/features/estimation/presentation/widgets/guarded_quick_sheet.dart';
import 'package:construculator/features/estimation/presentation/widgets/sheet_surface.dart';
import 'package:construculator/features/estimation/presentation/widgets/your_rates_recents_sheet.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:construculator/libraries/router/interfaces/app_router.dart';
import 'package:construculator/libraries/router/routes/estimation_routes.dart';
import 'package:construculator/libraries/time/interfaces/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// The cost estimation details page.
///
/// Displays the estimate's cost lines as one list of three sections
/// (Materials, Labor, Equipment) under a custom app bar, with a bottom bar
/// that holds the estimate total, `+ Add cost` and Preview.
class CostEstimationDetailsPage extends StatefulWidget {
  final String estimationId;

  /// Router used for navigation (e.g. popping this page).
  final AppRouter router;

  /// Builds an [EquipmentCostFormBloc] for the equipment cost sheet that
  /// `+ Add cost` opens. Injected rather than resolved with `Modular.get` here, since
  /// this page isn't a module file.
  final EquipmentCostFormBloc Function() equipmentCostFormBlocFactory;

  /// Builds a [MaterialCostFormBloc] for the material cost sheet that
  /// `+ Add cost` opens. Same not-a-module-file reasoning as
  /// [equipmentCostFormBlocFactory].
  final MaterialCostFormBloc Function() materialCostFormBlocFactory;

  /// Builds the [EstimateSummaryBloc] that loads this estimate's name and
  /// total for the cost sheets. Same not-a-module-file reasoning as
  /// [equipmentCostFormBlocFactory].
  final EstimateSummaryBloc Function() estimateSummaryBlocFactory;

  /// Backs the equipment form's "Save as my rate" and look-up-a-rate
  /// features. Same not-a-module-file reasoning as
  /// [equipmentCostFormBlocFactory].
  final YourRatesBloc Function() yourRatesBlocFactory;

  /// Builds the [CostItemsBloc] that loads this estimate's cost lines. Same
  /// not-a-module-file reasoning as [equipmentCostFormBlocFactory].
  final CostItemsBloc Function() costItemsBlocFactory;

  /// Backs the equipment form's "Save as my rate" timestamp and the
  /// "Your recents" sheet's recency subtitles. Same not-a-module-file
  /// reasoning as [equipmentCostFormBlocFactory].
  final Clock clock;

  const CostEstimationDetailsPage({
    super.key,
    required this.estimationId,
    required this.router,
    required this.equipmentCostFormBlocFactory,
    required this.materialCostFormBlocFactory,
    required this.estimateSummaryBlocFactory,
    required this.yourRatesBlocFactory,
    required this.costItemsBlocFactory,
    required this.clock,
  });

  @override
  State<CostEstimationDetailsPage> createState() =>
      _CostEstimationDetailsPageState();
}

enum _SheetOutcome { editing, submitting, added, failed }

class _CostEstimationDetailsPageState extends State<CostEstimationDetailsPage> {
  late final EstimateSummaryBloc _summaryBloc;
  late final CostItemsBloc _costItemsBloc;
  final _addedLineHighlight = AddedLineHighlightCubit();

  @override
  void initState() {
    super.initState();
    _summaryBloc = widget.estimateSummaryBlocFactory()
      ..add(EstimateSummaryRequested(widget.estimationId));
    _costItemsBloc = widget.costItemsBlocFactory()
      ..add(CostItemsRequested(widget.estimationId));
  }

  @override
  void dispose() {
    unawaited(_summaryBloc.close());
    unawaited(_costItemsBloc.close());
    unawaited(_addedLineHighlight.close());
    super.dispose();
  }

  Future<void> _openEquipmentSheet(YourRateEntry? entry, {String? name}) =>
      _openCostSheet<EquipmentCostFormBloc, EquipmentCostFormState>(
        type: CostItemType.equipment,
        asksBeforeClosing: true,
        entry: entry,
        name: name,
        blocFactory: widget.equipmentCostFormBlocFactory,
        addedItemIdOf: (state) =>
            state is EquipmentCostFormSuccess ? state.createdItem.id : null,
        outcomeOf: (state) => switch (state) {
          EquipmentCostFormSubmitting() => _SheetOutcome.submitting,
          EquipmentCostFormSuccess() => _SheetOutcome.added,
          EquipmentCostFormFailure() => _SheetOutcome.failed,
          _ => _SheetOutcome.editing,
        },
      );

  Future<void> _openMaterialSheet() =>
      _openCostSheet<MaterialCostFormBloc, MaterialCostFormState>(
        type: CostItemType.material,
        asksBeforeClosing: true,
        blocFactory: widget.materialCostFormBlocFactory,
        addedItemIdOf: (state) =>
            state is MaterialCostFormSuccess ? state.createdItem.id : null,
        outcomeOf: (state) => switch (state) {
          MaterialCostFormSubmitting() => _SheetOutcome.submitting,
          MaterialCostFormSuccess() => _SheetOutcome.added,
          MaterialCostFormFailure() => _SheetOutcome.failed,
          _ => _SheetOutcome.editing,
        },
      );

  Future<void> _openCostSheet<B extends BlocBase<S>, S>({
    required CostItemType type,
    bool asksBeforeClosing = false,
    required B Function() blocFactory,
    String? Function(S state)? addedItemIdOf,
    required _SheetOutcome Function(S state) outcomeOf,
    YourRateEntry? entry,
    String? name,
  }) async {
    final l10n = context.l10n;
    final formBloc = blocFactory();
    try {
      final sheetBody = MultiBlocProvider(
        providers: [
          BlocProvider<B>.value(value: formBloc),
          BlocProvider<EstimateSummaryBloc>.value(value: _summaryBloc),
        ],
        child: BlocBuilder<EstimateSummaryBloc, EstimateSummaryState>(
          builder: (context, summary) => CostItemFormScreen(
            type: type,
            estimationId: widget.estimationId,
            router: widget.router,
            presentAsSheet: true,
            yourRatesBlocFactory: widget.yourRatesBlocFactory,
            clock: widget.clock,
            estimate: summary is EstimateSummaryLoaded
                ? summary.estimate
                : null,
            initialRateEntry: entry,
            initialEquipmentName: name,
          ),
        ),
      );
      final surface = sheetSurface(context);
      await (asksBeforeClosing
          ? GuardedQuickSheet.show<void>(
              context: context,
              backgroundColor: surface,
              child: sheetBody,
            )
          : CoreQuickSheet.show<void>(
              context: context,
              backgroundColor: surface,
              child: sheetBody,
            ));
      final wasSavingWhenDismissed =
          outcomeOf(formBloc.state) == _SheetOutcome.submitting;
      if (wasSavingWhenDismissed) {
        await formBloc.stream.firstWhere(
          (s) => outcomeOf(s) != _SheetOutcome.submitting,
          orElse: () => formBloc.state,
        );
      }
      if (!mounted) return;
      final summary = _summaryBloc.state;
      _summaryBloc.add(EstimateSummaryRequested(widget.estimationId));
      final outcome = outcomeOf(formBloc.state);
      if (outcome != _SheetOutcome.editing) {
        _costItemsBloc.add(const CostItemsRefreshed());
      }
      switch (outcome) {
        case _SheetOutcome.added:
          final addedItemId = addedItemIdOf?.call(formBloc.state);
          if (addedItemId != null) _addedLineHighlight.highlight(addedItemId);
          if (summary is EstimateSummaryLoaded) {
            CoreToast.showCustomToast(
              context,
              (_) => AddedToEstimateToast(
                message: l10n.addedToEstimateToast(
                  summary.estimate.estimateName,
                ),
              ),
              duration: const Duration(seconds: 4),
            );
          }
        case _SheetOutcome.failed when wasSavingWhenDismissed:
          CoreToast.showError(
            context,
            l10n.addToEstimateFailedError,
            l10n.closeLabel,
          );
        default:
          break;
      }
    } finally {
      unawaited(formBloc.close());
    }
  }

  @override
  Widget build(BuildContext context) =>
      BlocProvider<AddedLineHighlightCubit>.value(
        value: _addedLineHighlight,
        child: Builder(builder: _buildScaffold),
      );

  Widget _buildScaffold(BuildContext context) {
    final textTheme = context.textTheme;
    final colorTheme = context.colorTheme;
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: sheetSurface(context),
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
      body: BlocBuilder<CostItemsBloc, CostItemsState>(
        bloc: _costItemsBloc,
        builder: (context, state) => switch (state) {
          CostItemsLoaded() => BlocBuilder<AddedLineHighlightCubit, String?>(
            builder: (context, highlightedItemId) => CostSectionsList(
              costs: state,
              highlightedItemId: highlightedItemId,
              onLineTap: (_) => _addedLineHighlight.clear(),
              onAddFirstCost: () => unawaited(_openAddCost(context)),
            ),
          ),
          CostItemsFailure() => _buildLoadFailure(context),
          CostItemsInitial() ||
          CostItemsLoading() => const Center(child: CoreLoadingIndicator()),
        },
      ),
      bottomNavigationBar: BlocBuilder<CostItemsBloc, CostItemsState>(
        bloc: _costItemsBloc,
        builder: (context, costs) =>
            BlocBuilder<EstimateSummaryBloc, EstimateSummaryState>(
              bloc: _summaryBloc,
              buildWhen: (_, current) => current is EstimateSummaryLoaded,
              builder: (context, summary) => AddCostBottomBar(
                total: summary is EstimateSummaryLoaded
                    ? summary.estimate.totalCost
                    : null,
                isEstimateEmpty:
                    costs is CostItemsLoaded && costs.items.isEmpty,
                onAddCost: () => unawaited(_openAddCost(context)),
                // TODO: [CA-186] [Cost Estimation] Implement Preview Button Logic https://ripplearc.youtrack.cloud/issue/CA-186/Cost-Estimation-Implement-Preview-Button-Logic
              ),
            ),
      ),
    );
  }

  Widget _buildLoadFailure(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: CoreSpacing.space4,
        children: [
          Text(
            l10n.costItemsLoadFailed,
            key: const Key('cost_items_load_failed'),
            style: context.textTheme.bodyMediumRegular.copyWith(
              color: context.colorTheme.textBody,
            ),
          ),
          CoreButton(
            key: const Key('cost_items_retry_button'),
            label: l10n.costItemsRetryButton,
            variant: CoreButtonVariant.secondary,
            fullWidth: false,
            onPressed: () => _costItemsBloc.add(const CostItemsRefreshed()),
          ),
        ],
      ),
    );
  }

  Future<void> _openAddCost(BuildContext context) async {
    final type = await AddCostCategorySheet.show(context);
    if (type == null || !context.mounted) return;
    switch (type) {
      case CostItemType.material:
        await _openMaterialSheet();
      case CostItemType.labor:
        await widget.router.pushNamed(
          '$fullAddLabourCostRoute/${widget.estimationId}',
        );
        if (!mounted) return;
        _summaryBloc.add(EstimateSummaryRequested(widget.estimationId));
        _costItemsBloc.add(const CostItemsRefreshed());
      case CostItemType.equipment:
        await _openRecentsThenEquipmentForm(context);
    }
  }

  Future<void> _openRecentsThenEquipmentForm(BuildContext context) async {
    final result = await YourRatesRecentsSheet.show(
      context: context,
      clock: widget.clock,
      blocFactory: widget.yourRatesBlocFactory,
    );
    if (!context.mounted) return;
    switch (result) {
      case YourRatesRecentsDismissed():
        return;
      case YourRatesRecentsPicked(:final entry):
        await _openEquipmentSheet(entry);
      case YourRatesRecentsNewEquipmentCost(:final name):
        await _openEquipmentSheet(null, name: name);
    }
  }
}
