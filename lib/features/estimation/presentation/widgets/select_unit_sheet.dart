import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/domain/entities/material_unit_list.dart';
import 'package:construculator/features/estimation/presentation/helpers/unit_display_name.dart';
import 'package:construculator/features/estimation/presentation/widgets/sheet_header.dart';
import 'package:construculator/features/estimation/presentation/widgets/unit_radio_row.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// The Select unit sheet: a fixed list of units under group headings, one
/// radio row per unit. It closes with the unit tapped.
///
/// It opens scrolled so the [selected] unit sits mid-sheet, because the full
/// list is taller than the screen.
class SelectUnitSheet extends StatefulWidget {
  /// The groups to list, top to bottom.
  final List<UnitListGroup> groups;

  /// The unit shown as selected, or null when none is.
  final Unit? selected;

  const SelectUnitSheet({
    super.key,
    required this.groups,
    required this.selected,
  });

  @override
  State<SelectUnitSheet> createState() => _SelectUnitSheetState();
}

class _SelectUnitSheetState extends State<SelectUnitSheet> {
  final _selectedRowKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final selectedRow = _selectedRowKey.currentContext;
      if (selectedRow == null) return;
      Scrollable.ensureVisible(selectedRow, alignment: 0.5);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetHeader(title: l10n.selectUnitTitle),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (index, group) in widget.groups.indexed) ...[
                    _GroupHeading(
                      group.group.heading(l10n),
                      isFirst: index == 0,
                    ),
                    for (final unit in group.units)
                      UnitRadioRow(
                        key: unit == widget.selected ? _selectedRowKey : null,
                        unit: unit,
                        isSelected: unit == widget.selected,
                        onSelected: () => Navigator.of(context).pop(unit),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupHeading extends StatelessWidget {
  static const double _letterSpacingEm = 0.07;

  final String text;
  final bool isFirst;

  const _GroupHeading(this.text, {required this.isFirst});

  @override
  Widget build(BuildContext context) {
    final style = context.textTheme.bodySmallSemiBold;
    return Semantics(
      header: true,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          CoreSpacing.space5,
          isFirst ? CoreSpacing.space1 : CoreSpacing.space4,
          CoreSpacing.space5,
          CoreSpacing.space1,
        ),
        child: Text(
          text.toUpperCase(),
          style: style.copyWith(
            color: context.colorTheme.textBody,
            letterSpacing: (style.fontSize ?? 0) * _letterSpacingEm,
          ),
        ),
      ),
    );
  }
}
