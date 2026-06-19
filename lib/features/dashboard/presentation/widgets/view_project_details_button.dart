import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

// 48 × 48 hit target satisfies both Android (48 dp) and iOS (44 pt) a11y guidelines.
const double _kHitTargetSize = CoreSpacing.space12;
// 40 × 40 visual container per Figma; centred within the hit target.
const double _kVisualSize = CoreSpacing.space10;
// 8 px padding inside the 40 × 40 visual gives a 24 × 24 icon content area.
const double _kPadding = CoreSpacing.space2;
const double _kIconSize = CoreSpacing.space6;

const Key _kSettingsIconKey = Key('view_project_details_icon');
const Key _kLoadingIndicatorKey = Key('view_project_details_loading');

/// A 40 × 40 button that shows a settings icon and navigates to the project
/// details screen. Manages its own loading state while the async [onPressed]
/// callback is in flight; taps are ignored during loading.
class ViewProjectDetailsButton extends StatefulWidget {
  /// Called when the button is tapped. May be async; the button shows a
  /// loading indicator until the future completes.
  final Future<void> Function()? onPressed;

  const ViewProjectDetailsButton({super.key, this.onPressed});

  @override
  State<ViewProjectDetailsButton> createState() =>
      _ViewProjectDetailsButtonState();
}

class _ViewProjectDetailsButtonState extends State<ViewProjectDetailsButton> {
  bool _isLoading = false;

  Future<void> _handleTap() async {
    final onPressed = widget.onPressed;
    if (_isLoading || onPressed == null) return;
    setState(() => _isLoading = true);
    try {
      await onPressed();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colorTheme;

    final inner = SizedBox(
      width: _kHitTargetSize,
      height: _kHitTargetSize,
      child: GestureDetector(
        onTap: _handleTap,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: SizedBox(
            width: _kVisualSize,
            height: _kVisualSize,
            child: Padding(
              padding: const EdgeInsets.all(_kPadding),
              child: _isLoading
                  ? CoreLoadingIndicator(
                      key: _kLoadingIndicatorKey,
                      size: _kIconSize,
                    )
                  : CoreIconWidget(
                      key: _kSettingsIconKey,
                      icon: CoreIcons.settings,
                      size: _kIconSize,
                      color: colors.iconGrayMid,
                    ),
            ),
          ),
        ),
      ),
    );

    if (widget.onPressed != null) {
      return Semantics(
        button: true,
        label: context.l10n.projectSettingsSemanticLabel,
        child: inner,
      );
    }
    return ExcludeSemantics(child: inner);
  }
}
