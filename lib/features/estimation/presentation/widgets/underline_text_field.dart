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

  /// Placeholder text shown in the value row, in the same disabled
  /// weight/color as the empty-value text itself (`bodyLargeRegular` /
  /// `textDisable`), while the controller is empty (e.g. the equipment name
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

  /// Hides [suffix] while the field is empty, so a unit word such as "days"
  /// does not repeat the placeholder text.
  final bool hideSuffixWhenEmpty;

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
  ///
  /// Nothing is shown while the user is still typing in the field for the
  /// first time. The error first shows when the field loses focus, and from
  /// then on it follows this list on every key, so it goes away as soon as
  /// the value is valid.
  final List<String>? errorTextList;

  const UnderlineTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hintText,
    this.keyboardType,
    this.prefix,
    this.suffix,
    this.hideSuffixWhenEmpty = false,
    this.labelTrailing,
    this.trailingAction,
    this.focusNode,
    this.errorTextList,
  });

  @override
  State<UnderlineTextField> createState() => _UnderlineTextFieldState();
}

const double _labelToValueGap = 3;
const double _valueToRuleGap = 10;

class _UnderlineTextFieldState extends State<UnderlineTextField> {
  late final FocusNode _focusNode;
  bool _wasFocused = false;
  bool _touched = false;

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

  void _onFocusChange() {
    final hasFocus = _focusNode.hasFocus;
    if (_wasFocused && !hasFocus) _touched = true;
    _wasFocused = hasFocus;
    setState(() {});
  }

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
    final prefix = widget.prefix;
    final labelTrailing = widget.labelTrailing;
    final trailingAction = widget.trailingAction;
    final errorTextList = widget.errorTextList;
    final visibleErrorText =
        _touched && errorTextList != null && errorTextList.isNotEmpty
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
          : textTheme.bodyLargeRegular.copyWith(color: colorTheme.textHeadline),
      decoration: InputDecoration(
        border: InputBorder.none,
        isDense: true,
        contentPadding: EdgeInsets.zero,
        hintText: suffix != null && !isEmpty ? null : widget.hintText,
        hintStyle: textTheme.bodyLargeRegular.copyWith(
          color: colorTheme.textDisable,
        ),
      ),
    );

    return MergeSemantics(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _focusNode.requestFocus,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  widget.label,
                  style: textTheme.bodySmallRegular.copyWith(
                    color: hasError
                        ? colorTheme.statusError
                        : colorTheme.textBody,
                  ),
                ),
                if (labelTrailing != null) ...[
                  const SizedBox(width: CoreSpacing.space2),
                  labelTrailing,
                ],
              ],
            ),
            const SizedBox(height: _labelToValueGap),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (prefix != null) ...[
                  prefix,
                  const SizedBox(width: CoreSpacing.space2),
                ],
                if (suffix != null)
                  Flexible(child: IntrinsicWidth(child: textField))
                else
                  Expanded(child: textField),
                if (suffix != null &&
                    !(widget.hideSuffixWhenEmpty && isEmpty)) ...[
                  const SizedBox(width: CoreSpacing.space1),
                  suffix,
                ],
                if (trailingAction != null) ...[
                  const SizedBox(width: CoreSpacing.space2),
                  trailingAction,
                ],
              ],
            ),
            const SizedBox(height: _valueToRuleGap),
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
      ),
    );
  }
}
