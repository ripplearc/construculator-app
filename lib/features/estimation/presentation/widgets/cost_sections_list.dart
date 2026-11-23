import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/presentation/bloc/cost_items_bloc/cost_items_bloc.dart';
import 'package:construculator/features/estimation/presentation/widgets/cost_line_row.dart';
import 'package:construculator/features/estimation/presentation/widgets/cost_section_header.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// The estimate's cost lines as one continuous list of three sections:
/// Materials, Labor and Equipment, always in that order.
///
/// An empty section is never hidden or moved. It shows a placeholder.
/// Headers scroll with the list and are never pinned.
/// The line named by [highlightedItemId] is drawn as the one just added.
class CostSectionsList extends StatelessWidget {
  /// Key of the placeholder of the section holding [type] while it has no lines.
  static Key emptySectionKey(CostItemType type) =>
      Key('cost_section_empty_${type.name}');

  /// The loaded lines and the subtotals the bloc worked out.
  final CostItemsLoaded costs;

  /// The id of the line just added, or null when none is marked.
  final String? highlightedItemId;

  /// Called when the user taps a line.
  final ValueChanged<CostItem> onLineTap;

  const CostSectionsList({
    super.key,
    required this.costs,
    required this.highlightedItemId,
    required this.onLineTap,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      key: const Key('cost_sections_list'),
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              _section(
                context,
                CostItemType.material,
                costs.materialLines,
                costs.materialsSubtotal,
              ),
              _section(
                context,
                CostItemType.labor,
                costs.laborLines,
                costs.laborSubtotal,
              ),
              _section(
                context,
                CostItemType.equipment,
                costs.equipmentLines,
                costs.equipmentSubtotal,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _section(
    BuildContext context,
    CostItemType type,
    List<CostItem> lines,
    double subtotal,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      CostSectionHeader(type: type, subtotal: subtotal),
      if (lines.isEmpty)
        _emptySection(context, type)
      else
        Padding(
          padding: const EdgeInsets.fromLTRB(
            CoreSpacing.space4,
            CoreSpacing.space3,
            CoreSpacing.space4,
            CoreSpacing.space7,
          ),
          child: Column(
            spacing: CoreSpacing.space3,
            children: [
              for (final line in lines)
                CostLineRow(
                  item: line,
                  isHighlighted: line.id == highlightedItemId,
                  onTap: () => onLineTap(line),
                ),
            ],
          ),
        ),
    ],
  );

  Widget _emptySection(BuildContext context, CostItemType type) {
    final l10n = context.l10n;
    final text = switch (type) {
      CostItemType.material => l10n.costSectionEmptyMaterial,
      CostItemType.labor => l10n.costSectionEmptyLabor,
      CostItemType.equipment => l10n.costSectionEmptyEquipment,
    };
    return _sectionNote(context, text, CostSectionsList.emptySectionKey(type));
  }

  Widget _sectionNote(BuildContext context, String text, Key key) => Container(
    constraints: const BoxConstraints(minHeight: CoreSpacing.space14),
    alignment: Alignment.centerLeft,
    padding: const EdgeInsets.symmetric(horizontal: CoreSpacing.space4),
    child: Text(
      text,
      key: key,
      style: context.textTheme.bodyMediumRegular.copyWith(
        color: context.colorTheme.textBody,
      ),
    ),
  );
}
