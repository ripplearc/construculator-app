import 'package:construculator/features/estimation/presentation/widgets/add_to_estimate_panel.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// The "Adds to this estimate" summary card and the full-width submit button
/// at the bottom of the equipment cost sheet.
class AddToEstimateFooter extends StatelessWidget {
  /// Key of the summary card.
  static const panelKey = Key('adds_to_estimate_panel');

  /// Key of the submit button.
  static const buttonKey = Key('add_to_estimate_button');

  /// Key of the save-error line.
  static const errorKey = Key('add_to_estimate_error');

  /// Key of the Delete this line button.
  static const deleteButtonKey = Key('delete_line_button');

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

  /// Called when the enabled button is tapped.
  final VoidCallback onAdd;

  /// How much saving moves the estimate total, in dollars, when the footer
  /// saves changes to a line already on the estimate; `null` when it adds a
  /// new line. Switches the panel and the button label to their edit wording.
  final double? changeInEstimateTotal;

  /// Called when the user taps Delete this line. The button is drawn only
  /// when this is set, which is for a line already on the estimate.
  final VoidCallback? onDelete;

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
    this.changeInEstimateTotal,
    this.onDelete,
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
              changeInEstimateTotal: changeInEstimateTotal,
            ),
            if (errorMessage case final message?) ...[
              const SizedBox(height: CoreSpacing.space4),
              _ErrorLine(message: message),
              const SizedBox(height: CoreSpacing.space2),
            ] else
              const SizedBox(height: CoreSpacing.space4),
            CoreButton(
              key: buttonKey,
              label:
                  block?.buttonLabel ??
                  (changeInEstimateTotal == null
                      ? l10n.addToEstimateButton
                      : l10n.saveThisLineButton),
              isDisabled: block != null || isSubmitting,
              onPressed: onAdd,
            ),
            if (onDelete case final onDelete?) ...[
              _DeleteLine(
                key: deleteButtonKey,
                isDisabled: isSubmitting,
                onTap: onDelete,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The red `Delete this line` text under the save button. It is plain text,
/// not an outlined button, with a tap area at least 48 dp high.
class _DeleteLine extends StatelessWidget {
  final bool isDisabled;
  final VoidCallback onTap;

  const _DeleteLine({super.key, required this.isDisabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final label = context.l10n.deleteThisLineButton;
    final colorTheme = context.colorTheme;
    return Semantics(
      button: true,
      enabled: !isDisabled,
      label: label,
      onTap: isDisabled ? null : onTap,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: isDisabled ? null : onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: CoreSpacing.space12),
          alignment: Alignment.center,
          child: Text(
            label,
            style: context.textTheme.bodyLargeSemiBold.copyWith(
              color: isDisabled ? colorTheme.textDisable : colorTheme.textError,
            ),
          ),
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
