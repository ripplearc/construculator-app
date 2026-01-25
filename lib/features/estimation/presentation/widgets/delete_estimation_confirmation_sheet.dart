import 'package:construculator/libraries/extensions/extensions.dart';
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
    extends State<DeleteEstimationConfirmationSheet> {
  @override
  Widget build(BuildContext context) {
    final colorTheme = context.colorTheme;
    final textTheme = context.textTheme;
    final l10n = context.l10n;

    return Container(
      decoration: BoxDecoration(
        color: colorTheme.pageBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.all(CoreSpacing.space4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: CoreSpacing.space4,
        children: [
          Center(
            child: Container(
              width: CoreSpacing.space10,
              height: CoreSpacing.space1,
              padding: EdgeInsets.only(bottom: CoreSpacing.space4),
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

              if (widget.imagesAttachedCount != null ||
                  widget.documentsAttachedCount != null)
                Row(
                  spacing: CoreSpacing.space3,
                  children: [
                    if (widget.imagesAttachedCount != null)
                      Expanded(
                        child: Container(
                          key: const Key('images_attached_count_container'),
                          padding: const EdgeInsets.symmetric(
                            horizontal: CoreSpacing.space4,
                            vertical: CoreSpacing.space2,
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
                    if (widget.documentsAttachedCount != null)
                      Expanded(
                        child: Container(
                          key: const Key('documents_attached_count_container'),
                          padding: const EdgeInsets.symmetric(
                            horizontal: CoreSpacing.space4,
                            vertical: CoreSpacing.space2,
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
            ],
          ),

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
        ],
      ),
    );
  }
}
