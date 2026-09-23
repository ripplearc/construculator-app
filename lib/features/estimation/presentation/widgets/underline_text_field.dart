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

  /// Placeholder shown in the value's own text color/weight while the
  /// controller is empty (e.g. the Note field's "Add a note (optional)").
  /// Fields that don't pass this simply render nothing while empty, same as
  /// before this parameter existed.
  final String? hintText;

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
    this.keyboardType,
    this.hintText,
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
    final hasError = errorTextList != null && errorTextList.isNotEmpty;
    final isEmpty = widget.controller.text.isEmpty;
    final ruleColor = hasError
        ? colorTheme.statusError
        : _focusNode.hasFocus
        ? colorTheme.textHeadline
        : colorTheme.lineMid;
    final ruleHeight = _focusNode.hasFocus || hasError ? 1.5 : 1.0;

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
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  keyboardType: widget.keyboardType,
                  cursorColor: colorTheme.textHeadline,
                  style: isEmpty
                      ? textTheme.bodyLargeRegular.copyWith(
                          color: colorTheme.textDisable,
                        )
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
                    // interactive area is only as tall as its text line
                    // (~24px), short of Android's 48dp minimum tap target.
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: CoreSpacing.space3,
                    ),
                  ),
                ),
              ),
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
          if (errorTextList != null && errorTextList.isNotEmpty) ...[
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
                    errorTextList.first,
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
