import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// A label-above, underlined-value text field matching the Figma design
/// system's "Text Field" component (node `4:33`) in its underline style:
/// no surrounding border box, just a single rule beneath the value that
/// darkens and thickens on focus.
///
/// [CoreTextField] only renders an outlined box in every state — confirmed
/// by reading its source, no underline variant exists in `ripplearc_coreui`
/// as of 0.22.0 — so this widget exists specifically for the fields the
/// Figma mocks show underlined: Equipment name, Duration, Rate, and Amount.
///
// TODO: CA-1158 — replace this with CoreUI's underline text field once it exists
class UnderlineTextField extends StatefulWidget {
  /// Label shown above the value.
  final String label;

  final TextEditingController controller;
  final TextInputType? keyboardType;

  /// Trailing content at the end of the value row (e.g. the "days" suffix
  /// text or the "$" icon) — stays inline in the row, not inside a box.
  final Widget? suffix;

  /// Error messages shown below the rule. Only the first is rendered,
  /// matching [CoreTextField.errorTextList]'s icon + red text treatment.
  final List<String>? errorTextList;

  const UnderlineTextField({
    super.key,
    required this.label,
    required this.controller,
    this.keyboardType,
    this.suffix,
    this.errorTextList,
  });

  @override
  State<UnderlineTextField> createState() => _UnderlineTextFieldState();
}

class _UnderlineTextFieldState extends State<UnderlineTextField> {
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
    widget.controller.addListener(_onTextChange);
  }

  @override
  void didUpdateWidget(covariant UnderlineTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onTextChange);
      widget.controller.addListener(_onTextChange);
    }
  }

  void _onFocusChange() => setState(() {});

  void _onTextChange() => setState(() {});

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    widget.controller.removeListener(_onTextChange);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorTheme = context.colorTheme;
    final textTheme = context.textTheme;
    final suffix = widget.suffix;
    final errorTextList = widget.errorTextList;
    // An error for a genuinely invalid value (e.g. a typed duration of 0)
    // is only surfaced once the user leaves the field, not on every
    // keystroke — "0" is a valid prefix of "0.5" — and it clears the
    // instant the bloc stops reporting one, which happens as soon as a
    // valid value is typed, focused or not.
    final visibleErrorText =
        errorTextList != null &&
            errorTextList.isNotEmpty &&
            !_focusNode.hasFocus
        ? errorTextList.first
        : null;
    final hasError = visibleErrorText != null;
    final isEmpty = widget.controller.text.isEmpty;
    final ruleColor = hasError
        ? colorTheme.statusError
        : _focusNode.hasFocus
        ? colorTheme.textHeadline
        : colorTheme.lineMid;
    final ruleHeight = _focusNode.hasFocus || hasError ? 1.5 : 1.0;
    final textField = TextField(
      controller: widget.controller,
      focusNode: _focusNode,
      keyboardType: widget.keyboardType,
      cursorColor: colorTheme.textHeadline,
      style: isEmpty
          ? textTheme.bodyLargeRegular.copyWith(color: colorTheme.textDisable)
          : textTheme.bodyLargeSemiBold.copyWith(
              color: colorTheme.textHeadline,
            ),
      decoration: const InputDecoration(
        border: InputBorder.none,
        // Vertical padding, not zero: without it the field's own
        // interactive area is only as tall as its text line (~24px), short
        // of Android's 48dp minimum tap target.
        contentPadding: EdgeInsets.symmetric(vertical: CoreSpacing.space3),
      ),
    );

    // The label is its own Text (for exact control over the Figma
    // label-above-value layout) rather than InputDecoration.labelText, so
    // without this the field's accessible name would be dropped — a screen
    // reader would announce only "edit text", not "Equipment name, edit
    // text". MergeSemantics folds the label (and error) text into the same
    // node as the field, restoring that association.
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.label,
            style: textTheme.bodySmallRegular.copyWith(
              color: colorTheme.textBody,
            ),
          ),
          const SizedBox(height: CoreSpacing.space1),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // With a suffix (e.g. "days", "$"), the value field must size
              // to its own content so the suffix sits right beside the typed
              // number, matching Figma — an Expanded field would claim the
              // whole row before the suffix lays out, stranding it at the
              // row's trailing edge, far from the value. IntrinsicWidth (with
              // a floor so the tap target stays reasonable when empty) gives
              // that content-sized behavior; a field with no suffix keeps
              // Expanded so it still fills the row for normal typing.
              if (suffix != null)
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 24),
                  child: IntrinsicWidth(child: textField),
                )
              else
                Expanded(child: textField),
              if (suffix != null) ...[
                const SizedBox(width: CoreSpacing.space2),
                suffix,
              ],
            ],
          ),
          const SizedBox(height: CoreSpacing.space1),
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: ruleHeight,
            color: ruleColor,
          ),
          if (hasError) ...[
            const SizedBox(height: CoreSpacing.space1),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CoreIconWidget(
                  icon: CoreIcons.error,
                  size: 16,
                  color: colorTheme.iconRed,
                ),
                const SizedBox(width: CoreSpacing.space1),
                Expanded(
                  child: Text(
                    visibleErrorText,
                    style: textTheme.bodySmallRegular.copyWith(
                      color: colorTheme.textError,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
