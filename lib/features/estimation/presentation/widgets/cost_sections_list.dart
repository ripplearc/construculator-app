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
/// An empty section is never hidden or moved. It shows a placeholder, or
/// examples while the whole estimate is empty, with a centred message and a
/// button that adds the first cost. Headers scroll with the list and are never
/// pinned.
/// When [highlightedItemId] names a line, the list scrolls it into view once.
///
/// Every line is built at once, because scrolling to a line needs it built.
/// That suits an estimate of a few hundred lines.
class CostSectionsList extends StatefulWidget {
  /// Key of the title of the message shown while the whole estimate is empty.
  static const emptyEstimateTitleKey = Key('empty_estimate_title');

  /// Key of the text under that title.
  static const emptyEstimateBodyKey = Key('empty_estimate_body');

  /// Key of the button that adds the first cost.
  static const addFirstCostButtonKey = Key('add_first_cost_button');

  /// Key of the placeholder of the section holding [type] while it has no lines.
  static Key emptySectionKey(CostItemType type) =>
      Key('cost_section_empty_${type.name}');

  /// Key of the examples of the section holding [type].
  static Key examplesKey(CostItemType type) =>
      Key('cost_section_examples_${type.name}');

  /// The loaded lines and the subtotals the bloc worked out.
  final CostItemsLoaded costs;

  /// The id of the line just added, or null when none is marked.
  final String? highlightedItemId;

  /// Called when the user taps a line.
  final ValueChanged<CostItem> onLineTap;

  /// Called when the user taps the button that adds the first cost.
  final VoidCallback onAddFirstCost;

  const CostSectionsList({
    super.key,
    required this.costs,
    required this.highlightedItemId,
    required this.onLineTap,
    required this.onAddFirstCost,
  });

  @override
  State<CostSectionsList> createState() => _CostSectionsListState();
}

class _CostSectionsListState extends State<CostSectionsList> {
  static const _scrollDuration = Duration(milliseconds: 200);

  final _lineKeys = <String, GlobalKey>{};
  String? _scrolledToItemId;

  @override
  void initState() {
    super.initState();
    _scheduleScrollToHighlighted();
  }

  @override
  void didUpdateWidget(CostSectionsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scheduleScrollToHighlighted();
  }

  void _scheduleScrollToHighlighted() {
    final id = widget.highlightedItemId;
    if (id == null) {
      _scrolledToItemId = null;
      return;
    }
    if (id == _scrolledToItemId) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final lineContext = _lineKeys[id]?.currentContext;
      if (!mounted || lineContext == null) return;
      _scrolledToItemId = id;
      Scrollable.ensureVisible(lineContext, duration: _scrollDuration);
    });
  }

  @override
  Widget build(BuildContext context) {
    final costs = widget.costs;
    final isEmpty = costs.items.isEmpty;
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
                isEmpty,
              ),
              _section(
                context,
                CostItemType.labor,
                costs.laborLines,
                costs.laborSubtotal,
                isEmpty,
              ),
              _section(
                context,
                CostItemType.equipment,
                costs.equipmentLines,
                costs.equipmentSubtotal,
                isEmpty,
              ),
            ],
          ),
        ),
        if (isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: _addFirstCost(context)),
          ),
      ],
    );
  }

  Widget _section(
    BuildContext context,
    CostItemType type,
    List<CostItem> lines,
    double subtotal,
    bool isEstimateEmpty,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      CostSectionHeader(type: type, subtotal: subtotal),
      if (isEstimateEmpty)
        _examples(context, type)
      else if (lines.isEmpty)
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
                KeyedSubtree(
                  key: _lineKeys.putIfAbsent(line.id, GlobalKey.new),
                  child: CostLineRow(
                    item: line,
                    isHighlighted: line.id == widget.highlightedItemId,
                    onTap: () => widget.onLineTap(line),
                  ),
                ),
            ],
          ),
        ),
    ],
  );

  Widget _examples(BuildContext context, CostItemType type) {
    final l10n = context.l10n;
    final text = switch (type) {
      CostItemType.material => l10n.costSectionExamplesMaterial,
      CostItemType.labor => l10n.costSectionExamplesLabor,
      CostItemType.equipment => l10n.costSectionExamplesEquipment,
    };
    return _sectionNote(context, text, CostSectionsList.examplesKey(type));
  }

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

  Widget _addFirstCost(BuildContext context) {
    final l10n = context.l10n;
    final colorTheme = context.colorTheme;
    final textTheme = context.textTheme;
    return Padding(
      padding: const EdgeInsets.all(CoreSpacing.space4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.emptyEstimateTitle,
            key: CostSectionsList.emptyEstimateTitleKey,
            textAlign: TextAlign.center,
            style: textTheme.titleMediumSemiBold.copyWith(
              color: colorTheme.textHeadline,
            ),
          ),
          const SizedBox(height: CoreSpacing.space2),
          Text(
            l10n.emptyEstimateBody,
            key: CostSectionsList.emptyEstimateBodyKey,
            textAlign: TextAlign.center,
            style: textTheme.bodyMediumRegular.copyWith(
              color: colorTheme.textBody,
            ),
          ),
          const SizedBox(height: CoreSpacing.space4),
          CoreButton(
            key: CostSectionsList.addFirstCostButtonKey,
            label: l10n.addFirstCostButton,
            icon: CoreIconWidget(
              icon: CoreIcons.add,
              color: colorTheme.textInverse,
            ),
            onPressed: widget.onAddFirstCost,
          ),
        ],
      ),
    );
  }
}
