import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

const double _kProjectSelectionIndicatorBorderWidth = 3;

/// Wraps [child] in the highlighted card decoration that signals the currently
/// selected project: a 3 px [AppColorsExtension.lineHighlight] (cyan) border
/// matching the Figma spec (DASH-014, node 57511-16873).
///
/// Must be placed inside a [Material] ancestor so InkWell ripples propagate
/// through the [Ink] layer correctly.
class ProjectSelectionIndicator extends StatelessWidget {
  /// The card content to decorate with the selection highlight.
  final Widget child;

  const ProjectSelectionIndicator({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final colors = context.colorTheme;
    return Ink(
      padding: const EdgeInsets.all(CoreSpacing.space4),
      decoration: BoxDecoration(
        color: colors.pageBackground,
        borderRadius: BorderRadius.circular(CoreSpacing.space3),
        border: Border.all(
          color: colors.lineHighlight,
          width: _kProjectSelectionIndicatorBorderWidth,
        ),
        boxShadow: CoreShadows.small,
      ),
      child: child,
    );
  }
}
