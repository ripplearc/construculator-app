import 'package:construculator/features/estimation/presentation/widgets/sheet_surface.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// A two-answer question over a sheet: a title, one line of body text, an
/// outlined secondary button and a filled primary button, the same dialog the
/// equipment form raises for an outsized delivery fee.
///
/// The destructive answer belongs on the secondary button, so it is never the
/// filled, default-tap one.
///
// TODO: use a CoreUI confirmation dialog and spacing tokens once they exist, and move the equipment delivery-fee dialog onto this one. CoreUI has none today and no ticket tracks it yet.
class ConfirmationDialog extends StatelessWidget {
  static const titleKey = Key('confirmation_dialog_title');
  static const bodyKey = Key('confirmation_dialog_body');
  static const secondaryButtonKey = Key('confirmation_dialog_secondary_button');
  static const primaryButtonKey = Key('confirmation_dialog_primary_button');

  final String title;
  final String body;
  final String secondaryLabel;
  final String primaryLabel;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.body,
    required this.secondaryLabel,
    required this.primaryLabel,
  });

  /// Shows the dialog and returns true for the primary button, false for the
  /// secondary one, and null when it is dismissed by a tap outside or the
  /// phone's back gesture.
  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String body,
    required String secondaryLabel,
    required String primaryLabel,
  }) => showDialog<bool>(
    context: context,
    builder: (_) => ConfirmationDialog(
      title: title,
      body: body,
      secondaryLabel: secondaryLabel,
      primaryLabel: primaryLabel,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final colorTheme = context.colorTheme;
    final textTheme = context.textTheme;
    return Dialog(
      backgroundColor: sheetSurface(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CoreSpacing.space5),
      ),
      // 22px padding and the 340 width come directly from the Figma spec
      // (node 65354:146175) and don't land on a named CoreSpacing step.
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: SizedBox(
          width: 340,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                key: titleKey,
                style: textTheme.titleMediumSemiBold.copyWith(
                  color: colorTheme.textHeadline,
                ),
              ),
              const SizedBox(height: CoreSpacing.space3),
              Text(
                body,
                key: bodyKey,
                style: textTheme.bodyMediumRegular.copyWith(
                  color: colorTheme.textBody,
                ),
              ),
              const SizedBox(height: CoreSpacing.space3),
              Row(
                children: [
                  Expanded(
                    child: CoreButton(
                      key: secondaryButtonKey,
                      label: secondaryLabel,
                      variant: CoreButtonVariant.secondary,
                      size: CoreButtonSize.medium,
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                  ),
                  const SizedBox(width: CoreSpacing.space3),
                  Expanded(
                    child: CoreButton(
                      key: primaryButtonKey,
                      label: primaryLabel,
                      variant: CoreButtonVariant.primary,
                      size: CoreButtonSize.medium,
                      onPressed: () => Navigator.of(context).pop(true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
