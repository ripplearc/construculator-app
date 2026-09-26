import 'package:construculator/features/estimation/domain/entities/cost_estimation_activity_type.dart';
import 'package:construculator/features/estimation/domain/entities/cost_estimation_log_entity.dart';
import 'package:construculator/features/estimation/presentation/helpers/cost_estimation_activity_title_formatter.dart';
import 'package:construculator/features/estimation/presentation/helpers/cost_item_edited_field_mapper.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:construculator/libraries/formatting/display_formatter.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

class CostEstimationLogTile extends StatelessWidget {
  final CostEstimationLog log;

  const CostEstimationLogTile({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    final appColors = context.colorTheme;
    final typography = context.textTheme;
    final subtitle = _buildSubtitle(context);
    return Container(
      padding: EdgeInsets.only(
        top: CoreSpacing.space2,
        bottom: CoreSpacing.space4,
        right: CoreSpacing.space4,
        left: CoreSpacing.space4,
      ),
      decoration: BoxDecoration(
        boxShadow: CoreShadows.small,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: appColors.lineLight),
        color: appColors.pageBackground,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
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
                  style: typography.bodyMediumSemiBold.copyWith(
                    color: appColors.textHeadline,
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
          if (subtitle != null) ...[
            const SizedBox(height: CoreSpacing.space1),
            subtitle,
          ],
          const SizedBox(height: CoreSpacing.space2),
          _buildBottomInfo(context),
        ],
      ),
    );
  }

  Widget? _buildSubtitle(BuildContext context) {
    switch (log.activity) {
      case CostEstimationActivityType.costEstimationRenamed:
        return _buildRenamedSubtitle(context);
      case CostEstimationActivityType.costEstimationExported:
        return _buildExportedSubtitle(context);
      case CostEstimationActivityType.costItemAdded:
      case CostEstimationActivityType.costItemRemoved:
        return _buildItemTypeSubtitle(context);
      case CostEstimationActivityType.costItemEdited:
        return _buildEditedFieldsSubtitle(context);
      case CostEstimationActivityType.taskAssigned:
        return _buildTaskAssignedSubtitle(context);
      default:
        return null;
    }
  }

  Widget? _buildRenamedSubtitle(BuildContext context) {
    final oldName = log.activityDetails['oldName'] as String?;
    final newName = log.activityDetails['newName'] as String?;
    if (oldName != null && newName != null) {
      return _buildSubtitleRow(
        context,
        oldName,
        newName,
        emphasizeValues: false,
      );
    }
    return null;
  }

  Widget? _buildExportedSubtitle(BuildContext context) {
    final format = log.activityDetails['format'] as String?;
    if (format != null) {
      return _buildSubtitleSingleInfo(
        context,
        context.l10n.activityExportFormat,
        format,
      );
    }
    return null;
  }

  Widget? _buildItemTypeSubtitle(BuildContext context) {
    final itemType = log.activityDetails['itemType'] as String?;
    if (itemType != null) {
      return _buildSubtitleSingleInfo(
        context,
        context.l10n.activityItemType,
        itemType,
      );
    }
    return null;
  }

  Widget? _buildEditedFieldsSubtitle(BuildContext context) {
    final changes = CostItemEditedFieldMapper.fromActivityDetails(
      context.l10n,
      log.activityDetails,
    );
    if (changes.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var index = 0; index < changes.length; index++) ...[
            _buildSubtitleRow(
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
    return null;
  }

  Widget? _buildTaskAssignedSubtitle(BuildContext context) {
    final taskName = log.activityDetails['taskName'] as String?;
    final assigneeName = log.activityDetails['assigneeName'] as String?;
    if (taskName != null && assigneeName != null) {
      return Column(
        children: [_buildSubtitleRow(context, taskName, assigneeName)],
      );
    }
    return null;
  }

  Widget _buildSubtitleSingleInfo(
    BuildContext context,
    String label,
    String value,
  ) {
    final emphasis = context.textTheme.bodyMediumSemiBold.copyWith(
      color: context.colorTheme.textHeadline,
    );

    // The label ends in a space, so label and value read as one line.
    return Text.rich(
      TextSpan(
        style: emphasis,
        children: [TextSpan(text: label), TextSpan(text: value)],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildSubtitleRow(
    BuildContext context,
    String fromValue,
    String toValue, {
    String? fieldLabel,
    bool emphasizeValues = true,
  }) {
    final appColors = context.colorTheme;
    final typography = context.textTheme;
    final regular = typography.bodyMediumRegular.copyWith(
      color: appColors.textBody,
    );
    final emphasis = typography.bodyMediumSemiBold.copyWith(
      color: appColors.textHeadline,
    );
    final labelStyle = emphasizeValues ? regular : emphasis;
    final valueStyle = emphasizeValues ? emphasis : regular;

    // One run of text, so a long name wraps word by word as on the
    // storyboard, with 8px either side of the dot.
    return Text.rich(
      TextSpan(
        children: [
          if (fieldLabel != null && fieldLabel.isNotEmpty)
            TextSpan(text: '$fieldLabel: ', style: emphasis),
          TextSpan(text: context.l10n.activityFrom, style: labelStyle),
          TextSpan(text: fromValue, style: valueStyle),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: CoreSpacing.space2,
              ),
              child: Container(
                width: CoreSpacing.space1,
                height: CoreSpacing.space1,
                decoration: BoxDecoration(
                  color: appColors.lineDarkOutline,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          TextSpan(text: context.l10n.activityTo, style: labelStyle),
          TextSpan(text: toValue, style: valueStyle),
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
          size: CoreIconSize.size16,
        ),
        const SizedBox(width: CoreSpacing.space2),
        Text(
          DisplayFormatter.formatDate(log.loggedAt),
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
          DisplayFormatter.formatTime(log.loggedAt),
          key: const Key('timeText'),
          style: typography.bodySmallRegular.copyWith(
            color: appColors.textBody,
          ),
        ),
        const SizedBox(width: CoreSpacing.space2),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CoreAvatar(
                key: const Key('avatar'),
                radius: 12,
                backgroundColor: appColors.orientLight,
                child: Center(
                  child: Text(
                    log.user.firstName.isNotEmpty ? log.user.firstName[0] : '?',
                    style: typography.bodySmallSemiBold.copyWith(
                      color: appColors.textHeadline,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: CoreSpacing.space2),
              Flexible(
                child: Text(
                  log.user.firstName,
                  key: const Key('userName'),
                  textAlign: TextAlign.right,
                  style: typography.bodySmallRegular.copyWith(
                    color: appColors.textBody,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
