import 'package:construculator/features/estimation/domain/entities/cost_estimation_activity_type.dart';
import 'package:construculator/features/estimation/domain/entities/cost_estimation_log_entity.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:construculator/libraries/formatting/formatting_helper.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

class CostEstimationLogTile extends StatelessWidget {
  final CostEstimationLog log;
  final VoidCallback? onTap;

  const CostEstimationLogTile({super.key, required this.log, this.onTap});

  @override
  Widget build(BuildContext context) {
    final appColors = context.colorTheme;
    final typography = context.textTheme;
    return GestureDetector(
      key: const Key('logTileGestureDetector'),
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.only(
          top: CoreSpacing.space2,
          bottom: CoreSpacing.space4,
          right: CoreSpacing.space4,
          left: CoreSpacing.space4,
        ),
        decoration: BoxDecoration(
          boxShadow: CoreShadows.small,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  child: Text(
                    _getActivityTitle(context),
                    key: const Key('activityTitle'),
                    style: typography.bodyMediumMedium.copyWith(
                      color: appColors.textDark,
                    ),
                  ),
                ),
                CoreIconWidget(
                  key: const Key('activityIcon'),
                  icon: CoreIcons.arrowRight,
                  color: appColors.iconGrayMid,
                  size: 14,
                ),
              ],
            ),
            const SizedBox(height: CoreSpacing.space3),
            _buildSubtitle(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSubtitle(BuildContext context) {
    final appColors = context.colorTheme;
    final typography = context.textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CoreIconWidget(
          key: const Key('calendarIcon'),
          icon: CoreIcons.calendar,
          color: appColors.iconGrayMid,
          size: 14,
        ),
        const SizedBox(width: CoreSpacing.space2),
        Text(
          FormattingHelper.formatDate(log.loggedAt),
          key: const Key('dateText'),
          style: typography.bodySmallRegular.copyWith(
            color: appColors.textBody,
          ),
        ),
        const SizedBox(width: CoreSpacing.space2),
        Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            color: appColors.lineDarkOutline,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: CoreSpacing.space2),
        Text(
          FormattingHelper.formatTime(log.loggedAt),
          key: const Key('timeText'),
          style: typography.bodySmallRegular.copyWith(
            color: appColors.textBody,
          ),
        ),
        const SizedBox(width: CoreSpacing.space2),
        const Spacer(),
        CoreAvatar(
          key: const Key('avatar'),
          radius: 12,
          backgroundColor: appColors.orientMid,
          child: Center(
            child: Text(
              log.user.firstName[0],
              style: typography.bodySmallMedium.copyWith(
                color: appColors.textHeadline,
              ),
            ),
          ),
        ),
        const SizedBox(width: CoreSpacing.space2),
        Text(
          log.user.firstName,
          key: const Key('userName'),
          textAlign: TextAlign.right,
          style: typography.bodySmallRegular.copyWith(
            color: appColors.textBody,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  String _getActivityTitle(BuildContext context) {
    final l10n = context.l10n;
    final details = log.activityDetails;

    switch (log.activity) {
      case CostEstimationActivityType.costEstimationCreated:
        return l10n.activityCostEstimationCreated;
      case CostEstimationActivityType.costEstimationRenamed:
        final oldName = details['oldName'] as String?;
        final newName = details['newName'] as String?;
        if (oldName != null && newName != null) {
          return l10n.activityCostEstimationRenamed(oldName, newName);
        }
        return l10n.activityCostEstimationRenamedSimple;
      case CostEstimationActivityType.costEstimationExported:
        return l10n.activityCostEstimationExported;
      case CostEstimationActivityType.costEstimationLocked:
        return l10n.activityCostEstimationLocked;
      case CostEstimationActivityType.costEstimationUnlocked:
        return l10n.activityCostEstimationUnlocked;
      case CostEstimationActivityType.costEstimationDeleted:
        return l10n.activityCostEstimationDeleted;
      case CostEstimationActivityType.costItemAdded:
        final itemName = details['itemName'] as String?;
        if (itemName != null) {
          return l10n.activityCostItemAdded(itemName);
        }
        return l10n.activityCostItemAddedSimple;
      case CostEstimationActivityType.costItemEdited:
        final itemName = details['itemName'] as String?;
        if (itemName != null) {
          return l10n.activityCostItemEdited(itemName);
        }
        return l10n.activityCostItemEditedSimple;
      case CostEstimationActivityType.costItemRemoved:
        final itemName = details['itemName'] as String?;
        if (itemName != null) {
          return l10n.activityCostItemRemoved(itemName);
        }
        return l10n.activityCostItemRemovedSimple;
      case CostEstimationActivityType.costItemDuplicated:
        final itemName = details['itemName'] as String?;
        if (itemName != null) {
          return l10n.activityCostItemDuplicated(itemName);
        }
        return l10n.activityCostItemDuplicatedSimple;
      case CostEstimationActivityType.taskAssigned:
        final taskName = details['taskName'] as String?;
        final assigneeName = details['assigneeName'] as String?;
        if (taskName != null && assigneeName != null) {
          return l10n.activityTaskAssigned(taskName, assigneeName);
        }
        return l10n.activityTaskAssignedSimple;
      case CostEstimationActivityType.taskUnassigned:
        final taskName = details['taskName'] as String?;
        if (taskName != null) {
          return l10n.activityTaskUnassigned(taskName);
        }
        return l10n.activityTaskUnassignedSimple;
      case CostEstimationActivityType.costFileUploaded:
        final fileName = details['fileName'] as String?;
        final oldQty = details['oldQuantity'] as int?;
        final newQty = details['newQuantity'] as int?;
        if (fileName != null && oldQty != null && newQty != null) {
          return l10n.activityCostFileUploaded(fileName, oldQty, newQty);
        }
        return l10n.activityCostFileUploadedSimple;
      case CostEstimationActivityType.costFileDeleted:
        final fileName = details['fileName'] as String?;
        if (fileName != null) {
          return l10n.activityCostFileDeleted(fileName);
        }
        return l10n.activityCostFileDeletedSimple;
      case CostEstimationActivityType.attachmentAdded:
        final fileName = details['fileName'] as String?;
        if (fileName != null) {
          return l10n.activityAttachmentAdded(fileName);
        }
        return l10n.activityAttachmentAddedSimple;
      case CostEstimationActivityType.attachmentRemoved:
        final fileName = details['fileName'] as String?;
        if (fileName != null) {
          return l10n.activityAttachmentRemoved(fileName);
        }
        return l10n.activityAttachmentRemovedSimple;
    }
  }
}
