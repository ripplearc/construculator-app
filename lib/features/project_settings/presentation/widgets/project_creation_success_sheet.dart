import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

class ProjectCreationSuccessSheet {
  static void show(
    BuildContext context, {
    required VoidCallback onBackToCalculation,
    required VoidCallback onContinue,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      enableDrag: false,
      isDismissible: false,
      backgroundColor: context.colorTheme.pageBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ProjectCreationSuccessSheetContent(
        onBackToCalculation: onBackToCalculation,
        onContinue: onContinue,
      ),
    );
  }
}

class ProjectCreationSuccessSheetContent extends StatelessWidget {
  final VoidCallback onBackToCalculation;
  final VoidCallback onContinue;

  const ProjectCreationSuccessSheetContent({
    super.key,
    required this.onBackToCalculation,
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
          Row(
            children: [
              Expanded(
                child: CoreButton(
                  key: const Key('back_to_calculation_button'),
                  label: l10n.backToCalculationButton,
                  onPressed: onBackToCalculation,
                  variant: CoreButtonVariant.secondary,
                  icon: const CoreIconWidget(icon: CoreIcons.arrowLeft),
                  centerAlign: true,
                ),
              ),
              const SizedBox(width: CoreSpacing.space3),
              Expanded(
                child: CoreButton(
                  key: const Key('continue_button'),
                  label: l10n.continueButton,
                  onPressed: onContinue,
                  variant: CoreButtonVariant.primary,
                  centerAlign: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
