import 'package:construculator/features/dashboard/domain/entities/cost_file_entity.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:construculator/libraries/formatting/display_formatter.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// Displays a single cost file as a card row showing the file name,
/// size, and upload date.
class CostFileItem extends StatelessWidget {
  final CostFile file;

  const CostFileItem({super.key, required this.file});

  @override
  Widget build(BuildContext context) {
    final colors = context.colorTheme;
    final typography = context.textTheme;

    return Container(
      padding: const EdgeInsets.all(CoreSpacing.space3),
      decoration: BoxDecoration(
        color: colors.pageBackground,
        border: Border.all(color: colors.lineLight),
        borderRadius: BorderRadius.circular(CoreSpacing.space2),
        boxShadow: CoreShadows.small,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(CoreSpacing.space2),
            decoration: BoxDecoration(
              color: colors.backgroundBlueLight,
              borderRadius: BorderRadius.circular(30),
            ),
            child: CoreIconWidget(
              icon: CoreIcons.file,
              size: CoreIconSize.size24,
              color: colors.iconOrient,
            ),
          ),
          const SizedBox(width: CoreSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  file.fileName,
                  style: typography.bodyMediumMedium.copyWith(
                    color: colors.textDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      DisplayFormatter.formatFileSize(file.fileSizeInBytes),
                      style: typography.bodySmallMedium.copyWith(
                        color: colors.textDark,
                      ),
                    ),
                    const SizedBox(width: CoreSpacing.space2),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colors.textBody,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: CoreSpacing.space2),
                    Text(
                      context.l10n.uploadedOnLabel,
                      style: typography.bodySmallRegular.copyWith(
                        color: colors.textBody,
                      ),
                    ),
                    const SizedBox(width: CoreSpacing.space1),
                    Text(
                      DisplayFormatter.date.format(file.uploadedAt),
                      style: typography.bodySmallMedium.copyWith(
                        color: colors.textDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
