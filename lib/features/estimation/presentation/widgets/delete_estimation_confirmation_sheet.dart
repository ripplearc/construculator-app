import 'package:construculator/libraries/mixins/localization_mixin.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

class DeleteEstimationConfirmationSheet extends StatefulWidget {
  final String estimationName;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final int? imagesAttachedCount;
  final int? documentsAttachedCount;

  const DeleteEstimationConfirmationSheet({
    super.key,
    required this.estimationName,
    this.onConfirm,
    this.onCancel,
    this.imagesAttachedCount,
    this.documentsAttachedCount,
  });

  @override
  State<DeleteEstimationConfirmationSheet> createState() =>
      _DeleteEstimationConfirmationSheetState();
}

class _DeleteEstimationConfirmationSheetState
    extends State<DeleteEstimationConfirmationSheet>
    with LocalizationMixin {
  @override
  Widget build(BuildContext context) {
    final colorTheme = AppColorsExtension.of(context);
    final textTheme = AppTypographyExtension.of(context);

    return Container(
      decoration: BoxDecoration(
        color: colorTheme.pageBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(CoreSpacing.space4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: CoreSpacing.space4,
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
                  size: 32,
                  color: colorTheme.iconRed,
                ),
              ),
            ),

            Text(
              l10n.deleteEstimationConfirmTitle(widget.estimationName),
              style: textTheme.titleMediumSemiBold,
            ),

            Text(
              l10n.deleteEstimationWarningMessage,
              style: textTheme.bodyMediumRegular,
            ),
            const SizedBox(height: CoreSpacing.space4),

            if (widget.imagesAttachedCount != null ||
                widget.documentsAttachedCount != null)
              Row(
                children: [
                  if (widget.imagesAttachedCount != null)
                    Expanded(
                      child: Container(
                        key: const Key('images_attached_count_container'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: CoreSpacing.space3,
                          vertical: CoreSpacing.space3,
                        ),
                        decoration: BoxDecoration(
                          color: colorTheme.backgroundBlueLight,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          l10n.imagesAttachedCount(
                            widget.imagesAttachedCount ?? 0,
                          ),
                          style: textTheme.bodyMediumRegular.copyWith(
                            color: colorTheme.textDark,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  if (widget.imagesAttachedCount != null &&
                      widget.documentsAttachedCount != null)
                    const SizedBox(width: CoreSpacing.space3),
                  if (widget.documentsAttachedCount != null)
                    Expanded(
                      child: Container(
                        key: const Key('documents_attached_count_container'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: CoreSpacing.space3,
                          vertical: CoreSpacing.space3,
                        ),
                        decoration: BoxDecoration(
                          color: colorTheme.backgroundBlueLight,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          l10n.documentsAttachedCount(
                            widget.documentsAttachedCount ?? 0,
                          ),
                          style: textTheme.bodyMediumRegular.copyWith(
                            color: colorTheme.textDark,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            if (widget.imagesAttachedCount != null ||
                widget.documentsAttachedCount != null)
              const SizedBox(height: CoreSpacing.space6),

            Row(
              children: [
                Expanded(
                  child: CoreButton(
                    key: const Key('delete_estimation_confirm_button'),
                    label: l10n.yesDeleteButton,
                    onPressed: widget.onConfirm,
                    variant: CoreButtonVariant.secondary,
                  ),
                ),
                const SizedBox(width: CoreSpacing.space3),
                Expanded(
                  child: CoreButton(
                    key: const Key('delete_estimation_cancel_button'),
                    label: l10n.noKeepButton,
                    onPressed: widget.onCancel,
                    variant: CoreButtonVariant.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: CoreSpacing.space2),
          ],
        ),
      ),
    );
  }
}
