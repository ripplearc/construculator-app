import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/presentation/widgets/sheet_surface.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// The list a user picks a cost category from, opened by `+ Add cost`.
///
/// It has three rows, Material, Labor and Equipment, each with an icon, a
/// short description and a chevron, and none selected when it opens. Tapping
/// outside the list or swiping down closes it with no prompt, because nothing
/// has been entered yet.
class AddCostCategorySheet extends StatelessWidget {
  /// Key of the row for [type], so tests and screen readers can find it.
  static Key rowKey(CostItemType type) => Key('add_cost_category_${type.name}');

  static const double _rowHorizontalPadding = 20;
  static const double _rowVerticalPadding = 15;
  static const double _iconTileSize = 38;
  static const double _iconTileRadius = 11;
  static const double _bottomPadding = 28;

  const AddCostCategorySheet({super.key});

  /// Shows the list and returns the category the user picked, or null when
  /// the list is dismissed.
  static Future<CostItemType?> show(BuildContext context) =>
      CoreQuickSheet.show<CostItemType>(
        context: context,
        backgroundColor: sheetSurface(context),
        useSafeArea: true,
        child: const AddCostCategorySheet(),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = context.textTheme;
    final colorTheme = context.colorTheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: _bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              _rowHorizontalPadding,
              CoreSpacing.space2,
              _rowHorizontalPadding,
              CoreSpacing.space3,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: CoreSpacing.space1,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    l10n.addCostSheetTitle,
                    style: textTheme.titleMediumSemiBold.copyWith(
                      color: colorTheme.textHeadline,
                    ),
                  ),
                ),
                Text(
                  l10n.addCostSheetSubtitle,
                  style: textTheme.bodySmallRegular.copyWith(
                    color: colorTheme.textBody,
                  ),
                ),
              ],
            ),
          ),
          _row(
            context,
            CostItemType.material,
            _materialIcon,
            l10n.addCostCategoryMaterialTitle,
            l10n.addCostCategoryMaterialSubtitle,
          ),
          _row(
            context,
            CostItemType.labor,
            _laborIcon,
            l10n.addCostCategoryLaborTitle,
            l10n.addCostCategoryLaborSubtitle,
          ),
          _row(
            context,
            CostItemType.equipment,
            _equipmentIcon,
            l10n.addCostCategoryEquipmentTitle,
            l10n.addCostCategoryEquipmentSubtitle,
          ),
        ],
      ),
    );
  }

  // TODO: [CA-1439] Take the Material, Labor and Equipment icons from CoreUI once it has them https://ripplearc.youtrack.cloud/issue/CA-1439
  static const _materialIcon = CoreIconData.svg(
    'assets/icons/cost_category_material.svg',
  );
  static const _laborIcon = CoreIconData.svg(
    'assets/icons/cost_category_labor.svg',
  );
  static const _equipmentIcon = CoreIconData.svg(
    'assets/icons/cost_category_equipment.svg',
  );

  Widget _row(
    BuildContext context,
    CostItemType type,
    CoreIconData icon,
    String title,
    String subtitle,
  ) {
    final colorTheme = context.colorTheme;
    final textTheme = context.textTheme;
    return Semantics(
      button: true,
      excludeSemantics: true,
      label: '$title. $subtitle',
      onTap: () => Navigator.of(context).pop(type),
      child: InkWell(
        key: rowKey(type),
        onTap: () => Navigator.of(context).pop(type),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: _rowHorizontalPadding,
            vertical: _rowVerticalPadding,
          ),
          child: Row(
            spacing: CoreSpacing.space3,
            children: [
              Container(
                width: _iconTileSize,
                height: _iconTileSize,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colorTheme.backgroundGrayLight,
                  borderRadius: BorderRadius.circular(_iconTileRadius),
                ),
                child: CoreIconWidget(
                  icon: icon,
                  size: CoreIconSize.size20,
                  color: colorTheme.iconOrient,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: CoreSpacing.space1,
                  children: [
                    Text(
                      title,
                      style: textTheme.bodyLargeRegular.copyWith(
                        color: colorTheme.textHeadline,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: textTheme.bodySmallRegular.copyWith(
                        color: colorTheme.textBody,
                      ),
                    ),
                  ],
                ),
              ),
              CoreIconWidget(
                icon: CoreIcons.arrowRight,
                size: CoreIconSize.size20,
                color: colorTheme.iconGrayMid,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
