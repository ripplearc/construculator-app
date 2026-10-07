import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// The rounded frame around one cost line on the estimate screen. The line
/// added last takes a blue border and a blue fill; every other line has a grey
/// border and no fill. The highlight has no shadow and no animation, and does not
/// change the corners or padding.
///
// TODO: [CA-151] draw the estimate's cost lines inside this frame once the details screen is bound to data, and call clear on the highlight cubit from [onTap].
class CostLineCardFrame extends StatelessWidget {
  // The Figma card uses 14 for its corners and its top and bottom padding, a
  // step CoreSpacing does not have.
  static const double _cornerRadius = 14;
  static const double _verticalPadding = 14;

  /// Whether this is the line that was just added.
  final bool isHighlighted;

  /// Called when the user taps the line.
  final VoidCallback? onTap;

  /// The line's text and tags.
  final Widget child;

  const CostLineCardFrame({
    super.key,
    required this.isHighlighted,
    required this.child,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorTheme = context.colorTheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isHighlighted
              ? colorTheme.backgroundBlueLight
              : colorTheme.transparent,
          borderRadius: BorderRadius.circular(_cornerRadius),
          border: Border.all(
            color: isHighlighted
                ? colorTheme.lineHighlight
                : colorTheme.lineLight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: CoreSpacing.space4,
            vertical: _verticalPadding,
          ),
          child: child,
        ),
      ),
    );
  }
}
