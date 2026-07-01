import 'package:construculator/features/dashboard/domain/entities/cost_file_entity.dart';
import 'package:construculator/features/dashboard/presentation/widgets/cost_file_item.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// Displays the Cost Files section on the project details screen,
/// showing a vertical list of [CostFileItem]s or an empty state.
///
/// TODO(CA-180): Wire [files] to live data from DashboardBloc when the
/// Project Details Screen is assembled.
class CostFilesSection extends StatelessWidget {
  final List<CostFile> files;

  const CostFilesSection({super.key, required this.files});

  @override
  Widget build(BuildContext context) {
    final colors = context.colorTheme;
    final typography = context.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.costFilesSectionTitle,
          style: typography.titleMediumSemiBold.copyWith(
            color: colors.textDark,
          ),
        ),
        const SizedBox(height: CoreSpacing.space4),
        if (files.isEmpty)
          Center(
            child: Text(
              context.l10n.costFilesEmptyState,
              style: typography.bodyMediumRegular.copyWith(
                color: colors.textBody,
              ),
            ),
          )
        else
          Column(
            children: [
              for (int i = 0; i < files.length; i++) ...[
                CostFileItem(file: files[i]),
                if (i < files.length - 1)
                  const SizedBox(height: CoreSpacing.space6),
              ],
            ],
          ),
      ],
    );
  }
}
