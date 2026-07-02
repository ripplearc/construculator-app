import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

class DeletionConfirmationBottomSheet extends StatelessWidget {
  final String projectName;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  /// Count of images attached to the project's calculations.
  ///
  /// When null the chip is hidden. Pass null until CA-269 (cost_files table)
  /// is implemented; at that point supply the real aggregate count.
  final int? imagesAttachedCount;

  const DeletionConfirmationBottomSheet({
    super.key,
    required this.projectName,
    this.onConfirm,
    this.onCancel,
    this.imagesAttachedCount,
  });

  // TODO: [CA-182] Add a static show() helper wired to ProjectSettingsBloc
  // once DeleteProjectButton wires this sheet.
  // https://ripplearc.youtrack.cloud/issue/CA-182

  @override
  Widget build(BuildContext context) {
    final colorTheme = context.colorTheme;
    final textTheme = context.textTheme;
    final l10n = context.l10n;
    final imageCount = imagesAttachedCount;

    return Container(
      decoration: BoxDecoration(
        color: colorTheme.pageBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.all(CoreSpacing.space4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: CoreSpacing.space8,
        children: [
          Center(
            child: Container(
              width: CoreSpacing.space10,
              height: CoreSpacing.space1,
              decoration: BoxDecoration(
                color: colorTheme.textDisable,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Column(
            spacing: CoreSpacing.space3,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: colorTheme.backgroundRedMid,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: CoreIconWidget(
                    icon: CoreIcons.delete,
                    size: CoreSpacing.space8,
                    color: colorTheme.iconRed,
                  ),
                ),
              ),

              Text(
                l10n.deleteProjectConfirmTitle(projectName),
                style: textTheme.titleMediumSemiBold,
              ),

              Text(
                l10n.deleteProjectWarningMessage,
                style: textTheme.bodyMediumRegular,
              ),

              if (imageCount != null)
                Container(
                  key: const Key('project_images_attached_count_container'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: CoreSpacing.space4,
                    vertical: CoreSpacing.space2,
                  ),
                  decoration: BoxDecoration(
                    color: colorTheme.backgroundBlueLight,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    l10n.imagesAttachedCount(imageCount),
                    style: textTheme.bodyMediumRegular.copyWith(
                      color: colorTheme.textDark,
                    ),
                  ),
                ),
            ],
          ),

          Row(
            children: [
              Expanded(
                child: CoreButton(
                  key: const Key('delete_project_confirm_button'),
                  label: l10n.yesDeleteButton,
                  onPressed: onConfirm,
                  variant: CoreButtonVariant.secondary,
                ),
              ),
              const SizedBox(width: CoreSpacing.space3),
              Expanded(
                child: CoreButton(
                  key: const Key('delete_project_cancel_button'),
                  label: l10n.noKeepButton,
                  onPressed: onCancel,
                  variant: CoreButtonVariant.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
