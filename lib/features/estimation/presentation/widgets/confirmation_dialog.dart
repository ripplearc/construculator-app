import 'package:construculator/features/estimation/presentation/widgets/sheet_surface.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// A two-answer question over a sheet: a title, one line of body text, a
/// filled primary answer on top and an outlined secondary answer below it.
///
/// The answers always stack, each as wide as the dialog, so a long label or a
/// large text size wraps instead of being cut off. Each answer is drawn at
/// least 40 dp tall and grows with its text, inside a tap area at least 48 dp
/// tall.
///
/// The filled answer is the one the user asked for. The exception is a dialog
/// shown while leaving a form, where the answer that keeps the work is filled.
///
// TODO: [CA-1315] move this into ripplearc_coreui and move the Equipment delivery-fee dialog onto it. https://ripplearc.youtrack.cloud/issue/CA-1315
class ConfirmationDialog extends StatelessWidget {
  /// Key of the title text.
  static const titleKey = Key('confirmation_dialog_title');

  /// Key of the body text.
  static const bodyKey = Key('confirmation_dialog_body');

  /// Key of the outlined secondary button.
  static const secondaryButtonKey = Key('confirmation_dialog_secondary_button');

  /// Key of the filled primary button.
  static const primaryButtonKey = Key('confirmation_dialog_primary_button');

  static const double _minSideMargin = 36;

  /// The question, in one line.
  final String title;

  /// The text under the title. A [TextSpan] with bold parts lets a caller
  /// emphasise amounts or names.
  final InlineSpan body;

  /// Label of the outlined secondary button, which carries the destructive
  /// answer.
  final String secondaryLabel;

  /// Label of the filled primary button.
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
    required InlineSpan body,
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
      // The storyboard keeps at least 36 dp on each side, which is also what
      // makes the dialog at most 340 dp wide on a 412 dp phone.
      insetPadding: const EdgeInsets.symmetric(
        horizontal: _minSideMargin,
        vertical: CoreSpacing.space6,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CoreSpacing.space5),
      ),
      // The 22 dp padding and the 340 dp width come directly from the Figma
      // spec (node 65354:146175) and don't land on a named CoreSpacing step.
      child: SizedBox(
        width: 340,
        child: Padding(
          // 4 dp less at the bottom: the last answer's tap area already
          // reaches 4 dp below its drawn edge.
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
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
              Text.rich(
                body,
                key: bodyKey,
                style: textTheme.bodyLargeRegular.copyWith(
                  color: colorTheme.textBody,
                ),
              ),
              // 8 dp, because each answer's tap area adds 4 dp above its
              // drawn edge.
              const SizedBox(height: CoreSpacing.space2),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _AnswerButton(
                    key: primaryButtonKey,
                    label: primaryLabel,
                    isPrimary: true,
                    onTap: () => Navigator.of(context).pop(true),
                  ),
                  _AnswerButton(
                    key: secondaryButtonKey,
                    label: secondaryLabel,
                    isPrimary: false,
                    onTap: () => Navigator.of(context).pop(false),
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

/// One answer of [ConfirmationDialog]. It looks like a medium [CoreButton],
/// but its height grows with its text, because [CoreButton] has a fixed height
/// and cuts a long or large label with "...".
// TODO: [CA-1315] drop this with the rest of the dialog once ripplearc_coreui has a confirmation dialog.
class _AnswerButton extends StatefulWidget {
  static const double _drawnMinHeight = CoreSpacing.space10;
  static const double _tapPadding = CoreSpacing.space1;

  final String label;
  final bool isPrimary;
  final VoidCallback onTap;

  const _AnswerButton({
    super.key,
    required this.label,
    required this.isPrimary,
    required this.onTap,
  });

  @override
  State<_AnswerButton> createState() => _AnswerButtonState();
}

class _AnswerButtonState extends State<_AnswerButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final colorTheme = context.colorTheme;
    final color = _isPressed
        ? colorTheme.buttonPress
        : colorTheme.buttonSurface;
    final isPrimary = widget.isPrimary;
    return Semantics(
      button: true,
      label: widget.label,
      onTap: widget.onTap,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: _AnswerButton._tapPadding,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: _AnswerButton._drawnMinHeight,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(CoreSpacing.space10),
                color: isPrimary ? color : colorTheme.transparent,
                border: Border.all(color: color, width: isPrimary ? 0 : 2),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: CoreSpacing.space5,
                  vertical: CoreSpacing.space2,
                ),
                child: Center(
                  child: Text(
                    widget.label,
                    textAlign: TextAlign.center,
                    style: context.textTheme.bodyLargeSemiBold.copyWith(
                      color: isPrimary ? colorTheme.textInverse : color,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
