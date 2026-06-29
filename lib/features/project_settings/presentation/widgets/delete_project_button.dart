import 'package:construculator/features/project_settings/presentation/widgets/deletion_confirmation_bottom_sheet.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

// TODO: CA-180 — place DeleteProjectButton in ProjectDetailScreen once it exists.
// TODO: CA-180 — add a BlocListener in ProjectDetailScreen to show an error
//   snackbar when ProjectSettingsBloc emits ProjectSettingsError after deletion.

class DeleteProjectButton extends StatelessWidget {
  /// Display name of the project, forwarded to [DeletionConfirmationBottomSheet].
  final String projectName;

  /// When false the button is not rendered (non-admin users).
  final bool canDelete;

  /// When true the button is rendered but disabled (deletion in progress).
  final bool isDeleting;

  /// Called after the user confirms deletion in the bottom sheet.
  ///
  /// The caller is responsible for dispatching
  /// [ProjectSettingsDeleteRequested] to the bloc.
  final VoidCallback? onDeleteConfirmed;

  const DeleteProjectButton({
    super.key,
    required this.projectName,
    required this.canDelete,
    required this.isDeleting,
    this.onDeleteConfirmed,
  });

  void _showConfirmationSheet(BuildContext context) {
    final colorTheme = context.colorTheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorTheme.transparent,
      isDismissible: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => DeletionConfirmationBottomSheet(
        projectName: projectName,
        onConfirm: () {
          Navigator.of(context).pop();
          onDeleteConfirmed?.call();
        },
        onCancel: () => Navigator.of(context).pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!canDelete) return const SizedBox.shrink();

    return CoreButton(
      key: const Key('delete_project_button'),
      label: context.l10n.deleteProjectButton,
      onPressed: isDeleting ? null : () => _showConfirmationSheet(context),
      variant: CoreButtonVariant.secondary,
      fullWidth: false,
    );
  }
}
