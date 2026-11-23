import 'package:construculator/features/estimation/presentation/widgets/add_to_estimate_panel.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// Which parts of an [AddToEstimateFooter] to draw.
enum AddToEstimateFooterPart {
  /// The card, then the error line and the button or number pad.
  all,

  /// The card alone, with the gap above it, to scroll with the form.
  panel,

  /// The error line and the button or number pad, without the card.
  controls,
}

/// The "Adds to this estimate" summary card and the full-width submit button
/// at the bottom of the material, equipment and labor cost sheets.
///
/// [part] splits the two, so a phone too short to pin both the card and the
/// number pad can scroll the card with the form.
class AddToEstimateFooter extends StatelessWidget {
  /// Key of the summary card.
  static const panelKey = Key('adds_to_estimate_panel');
  /// Key of the submit button.
  static const buttonKey = Key('add_to_estimate_button');
  /// Key of the save-error line.
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

  /// Disables the button while the form is busy: a submit is in flight, or
  /// another save the form must wait for is still running.
  final bool isBusy;

  /// A line above the button that says the last save failed, or null when
  /// there is nothing to say.
  final String? errorMessage;

  /// Called when the enabled button is tapped.
  final VoidCallback onAdd;

  /// The app's own number pad, drawn in place of the button while it is up.
  /// The pad spans the sheet with its own side insets, and its confirm key
  /// stands in for the button (storyboard CUJ 4, Keys up). Null draws the
  /// button.
  final Widget? keypad;

  /// Which parts to draw; [AddToEstimateFooterPart.all] by default.
  final AddToEstimateFooterPart part;

  const AddToEstimateFooter({
    super.key,
    required this.lineTotal,
    this.deliveryFee,
    required this.estimateName,
    required this.estimateTotal,
    this.block,
    this.isBusy = false,
    this.errorMessage,
    required this.onAdd,
    this.keypad,
    this.part = AddToEstimateFooterPart.all,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final block = this.block;
    const sideInset = EdgeInsets.symmetric(horizontal: CoreSpacing.space5);
    final panel = Padding(
      padding: sideInset,
      child: AddToEstimatePanel(
        key: panelKey,
        lineTotal: lineTotal,
        deliveryFee: deliveryFee,
        estimateName: estimateName,
        estimateTotal: estimateTotal,
        block: block,
      ),
    );
    if (part == AddToEstimateFooterPart.panel) {
      return Padding(
        padding: const EdgeInsets.only(top: CoreSpacing.space4),
        child: panel,
      );
    }
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: CoreSpacing.space7),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (part == AddToEstimateFooterPart.all) panel,
          if (errorMessage case final message?) ...[
            const SizedBox(height: CoreSpacing.space4),
            Padding(
              padding: sideInset,
              child: CoreInlineErrorRow(
                key: AddToEstimateFooter.errorKey,
                message: message,
              ),
            ),
            const SizedBox(height: CoreSpacing.space2),
          ] else
            const SizedBox(height: CoreSpacing.space4),
          keypad ??
              Padding(
                padding: sideInset,
                child: CoreButton(
                  key: buttonKey,
                  label: block?.buttonLabel ?? l10n.addToEstimateButton,
                  isDisabled: block != null || isBusy,
                  onPressed: onAdd,
                ),
              ),
        ],
      ),
    );
  }
}
