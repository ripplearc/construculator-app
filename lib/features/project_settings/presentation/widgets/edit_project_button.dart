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

const Key _kEditIconKey = Key('edit_project_icon');
const Key _kLoadingIndicatorKey = Key('edit_project_loading');

/// A 40 × 40 button that shows an edit icon and navigates to the edit project
/// screen. Hidden entirely (returns [SizedBox.shrink]) when [onPressed] is
/// null — callers pass null for users without edit permission (viewer role).
/// Manages its own loading state while the async [onPressed] is in flight;
/// taps are ignored during loading.
class EditProjectButton extends StatefulWidget {
  /// Called when the button is tapped. May be async; the button shows a
  /// loading indicator until the future completes. Pass null to hide the
  /// button for users who lack edit permission.
  final Future<void> Function()? onPressed;

  const EditProjectButton({super.key, this.onPressed});

  @override
  State<EditProjectButton> createState() => _EditProjectButtonState();
}

class _EditProjectButtonState extends State<EditProjectButton> {
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
    if (widget.onPressed == null) return const SizedBox.shrink();

    final colors = context.colorTheme;

    return Semantics(
      button: true,
      label: context.l10n.editProjectSemanticLabel,
      child: SizedBox(
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
                        key: _kEditIconKey,
                        icon: CoreIcons.edit,
                        size: _kIconSize,
                        color: colors.iconGrayMid,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
