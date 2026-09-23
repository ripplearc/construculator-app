import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// A label-above, underlined-value text field matching the Figma design
/// system's "Text Field" component (node `4:33`) in its underline style:
/// no surrounding border box, just a single rule beneath the value that
/// darkens and thickens on focus.
///
/// [CoreTextField] only renders an outlined box in every state; no underline
/// variant exists in `ripplearc_coreui` as of 0.22.0. This widget exists
/// specifically for the fields the Figma mocks show underlined: Equipment
/// name, Duration, Rate, and Amount.
///
// TODO: [CA-1158] Replace with CoreUI's underline text field once it exists. https://ripplearc.youtrack.cloud/issue/CA-1158
class UnderlineTextField extends StatefulWidget {
  /// Label shown above the value.
  final String label;

  /// Controls and reads the value text.
  final TextEditingController controller;

  /// Placeholder text shown in the value row, in the value's own text
  /// color/weight, while the controller is empty (e.g. the equipment name
  /// field's "Name the equipment", or the Note field's "Add a note
  /// (optional)"). Fields that don't pass this simply render nothing while
  /// empty.
  final String? hintText;

  /// Keyboard type shown when the field is focused.
  final TextInputType? keyboardType;

  /// Leading content at the start of the value row (e.g. the delivery-fee
  /// field's "$" icon, which sits before the digits rather than after them)
  /// — stays inline in the row, not inside a box.
  final Widget? prefix;

  /// Trailing content at the end of the value row (e.g. the "days" suffix
  /// text or the "$" icon) — stays inline in the row, not inside a box.
  final Widget? suffix;

  /// Content shown at the end of the label row, beside [label] (e.g. the
  /// Rate field's "Sample rate"/"✓ Your rate" status badge).
  final Widget? labelTrailing;

  /// Content right-aligned at the end of the value row, after [suffix]
  /// (e.g. the Rate field's "Save as my rate" link).
  final Widget? trailingAction;

  /// External focus node, for callers that need to observe or drive focus
  /// from outside (e.g. the delivery-fee editor folds back to its collapsed
  /// summary row when this loses focus). Defaults to an internally owned
  /// node when omitted.
  final FocusNode? focusNode;

  /// Error messages shown below the rule. Only the first is rendered,
  /// matching [CoreTextField.errorTextList]'s icon + red text treatment.
  final List<String>? errorTextList;

  const UnderlineTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hintText,
    this.keyboardType,
    this.prefix,
    this.suffix,
    this.labelTrailing,
    this.trailingAction,
    this.focusNode,
    this.errorTextList,
  });

  @override
  State<UnderlineTextField> createState() => _UnderlineTextFieldState();
}

class _UnderlineTextFieldState extends State<UnderlineTextField> {
  late final FocusNode _focusNode;

  /// Whether this state created [_focusNode] itself (true) or a caller
  /// passed one in via [UnderlineTextField.focusNode] (false) — only an
  /// internally created node is this state's to dispose.
  bool get _ownsFocusNode => widget.focusNode == null;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
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
    if (_ownsFocusNode) {
      _focusNode.dispose();
    }
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
      decoration: InputDecoration(
        border: InputBorder.none,
        hintText: widget.hintText,
        hintStyle: textTheme.bodyLargeRegular.copyWith(
          color: colorTheme.textDisable,
        ),
        // Vertical padding, not zero: without it the field's own
        // interactive area is only as tall as its text line (~24px), short
        // of Android's 48dp minimum tap target.
        contentPadding: const EdgeInsets.symmetric(
          vertical: CoreSpacing.space3,
        ),
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                widget.label,
                style: textTheme.bodySmallRegular.copyWith(
                  color: colorTheme.textBody,
                ),
              ),
              if (widget.labelTrailing != null) ...[
                const SizedBox(width: CoreSpacing.space2),
                widget.labelTrailing!,
              ],
            ],
          ),
          const SizedBox(height: CoreSpacing.space1),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (widget.prefix != null) ...[
                widget.prefix!,
                const SizedBox(width: CoreSpacing.space2),
              ],
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
              if (widget.trailingAction != null) ...[
                const SizedBox(width: CoreSpacing.space2),
                widget.trailingAction!,
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
