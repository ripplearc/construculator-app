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
            icon: CoreIcons.close,
            color: colorTheme.iconDark,
            padding: EdgeInsets.all(CoreSpacing.space4),
            size: 24,
            visualDensity: VisualDensity.compact,
            semanticLabel: l10n.closeLabel,
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
                const SizedBox(height: CoreSpacing.space3),
                _buildModeToggle(context),
              ],
            ),
          ),
        ),
        // TODO: [CA-???] Add form fields for cost item entry
      ],
    );
  }

  Widget _buildModeToggle(BuildContext context) {
    final colorTheme = context.colorTheme;
    final l10n = context.l10n;
    return Container(
      key: const Key('mode_toggle_container'),
      padding: const EdgeInsets.all(CoreSpacing.space1),
      decoration: BoxDecoration(
        color: colorTheme.pageBackground,
        borderRadius: BorderRadius.circular(48),
        boxShadow: [
          BoxShadow(color: colorTheme.shadowGrey10, blurRadius: 8),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _buildPill(
                context,
                key: const Key('from_cost_file_pill'),
                label: l10n.fromCostFileMode,
                semanticLabel: l10n.fromCostFileModeSemanticLabel,
                isActive: _fromCostFile,
                onTap: () => setState(() => _fromCostFile = true),
              ),
            ),
            const SizedBox(width: 2),
            Expanded(
              child: _buildPill(
                context,
                key: const Key('manually_pill'),
                label: l10n.manuallyMode,
                semanticLabel: l10n.manuallyModeSemanticLabel,
                isActive: !_fromCostFile,
                onTap: () => setState(() => _fromCostFile = false),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPill(
    BuildContext context, {
    required Key key,
    required String label,
    required String semanticLabel,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final colorTheme = context.colorTheme;
    final textTheme = context.textTheme;
    return Semantics(
      key: key,
      label: semanticLabel,
      selected: isActive,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(
              vertical: 6,
              horizontal: CoreSpacing.space4,
            ),
            decoration: BoxDecoration(
              color: isActive ? colorTheme.orientMid : colorTheme.transparent,
              borderRadius: BorderRadius.circular(CoreSpacing.space4),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: colorTheme.shadowGrey10,
                        blurRadius: 12,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: colorTheme.iconGrayMid.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Center(
              child: Text(
                label,
                style: isActive
                    ? textTheme.bodyMediumSemiBold.copyWith(
                        color: colorTheme.textHeadline,
                      )
                    : textTheme.bodyMediumRegular.copyWith(
                        color: colorTheme.textBody,
                      ),
              ),
            ),
          ),
        ),
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              key: const Key('cost_item_total_label'),
              spacing: CoreSpacing.space1,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  l10n.costItemTotalLabel,
                  style: textTheme.bodyLargeRegular.copyWith(
                    color: colorTheme.textBody,
                  ),
                ),
                Text(
                  '\$0',
                  style: textTheme.titleLargeSemiBold.copyWith(
                    color: colorTheme.textHeadline,
                  ),
                ),
              ],
            ),
            // TODO: [CA-???] Wire submission logic for cost item
            CoreButton(
              key: const Key('add_to_cost_button'),
              label: l10n.addToCostButton,
              isDisabled: true,
              fullWidth: false,
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}
