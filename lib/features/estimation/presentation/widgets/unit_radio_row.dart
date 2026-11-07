import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/presentation/helpers/unit_display_name.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// One radio row of the Select unit sheet: a radio, the unit's symbol, and
/// its name at the far end.
///
/// coreui has no radio row, so the row draws the library's list-control
/// looks itself: a Grey Mid fill while pressed and a 2 dp `outlineFocus` ring
/// while it has keyboard focus. Tab reaches it, and Enter or Space selects it.
class UnitRadioRow extends StatelessWidget {
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
  Widget build(BuildContext context) {
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
      button: true,
      inMutuallyExclusiveGroup: true,
      checked: isSelected,
      label: '$symbol, $name',
      // The label already reads the symbol and the name, so the texts inside
      // would be read a second time.
      excludeSemantics: true,
      onTap: onSelected,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onSelected,
          splashFactory: NoSplash.splashFactory,
          highlightColor: colorTheme.backgroundGrayMid,
          focusColor: colorTheme.transparent,
          hoverColor: colorTheme.transparent,
          child: Builder(
            builder: (context) => DecoratedBox(
              key: Key('unit_focus_ring_${unit.name}'),
              position: DecorationPosition.foreground,
              decoration: BoxDecoration(
                border: Focus.of(context).hasFocus ? focusRing : null,
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
