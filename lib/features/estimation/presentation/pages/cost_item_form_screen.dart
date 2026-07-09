import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/presentation/widgets/cost_item_mode_toggle.dart';
import 'package:construculator/features/estimation/presentation/widgets/material_cost_form_fields.dart';
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
            icon: CoreIcons.cross,
            color: colorTheme.iconDark,
            padding: EdgeInsets.all(CoreSpacing.space4),
            size: 24,
            visualDensity: VisualDensity.compact,
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
              CoreIconWidget(
                key: const Key('edit_title_button'),
                icon: CoreIcons.edit,
                color: colorTheme.iconDark,
                padding: EdgeInsets.all(CoreSpacing.space2),
                size: 24,
                semanticLabel: l10n.editEstimationNameLabel,
              ),
            ],
          ),
        ),
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
    return switch (widget.type) {
      CostItemType.material => MaterialCostFormFields(fromCostFile: _fromCostFile),
      // TODO: [CA-306] Add labour cost form fields
      CostItemType.labor => const SizedBox.shrink(),
      // TODO: [CA-306] Add equipment cost form fields
      CostItemType.equipment => const SizedBox.shrink(),
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
            // TODO: [CA-355] Wire submission logic for cost item
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
