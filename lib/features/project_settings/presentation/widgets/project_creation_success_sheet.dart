import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// Shows the project creation success sheet as a modal bottom sheet.
class ProjectCreationSuccessSheet {
  static void show(
    BuildContext context, {
    required VoidCallback onContinue,
  }) {
    CoreQuickSheet.show(
      context: context,
      child: ProjectCreationSuccessSheetContent(
        onContinue: onContinue,
      ),
    );
  }
}

/// Content widget for the project creation success sheet.
class ProjectCreationSuccessSheetContent extends StatelessWidget {
  final VoidCallback onContinue;

  const ProjectCreationSuccessSheetContent({
    super.key,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final typography = context.textTheme;
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.all(CoreSpacing.space6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/icons/success.png',
            width: 90,
            height: 90,
            package: 'ripplearc_coreui',
          ),
          const SizedBox(height: CoreSpacing.space4),
          Text(
            l10n.projectCreationSuccessMessage,
            textAlign: TextAlign.center,
            style: typography.titleLargeMedium,
          ),
          const SizedBox(height: CoreSpacing.space6),
          SizedBox(
            width: double.infinity,
            child: CoreButton(
              key: const Key('continue_to_dashboard_button'),
              label: l10n.continueToDashboardButton,
              onPressed: onContinue,
              variant: CoreButtonVariant.primary,
            ),
          ),
        ],
      ),
    );
  }
}
