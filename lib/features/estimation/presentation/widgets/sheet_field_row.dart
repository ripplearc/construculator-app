import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// One labelled row of a cost sheet: the label above, the value below, and a
/// divider under the row, inset from both screen edges as in the storyboard's
/// "New material" frame.
///
/// A tap anywhere on the row calls [onTap], so a text field in the row has a
/// tap target as tall as the row rather than as tall as its text.
///
/// The label is drawn but not announced: [child] carries the spoken label, so
/// a screen reader says it once.
// TODO: [CA-1158] replace this row with CoreUnderlineTextField once coreui releases it and the app moves to that version. https://ripplearc.youtrack.cloud/issue/CA-1158
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

  static const _contentInset = CoreSpacing.space5 + 2;

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
          excludeFromSemantics: true,
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              _contentInset,
              CoreSpacing.space3,
              _contentInset,
              bottomPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: valueGap,
              children: [
                ExcludeSemantics(
                  child: Text(
                    label,
                    style: textTheme.bodyMediumRegular.copyWith(
                      color: colorTheme.textBody,
                    ),
                  ),
                ),
                child,
              ],
            ),
          ),
        ),
        CoreDivider(
          color: colorTheme.lineDarkOutline,
          indent: CoreSpacing.space5,
          endIndent: CoreSpacing.space5,
        ),
      ],
    );
  }
}
