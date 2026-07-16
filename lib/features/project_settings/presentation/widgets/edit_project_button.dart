import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// Primary pill button that navigates to the edit-project screen.
///
/// Returns [SizedBox.shrink] when [onPressed] is null — callers pass null for
/// users who lack edit permission (viewer role), so the button is fully hidden.
/// Disables itself while the async [onPressed] is in flight to prevent
/// duplicate taps during navigation.
class EditProjectButton extends StatefulWidget {
  /// Called when the button is tapped. May be async. Pass null to hide the
  /// button entirely for users who lack edit permission.
  final Future<void> Function()? onPressed;

  const EditProjectButton({super.key, this.onPressed});

  @override
  State<EditProjectButton> createState() => _EditProjectButtonState();
}

class _EditProjectButtonState extends State<EditProjectButton> {
  bool _isLoading = false;

  Future<void> _handleTap() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      await widget.onPressed?.call();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onPressed == null) return const SizedBox.shrink();

    return CoreButton(
      label: context.l10n.editProjectButton,
      variant: CoreButtonVariant.primary,
      onPressed: _isLoading ? null : _handleTap,
      isDisabled: _isLoading,
    );
  }
}
