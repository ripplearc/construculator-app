import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/presentation/helpers/unit_display_name.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

// TODO: [CA-1508] Move this row to coreui as the library's Option row. https://ripplearc.youtrack.cloud/issue/CA-1508
/// One radio row of the Select unit sheet: a radio, the unit's symbol, and
/// its name at the far end.
///
/// coreui has no radio row, so the row draws the library's list-control
/// looks itself: a Grey Mid fill while pressed and a 2 dp `outlineFocus` ring
/// while it has keyboard focus. Tab reaches it, and Enter or Space selects it.
class UnitRadioRow extends StatefulWidget {
  /// The unit the row shows.
  final Unit unit;

  /// Whether the row's radio is on.
  final bool isSelected;

  /// Called when the row is tapped or activated from the keyboard.
  final VoidCallback onSelected;

  const UnitRadioRow({
    super.key,
    required this.unit,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  State<UnitRadioRow> createState() => _UnitRadioRowState();
}

class _UnitRadioRowState extends State<UnitRadioRow> {
  bool _showsFocusRing = false;

  @override
  Widget build(BuildContext context) {
    final unit = widget.unit;
    final isSelected = widget.isSelected;
    final l10n = context.l10n;
    final colorTheme = context.colorTheme;
    final textTheme = context.textTheme;
    final symbol = unit.symbol(l10n);
    final name = unit.displayName(l10n);
    final icon = isSelected ? CoreIcons.radioChecked : CoreIcons.radio;
    final accent = isSelected ? colorTheme.textLink : null;
    final symbolStyle = isSelected
        ? textTheme.bodyLargeSemiBold
        : textTheme.bodyLargeRegular;
    final focusRing = Border.all(color: colorTheme.outlineFocus, width: 2);
    return Semantics(
      key: Key('unit_option_${unit.name}'),
      enabled: true,
      focusable: true,
      inMutuallyExclusiveGroup: true,
      checked: isSelected,
      label: '$symbol, $name',
      // The label already reads the symbol and the name, so the texts inside
      // would be read a second time.
      excludeSemantics: true,
      onTap: widget.onSelected,
      child: FocusableActionDetector(
        onShowFocusHighlight: (showsFocusRing) =>
            setState(() => _showsFocusRing = showsFocusRing),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onSelected();
              return null;
            },
          ),
        },
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: widget.onSelected,
            canRequestFocus: false,
            splashFactory: NoSplash.splashFactory,
            highlightColor: colorTheme.backgroundGrayMid,
            hoverColor: colorTheme.transparent,
            child: DecoratedBox(
              key: Key('unit_focus_ring_${unit.name}'),
              position: DecorationPosition.foreground,
              decoration: BoxDecoration(
                border: _showsFocusRing ? focusRing : null,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: CoreSpacing.space5,
                  vertical: CoreSpacing.space4,
                ),
                child: Row(
                  spacing: CoreSpacing.space3,
                  children: [
                    CoreIconWidget(
                      icon: icon,
                      size: CoreIconSize.size24,
                      color: accent ?? colorTheme.lineMid,
                    ),
                    Text(
                      symbol,
                      style: symbolStyle.copyWith(
                        color: accent ?? colorTheme.textHeadline,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        name,
                        textAlign: TextAlign.end,
                        style: textTheme.bodyMediumRegular.copyWith(
                          color: colorTheme.textBody,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
