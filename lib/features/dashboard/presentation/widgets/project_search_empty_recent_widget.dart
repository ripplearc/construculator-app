import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// Empty state shown in the [ProjectSearchPage] when the user has no recent
/// project searches.
class ProjectSearchEmptyRecentWidget extends StatelessWidget {
  const ProjectSearchEmptyRecentWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CoreIconWidget(
            icon: CoreIcons.search,
            size: CoreIconSize.size32,
            color: context.colorTheme.iconDark,
          ),
          const SizedBox(height: CoreSpacing.space6),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: CoreSpacing.space10,
            ),
            child: Text(
              context.l10n.projectSearchEmptyRecentMessage,
              textAlign: TextAlign.center,
              style: context.textTheme.bodyMediumRegular.copyWith(
                color: context.colorTheme.textHeadline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
