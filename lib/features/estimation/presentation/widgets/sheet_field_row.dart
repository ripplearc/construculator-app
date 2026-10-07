import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// One labelled row of a cost sheet: the label above, the value below, and a
/// full-width divider under the row, as in the Figma "New material cost"
/// sheet.
///
/// A tap anywhere on the row calls [onTap], so a text field in the row has a
/// tap target as tall as the row rather than as tall as its text.
class SheetFieldRow extends StatelessWidget {
  /// The label shown above the value.
  final String label;

  /// The value area: a text field, a unit pill, or read-only text.
  final Widget child;

  /// The space between the label and the value.
  final double valueGap;

  /// The space between the value and the divider.
  final double bottomPadding;

  /// Called when the row is tapped outside any button inside it.
  final VoidCallback? onTap;

  const SheetFieldRow({
    super.key,
    required this.label,
    required this.child,
    this.valueGap = CoreSpacing.space1,
    this.bottomPadding = CoreSpacing.space3,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorTheme = context.colorTheme;
    final textTheme = context.textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              CoreSpacing.space4,
              CoreSpacing.space3,
              CoreSpacing.space4,
              bottomPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: valueGap,
              children: [
                Text(
                  label,
                  style: textTheme.bodyMediumRegular.copyWith(
                    color: colorTheme.textBody,
                  ),
                ),
                child,
              ],
            ),
          ),
        ),
        const CoreDivider(),
      ],
    );
  }
}
