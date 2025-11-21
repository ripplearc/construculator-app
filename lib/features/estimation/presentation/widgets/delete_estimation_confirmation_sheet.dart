import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

class DeleteEstimationConfirmationSheet extends StatelessWidget {
  final String estimationName;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final int? imagesAttachedCount;
  final int? documentsAttachedCount;

  const DeleteEstimationConfirmationSheet({
    super.key,
    required this.estimationName,
    required this.onConfirm,
    required this.onCancel,
    this.imagesAttachedCount,
    this.documentsAttachedCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(CoreSpacing.space4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: CoreSpacing.space4,
          children: [
            // Handle indicator
            Center(
              child: Container(
                width: CoreSpacing.space10,
                height: CoreSpacing.space1,
                decoration: BoxDecoration(
                  color: CoreTextColors.disable,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: CoreBackgroundColors.backgroundRedMid,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: CoreIconWidget(
                  icon: CoreIcons.delete,
                  size: 32,
                  color: CoreIconColors.red,
                ),
              ),
            ),

            // Title with estimation name inline
            Text.rich(
              TextSpan(
                text: 'Are you sure you want to remove ',
                style: CoreTypography.titleMediumSemiBold(),
                children: [
                  TextSpan(
                    text: '"$estimationName"?',
                    style: CoreTypography.titleMediumSemiBold(),
                  ),
                ],
              ),
            ),

            // Warning message
            Text(
              'By removing you will lose all the Material, Labour and Equipment Cost Calculation Permanently as well as the images and documents attached with that calculation also will be removed',
              style: CoreTypography.bodyMediumRegular(
                color: CoreTextColors.body,
              ),
            ),
            const SizedBox(height: CoreSpacing.space4),

            // Attachment info
            if (imagesAttachedCount != null || documentsAttachedCount != null)
              Row(
                children: [
                  if (imagesAttachedCount != null)
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: CoreSpacing.space3,
                          vertical: CoreSpacing.space3,
                        ),
                        decoration: BoxDecoration(
                          color: CoreBackgroundColors.backgroundBlueLight,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          '$imagesAttachedCount images attached',
                          style: CoreTypography.bodyMediumRegular(
                            color: CoreTextColors.dark,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  if (imagesAttachedCount != null &&
                      documentsAttachedCount != null)
                    const SizedBox(width: CoreSpacing.space3),
                  if (documentsAttachedCount != null)
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: CoreSpacing.space3,
                          vertical: CoreSpacing.space3,
                        ),
                        decoration: BoxDecoration(
                          color: CoreBackgroundColors.backgroundBlueLight,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          '$documentsAttachedCount documents attached',
                          style: CoreTypography.bodyMediumRegular(
                            color: CoreTextColors.dark,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            if (imagesAttachedCount != null || documentsAttachedCount != null)
              const SizedBox(height: CoreSpacing.space6),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: CoreButton(
                    label: 'Yes, Delete',
                    onPressed: onConfirm,
                    variant: CoreButtonVariant.secondary,
                  ),
                ),
                const SizedBox(width: CoreSpacing.space3),
                Expanded(
                  child: CoreButton(
                    label: 'No, Keep',
                    onPressed: onCancel,
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
