import 'package:construculator/features/estimation/domain/entities/cost_estimation_activity_type.dart';
import 'package:construculator/features/estimation/domain/entities/cost_estimation_log_entity.dart';
import 'package:construculator/features/estimation/presentation/helpers/cost_estimation_activity_title_formatter.dart';
import 'package:construculator/features/estimation/presentation/helpers/cost_item_edited_field_mapper.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:construculator/libraries/formatting/formatting_helper.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

class CostEstimationLogTile extends StatelessWidget {
  final CostEstimationLog log;

  const CostEstimationLogTile({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    final appColors = context.colorTheme;
    final typography = context.textTheme;
    return Container(
      constraints: const BoxConstraints(minHeight: 100),
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
                  CostEstimationActivityTitleFormatter.format(
                    context.l10n,
                    log,
                  ),
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
          const SizedBox(height: CoreSpacing.space2),
          _buildSubtitle(context),
          const SizedBox(height: CoreSpacing.space2),
          _buildBottomInfo(context),
        ],
      ),
    );
  }

  Widget _buildSubtitle(BuildContext context) {
    if (log.activity == CostEstimationActivityType.costEstimationRenamed) {
      final oldName = log.activityDetails['oldName'] as String?;
      final newName = log.activityDetails['newName'] as String?;
      if (oldName != null && newName != null) {
        return _buildRichSubtitleRow(context, oldName, newName);
      }
    } else if (log.activity ==
        CostEstimationActivityType.costEstimationExported) {
      final format = log.activityDetails['format'] as String?;
      if (format != null) {
        return _buildRichSubtitleSingleInfo(
          context,
          context.l10n.activityExportFormat,
          format,
        );
      }
    } else if (log.activity == CostEstimationActivityType.costItemAdded) {
      final itemType = log.activityDetails['costItemType'] as String?;
      if (itemType != null) {
        return _buildRichSubtitleSingleInfo(
          context,
          context.l10n.activityItemType,
          itemType,
        );
      }
    } else if (log.activity == CostEstimationActivityType.costItemEdited) {
      final changes = CostItemEditedFieldMapper.fromActivityDetails(
        context.l10n,
        log.activityDetails,
      );
      if (changes.isNotEmpty) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var index = 0; index < changes.length; index++) ...[
              _buildRichSubtitleRow(
                context,
                changes[index].fromValue,
                changes[index].toValue,
                fieldLabel: changes[index].fieldLabel,
              ),
              if (index < changes.length - 1)
                const SizedBox(height: CoreSpacing.space1),
            ],
          ],
        );
      }
    } else if (log.activity == CostEstimationActivityType.costItemRemoved) {
      final itemName = log.activityDetails['costItemType'] as String?;
      if (itemName != null) {
        return _buildRichSubtitleSingleInfo(
          context,
          context.l10n.activityItemType,
          itemName,
        );
      }
    } else if (log.activity == CostEstimationActivityType.taskAssigned ||
        log.activity == CostEstimationActivityType.taskUnassigned) {
      final taskName = log.activityDetails['taskName'] as String?;
      final assigneeName = log.activityDetails['assigneeName'] as String?;
      if (taskName != null && assigneeName != null) {
        return Column(
          children: [_buildRichSubtitleRow(context, taskName, assigneeName)],
        );
      }
    }

    return SizedBox.shrink();
  }

  Widget _buildRichSubtitleSingleInfo(
    BuildContext context,
    String label,
    String value,
  ) {
    final appColors = context.colorTheme;
    final typography = context.textTheme;

    return RichText(
      text: TextSpan(
        style: typography.bodySmallRegular.copyWith(color: appColors.textBody),
        children: [
          TextSpan(text: label, style: typography.bodyMediumRegular),
          TextSpan(
            text: value,
            style: typography.bodyMediumMedium.copyWith(
              color: appColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRichSubtitleRow(
    BuildContext context,
    String fromValue,
    String toValue, {
    String? fieldLabel,
  }) {
    final appColors = context.colorTheme;
    final typography = context.textTheme;

    return RichText(
      text: TextSpan(
        style: typography.bodySmallRegular.copyWith(color: appColors.textBody),
        children: [
          if (fieldLabel != null && fieldLabel.isNotEmpty)
            TextSpan(
              text: '$fieldLabel: ',
              style: typography.bodySmallRegular.copyWith(
                color: appColors.textBody,
              ),
            ),
          TextSpan(
            text: context.l10n.activityFrom,
            style: typography.bodySmallRegular.copyWith(
              color: appColors.textBody,
            ),
          ),
          TextSpan(
            text: fromValue,
            style: typography.bodySmallSemiBold.copyWith(
              color: appColors.textBody,
            ),
          ),
          WidgetSpan(
            child: Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: appColors.lineDarkOutline,
                shape: BoxShape.circle,
              ),
            ),
          ),
          TextSpan(
            text: context.l10n.activityTo,
            style: typography.bodySmallRegular.copyWith(
              color: appColors.textBody,
            ),
          ),
          TextSpan(
            text: toValue,
            style: typography.bodySmallRegular.copyWith(
              color: appColors.textBody,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomInfo(BuildContext context) {
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
          style: typography.bodySmallRegular,
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
}
