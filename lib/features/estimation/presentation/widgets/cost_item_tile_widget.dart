import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:construculator/libraries/formatting/display_formatter.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

class CostItemTileWidget extends StatelessWidget {
  final CostItem item;
  final VoidCallback? onMenuTap;
  final VoidCallback? onExpandTap;

  const CostItemTileWidget({
    super.key,
    required this.item,
    this.onMenuTap,
    this.onExpandTap,
  });

  @override
  Widget build(BuildContext context) {
    final appColors = context.colorTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: CoreSpacing.space4,
        vertical: CoreSpacing.space4,
      ),
      decoration: BoxDecoration(
        boxShadow: CoreShadows.small,
        borderRadius: BorderRadius.circular(4),
        color: appColors.pageBackground,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(context),
          const SizedBox(height: CoreSpacing.space2),
          _buildMetadata(context),
          const SizedBox(height: CoreSpacing.space2),
          Container(height: 1, color: appColors.lineLight),
          const SizedBox(height: CoreSpacing.space2),
          _buildTotalRow(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final appColors = context.colorTheme;
    final typography = context.textTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          child: Text(
            item.itemName,
            key: const Key('costItemTileName'),
            style: typography.bodyMediumSemiBold.copyWith(
              color: appColors.textDark,
            ),
          ),
        ),
        Semantics(
          button: true,
          label: context.l10n.costItemTileMenuSemanticLabel(item.itemName),
          excludeSemantics: true,
          child: GestureDetector(
            key: const Key('costItemTileMenuButton'),
            onTap: onMenuTap,
            child: CoreIconWidget(
              icon: CoreIcons.moreVert,
              color: appColors.iconGrayMid,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetadata(BuildContext context) {
    return switch (item) {
      final MaterialCostItem material => _buildMaterialMetadata(context, material),
      final EquipmentCostItem equipment => _buildEquipmentMetadata(context, equipment),
      final LaborCostItem labor => _buildLaborMetadata(context, labor),
    };
  }

  Widget _buildMaterialMetadata(BuildContext context, MaterialCostItem material) {
    return _buildUnitPricedItemMetadata(context, material.quantity, material.unitPrice);
  }

  Widget _buildEquipmentMetadata(BuildContext context, EquipmentCostItem equipment) {
    return _buildUnitPricedItemMetadata(context, equipment.quantity, equipment.unitPrice);
  }

  Widget _buildUnitPricedItemMetadata(BuildContext context, Quantity quantity, Money unitPrice) {
    return _buildMetaRow(context, [
      (context.l10n.costItemTileQuantityLabel, _formatQuantity(quantity.value)),
      // TODO(CA-XXX): unit.name produces unreadable compound names (e.g. SQUAREMETERS).
      // Replace with UomFormatter once available.
      (context.l10n.costItemTileUomLabel, quantity.unit.name.toUpperCase()),
      (context.l10n.costItemTileUnitPriceLabel, DisplayFormatter.formatCurrency(unitPrice.amount)),
    ]);
  }

  Widget _buildLaborMetadata(BuildContext context, LaborCostItem labor) {
    final chips = <(String, String)>[
      (context.l10n.costItemTileLaborMethodLabel, _formatLaborMethod(context, labor.laborCalcMethod)),
    ];

    switch (labor.laborCalcMethod) {
      case LaborCalculationMethodType.perHour:
        final hours = labor.laborValue.laborHours;
        if (hours != null) {
          chips.add((context.l10n.costItemTileLaborHoursLabel, _formatQuantity(hours)));
        }
      case LaborCalculationMethodType.perDay:
        final days = labor.laborValue.laborDays;
        if (days != null) {
          chips.add((context.l10n.costItemTileLaborDaysLabel, _formatQuantity(days)));
        }
      case LaborCalculationMethodType.perUnit:
        final unitValue = labor.laborValue.laborUnitValue;
        if (unitValue != null) {
          chips.add((context.l10n.costItemTileLaborUnitRateLabel, DisplayFormatter.formatCurrency(unitValue)));
        }
    }

    final crewSize = labor.crewSize;
    if (crewSize != null) {
      chips.add((context.l10n.costItemTileLaborCrewSizeLabel, crewSize.toString()));
    }

    return _buildMetaRow(context, chips);
  }

  Widget _buildMetaRow(BuildContext context, List<(String, String)> chips) {
    final appColors = context.colorTheme;
    final items = <Widget>[];

    for (var i = 0; i < chips.length; i++) {
      final (label, value) = chips[i];
      items.add(_buildMetaChip(context, label, value));
      if (i < chips.length - 1) {
        items.add(
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: appColors.iconGrayLight,
              shape: BoxShape.circle,
            ),
          ),
        );
      }
    }

    return Wrap(
      key: const Key('costItemTileMetadata'),
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: CoreSpacing.space2,
      runSpacing: CoreSpacing.space1,
      children: items,
    );
  }

  Widget _buildMetaChip(BuildContext context, String label, String value) {
    final appColors = context.colorTheme;
    final typography = context.textTheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: typography.bodySmallRegular.copyWith(color: appColors.textBody),
        ),
        Text(
          value,
          style: typography.bodySmallMedium.copyWith(color: appColors.textDark),
        ),
      ],
    );
  }

  Widget _buildTotalRow(BuildContext context) {
    final appColors = context.colorTheme;
    final typography = context.textTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${context.l10n.costItemTileTotalLabel}: ',
              style: typography.bodySmallRegular.copyWith(color: appColors.textBody),
            ),
            Text(
              DisplayFormatter.formatCurrency(item.itemTotalCost),
              key: const Key('costItemTileTotal'),
              style: typography.bodyMediumSemiBold.copyWith(color: appColors.textDark),
            ),
          ],
        ),
        Semantics(
          button: true,
          label: context.l10n.costItemTileExpandSemanticLabel(item.itemName),
          excludeSemantics: true,
          child: GestureDetector(
            key: const Key('costItemTileExpandButton'),
            onTap: onExpandTap,
            child: CoreIconWidget(
              icon: CoreIcons.arrowDropDown,
              color: appColors.iconGrayMid,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  String _formatQuantity(double value) {
    return value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(2);
  }

  String _formatLaborMethod(BuildContext context, LaborCalculationMethodType method) {
    return switch (method) {
      LaborCalculationMethodType.perHour => context.l10n.costItemTileLaborMethodPerHour,
      LaborCalculationMethodType.perDay => context.l10n.costItemTileLaborMethodPerDay,
      LaborCalculationMethodType.perUnit => context.l10n.costItemTileLaborMethodPerUnit,
    };
  }
}
