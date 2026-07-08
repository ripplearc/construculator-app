import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:construculator/libraries/router/interfaces/app_router.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

class CostItemFormScreen extends StatefulWidget {
  final CostItemType type;
  final String estimationId;
  final AppRouter router;

  const CostItemFormScreen({
    super.key,
    required this.type,
    required this.estimationId,
    required this.router,
  });

  @override
  State<CostItemFormScreen> createState() => _CostItemFormScreenState();
}

class _CostItemFormScreenState extends State<CostItemFormScreen> {
  bool _fromCostFile = false;

  @override
  Widget build(BuildContext context) {
    final colorTheme = context.colorTheme;
    return Scaffold(
      key: const Key('cost_item_form_screen'),
      backgroundColor: colorTheme.pageBackground,
      appBar: _buildAppBar(context),
      body: _buildBody(context),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final colorTheme = context.colorTheme;
    final textTheme = context.textTheme;
    final l10n = context.l10n;
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight + 5),
      child: Container(
        decoration: BoxDecoration(
          boxShadow: CoreShadows.medium,
          color: colorTheme.pageBackground,
        ),
        child: AppBar(
          backgroundColor: colorTheme.pageBackground,
          elevation: 0,
          centerTitle: false,
          titleSpacing: CoreSpacing.space1,
          leading: CoreIconWidget(
            key: const Key('back_button'),
            icon: CoreIcons.backspaceLeft,
            color: colorTheme.iconDark,
            padding: EdgeInsets.all(CoreSpacing.space4),
            size: 24,
            visualDensity: VisualDensity.compact,
            semanticLabel: l10n.backLabel,
            onTap: widget.router.pop,
          ),
          title: Text(
            _screenTitle(l10n),
            style: textTheme.titleMediumSemiBold.copyWith(
              color: colorTheme.textHeadline,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  String _screenTitle(dynamic l10n) => switch (widget.type) {
    CostItemType.material => l10n.addMaterialCostsScreenTitle,
    CostItemType.labor => l10n.addLabourCostsScreenTitle,
    CostItemType.equipment => l10n.addEquipmentCostsScreenTitle,
  };

  Widget _buildBody(BuildContext context) {
    final colorTheme = context.colorTheme;
    final l10n = context.l10n;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        CoreSpacing.space4,
        CoreSpacing.space6,
        CoreSpacing.space4,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CostCalculationModeToggle(
            fromCostFile: _fromCostFile,
            onChanged: (value) => setState(() => _fromCostFile = value),
          ),
          const SizedBox(height: CoreSpacing.space6),
          // TODO: [CA-???] Add form fields for cost item entry
          Center(
            child: CoreIconWidget(
              key: const Key('cost_item_form_placeholder'),
              icon: CoreIcons.emptyEstimation,
              size: 200,
              color: colorTheme.iconDark,
            ),
          ),
          const SizedBox(height: CoreSpacing.space20),
        ],
      ),
    );
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
          spacing: CoreSpacing.space4,
          children: [
            Text(
              '${l10n.costItemTotalLabel} \$0',
              key: const Key('cost_item_total_label'),
              style: textTheme.titleMediumSemiBold.copyWith(
                color: colorTheme.textHeadline,
              ),
            ),
            Expanded(
              // TODO: [CA-???] Wire submission logic for cost item
              child: CoreButton(
                key: const Key('add_to_cost_button'),
                label: l10n.addToCostButton,
                isDisabled: true,
                onPressed: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CostCalculationModeToggle extends StatelessWidget {
  final bool fromCostFile;
  final ValueChanged<bool> onChanged;

  const _CostCalculationModeToggle({
    required this.fromCostFile,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorTheme = context.colorTheme;
    final textTheme = context.textTheme;
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.howToCalculateCostLabel,
          key: const Key('how_to_calculate_label'),
          style: textTheme.bodyMediumRegular.copyWith(
            color: colorTheme.textHeadline,
          ),
        ),
        const SizedBox(height: CoreSpacing.space3),
        Container(
          key: const Key('mode_toggle_container'),
          padding: const EdgeInsets.all(CoreSpacing.space1),
          decoration: BoxDecoration(
            color: colorTheme.pageBackground,
            borderRadius: BorderRadius.circular(48),
            boxShadow: CoreShadows.medium,
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _TogglePill(
                    key: const Key('from_cost_file_pill'),
                    label: l10n.fromCostFileMode,
                    semanticLabel: l10n.fromCostFileModeSemanticLabel,
                    isActive: fromCostFile,
                    onTap: () => onChanged(true),
                  ),
                ),
                Expanded(
                  child: _TogglePill(
                    key: const Key('manually_pill'),
                    label: l10n.manuallyMode,
                    semanticLabel: l10n.manuallyModeSemanticLabel,
                    isActive: !fromCostFile,
                    onTap: () => onChanged(false),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TogglePill extends StatelessWidget {
  final String label;
  final String semanticLabel;
  final bool isActive;
  final VoidCallback onTap;

  const _TogglePill({
    super.key,
    required this.label,
    required this.semanticLabel,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorTheme = context.colorTheme;
    final textTheme = context.textTheme;
    return Semantics(
      label: semanticLabel,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(
              vertical: CoreSpacing.space2,
              horizontal: CoreSpacing.space4,
            ),
            decoration: BoxDecoration(
              color: isActive ? colorTheme.orientMid : colorTheme.transparent,
              borderRadius: BorderRadius.circular(44),
              boxShadow: isActive ? CoreShadows.medium : null,
            ),
            child: Center(
              child: Text(
                label,
                style: textTheme.bodyMediumRegular.copyWith(
                  color: isActive
                      ? colorTheme.pageBackground
                      : colorTheme.textBody,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
