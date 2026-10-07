import 'package:construculator/features/estimation/presentation/widgets/add_to_estimate_panel.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// The "Adds to this estimate" summary card and the full-width submit button
/// at the bottom of the equipment cost sheet.
class AddToEstimateFooter extends StatelessWidget {
  static const panelKey = Key('adds_to_estimate_panel');
  static const buttonKey = Key('add_to_estimate_button');
  static const errorKey = Key('add_to_estimate_error');

  /// The line's own total including delivery. Ignored while [block] is set.
  final double lineTotal;

  /// Shown as an "incl. delivery" row when above zero.
  final double? deliveryFee;

  /// The name of the estimate the line is added to.
  final String estimateName;

  /// That estimate's running total before this line is added.
  final double estimateTotal;

  /// Null when the form is ready to submit.
  final AddToEstimateBlock? block;

  /// Disables the button while a submit is in flight.
  final bool isSubmitting;

  /// A line above the button that says the last save failed, or null when
  /// there is nothing to say.
  final String? errorMessage;

  final VoidCallback onAdd;

  const AddToEstimateFooter({
    super.key,
    required this.lineTotal,
    this.deliveryFee,
    required this.estimateName,
    required this.estimateTotal,
    this.block,
    this.isSubmitting = false,
    this.errorMessage,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final block = this.block;
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: CoreSpacing.space7),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: CoreSpacing.space5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AddToEstimatePanel(
              key: panelKey,
              lineTotal: lineTotal,
              deliveryFee: deliveryFee,
              estimateName: estimateName,
              estimateTotal: estimateTotal,
              block: block,
            ),
            if (errorMessage case final message?) ...[
              const SizedBox(height: CoreSpacing.space3),
              _ErrorLine(message: message),
            ],
            const SizedBox(height: CoreSpacing.space4),
            CoreButton(
              key: buttonKey,
              label: block?.buttonLabel ?? l10n.addToEstimateButton,
              isDisabled: block != null || isSubmitting,
              onPressed: onAdd,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorLine extends StatelessWidget {
  final String message;

  const _ErrorLine({required this.message});

  @override
  Widget build(BuildContext context) {
    final colorTheme = context.colorTheme;
    return Semantics(
      liveRegion: true,
      child: Row(
        key: AddToEstimateFooter.errorKey,
        spacing: CoreSpacing.space2,
        children: [
          CoreIconWidget(
            icon: CoreIcons.error,
            size: CoreIconSize.size16,
            color: colorTheme.textError,
          ),
          Expanded(
            child: Text(
              message,
              style: context.textTheme.bodySmallRegular.copyWith(
                color: colorTheme.textError,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
