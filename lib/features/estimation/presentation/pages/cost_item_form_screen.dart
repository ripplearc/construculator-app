import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/domain/repositories/your_rates_repository.dart';
import 'package:construculator/features/estimation/presentation/bloc/your_rates_bloc/your_rates_bloc.dart';
import 'package:construculator/features/estimation/presentation/widgets/cost_item_mode_toggle.dart';
import 'package:construculator/features/estimation/presentation/widgets/equipment_cost_form_fields.dart';
import 'package:construculator/features/estimation/presentation/widgets/labour_cost_form_fields.dart';
import 'package:construculator/features/estimation/presentation/widgets/material_cost_form_fields.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:construculator/libraries/router/interfaces/app_router.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

class CostItemFormScreen extends StatefulWidget {
  final CostItemType type;
  final String estimationId;
  final AppRouter router;

  /// Backs the equipment form's "Save as my rate" and look-up-a-rate
  /// features. Only exercised when [type] is equipment, but taken uniformly
  /// across all three item types to match [router]'s existing pattern
  /// rather than special-casing this one type at every call site.
  final YourRatesRepository yourRatesRepository;
  final YourRatesBloc Function() yourRatesBlocFactory;

  /// When true, renders as plain content for a [CoreQuickSheet] (a back
  /// arrow + title header row instead of a [Scaffold]/[CoreAppBar]) rather
  /// than a full-screen route. Equipment only, per the Figma mocks — every
  /// "New equipment cost" screen renders as a bottom sheet over the
  /// estimate details screen. Material and Labor keep the full-screen
  /// [Scaffold] presentation (this defaults to false).
  final bool presentAsSheet;

  const CostItemFormScreen({
    super.key,
    required this.type,
    required this.estimationId,
    required this.router,
    required this.yourRatesRepository,
    required this.yourRatesBlocFactory,
    this.presentAsSheet = false,
  });

  @override
  State<CostItemFormScreen> createState() => _CostItemFormScreenState();
}

class _CostItemFormScreenState extends State<CostItemFormScreen> {
  bool _fromCostFile = false;
  double _total = 0;
  bool _canSave = false;

  @override
  Widget build(BuildContext context) {
    final colorTheme = context.colorTheme;
    if (widget.presentAsSheet) {
      return ColoredBox(
        key: const Key('cost_item_form_screen'),
        color: colorTheme.pageBackground,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSheetHeader(context),
            Flexible(child: _buildBody(context)),
            _buildBottomBar(context),
          ],
        ),
      );
    }
    return Scaffold(
      key: const Key('cost_item_form_screen'),
      backgroundColor: colorTheme.pageBackground,
      appBar: _buildAppBar(context),
      body: _buildBody(context),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  // Header row used in place of a CoreAppBar when presentAsSheet is true,
  // matching the Figma "Sheet Header" spec: a teal back arrow (the drag
  // handle itself comes from CoreQuickSheet, which already wraps this
  // content) + title, SF Pro 590/18px, colorTheme.textHeadline.
  Widget _buildSheetHeader(BuildContext context) {
    final colorTheme = context.colorTheme;
    final textTheme = context.textTheme;
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(
        left: CoreSpacing.space2,
        right: CoreSpacing.space4,
        bottom: CoreSpacing.space2,
      ),
      child: Row(
        children: [
          CoreIconWidget(
            key: const Key('sheet_back_button'),
            icon: CoreIcons.arrowLeft,
            color: colorTheme.textLink,
            padding: const EdgeInsets.all(CoreSpacing.space3),
            size: 24,
            semanticLabel: l10n.backLabel,
            onTap: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Text(
              _screenTitle(context),
              style: textTheme.titleMediumSemiBold.copyWith(
                color: colorTheme.textHeadline,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final colorTheme = context.colorTheme;
    final textTheme = context.textTheme;
    final l10n = context.l10n;
    return CoreAppBar(
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
        icon: CoreIcons.cross,
        color: colorTheme.iconDark,
        padding: EdgeInsets.all(CoreSpacing.space3),
        size: 24,
        semanticLabel: l10n.closeLabel,
        onTap: widget.router.pop,
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              _screenTitle(context),
              style: textTheme.titleMediumSemiBold.copyWith(
                color: colorTheme.textHeadline,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // TODO: [CA-356] [Cost Estimation] Build Edit Cost Item Screen UI https://ripplearc.youtrack.cloud/issue/CA-356/Cost-Estimation-Build-Edit-Cost-Item-Screen-UI
          CoreIconWidget(
            key: const Key('edit_title_button'),
            icon: CoreIcons.edit,
            color: colorTheme.iconDark,
            padding: EdgeInsets.all(CoreSpacing.space2),
            size: 24,
            semanticLabel: l10n.editCostItemNameLabel,
          ),
        ],
      ),
    );
  }

  String _screenTitle(BuildContext context) => switch (widget.type) {
    CostItemType.material => context.l10n.addMaterialCostsScreenTitle,
    CostItemType.labor => context.l10n.addLabourCostsScreenTitle,
    CostItemType.equipment => context.l10n.addEquipmentCostsScreenTitle,
  };

  Widget _buildBody(BuildContext context) {
    final colorTheme = context.colorTheme;
    final textTheme = context.textTheme;
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ColoredBox(
          color: colorTheme.backgroundBlueLight,
          child: Padding(
            padding: const EdgeInsets.all(CoreSpacing.space4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.howToCalculateCostLabel,
                  key: const Key('how_to_calculate_label'),
                  style: textTheme.bodyMediumRegular.copyWith(
                    color: colorTheme.textHeadline,
                  ),
                ),
                const SizedBox(height: CoreSpacing.space2),
                CostItemModeToggle(
                  fromCostFile: _fromCostFile,
                  onFromCostFile: () => setState(() => _fromCostFile = true),
                  onManually: () => setState(() => _fromCostFile = false),
                ),
              ],
            ),
          ),
        ),
        Expanded(child: _buildFormFields()),
      ],
    );
  }

  Widget _buildFormFields() {
    void onTotalChanged(double total) => setState(() => _total = total);
    void onSaveEnabledChanged(bool enabled) =>
        setState(() => _canSave = enabled);
    return switch (widget.type) {
      CostItemType.material => MaterialCostFormFields(
        fromCostFile: _fromCostFile,
        onTotalChanged: onTotalChanged,
        onSaveEnabledChanged: onSaveEnabledChanged,
      ),
      CostItemType.labor => LabourCostFormFields(
        fromCostFile: _fromCostFile,
        onTotalChanged: onTotalChanged,
        onSaveEnabledChanged: onSaveEnabledChanged,
      ),
      CostItemType.equipment => EquipmentCostFormFields(
        fromCostFile: _fromCostFile,
        onTotalChanged: onTotalChanged,
        onSaveEnabledChanged: onSaveEnabledChanged,
        estimateId: widget.estimationId,
        yourRatesRepository: widget.yourRatesRepository,
        yourRatesBlocFactory: widget.yourRatesBlocFactory,
      ),
    };
  }

  Widget _buildBottomBar(BuildContext context) {
    final colorTheme = context.colorTheme;
    final textTheme = context.textTheme;
    final l10n = context.l10n;
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: CoreSpacing.space4,
          vertical: CoreSpacing.space3,
        ),
        decoration: BoxDecoration(
          boxShadow: CoreShadows.sticky,
          color: colorTheme.pageBackground,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: Row(
                key: const Key('cost_item_total_label'),
                mainAxisSize: MainAxisSize.min,
                spacing: CoreSpacing.space1,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    l10n.costItemTotalLabel,
                    style: textTheme.bodyLargeRegular.copyWith(
                      color: colorTheme.textBody,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      '\$${_total.toStringAsFixed(2)}',
                      style: textTheme.titleLargeSemiBold.copyWith(
                        color: colorTheme.textHeadline,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            // TODO: [CA-355] [Cost Estimation] Implement Add To Cost Button Logic https://ripplearc.youtrack.cloud/issue/CA-355/Cost-Estimation-Implement-Add-To-Cost-Button-Logic
            CoreButton(
              key: const Key('add_to_cost_button'),
              label: l10n.addToCostButton,
              isDisabled: !_canSave,
              fullWidth: false,
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}
