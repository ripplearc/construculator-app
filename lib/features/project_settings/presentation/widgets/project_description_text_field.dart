import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

class ProjectDescriptionTextField extends StatefulWidget {
  const ProjectDescriptionTextField({
    super.key,
    required this.controller,
    this.onValidationChanged,
    this.onDirtyChanged,
    this.enabled = true,
  });

  final TextEditingController controller;
  final void Function(bool isValid)? onValidationChanged;
  final void Function(bool isDirty)? onDirtyChanged;
  final bool enabled;

  static const int maxLength = 100;

  @override
  State<ProjectDescriptionTextField> createState() =>
      _ProjectDescriptionTextFieldState();
}

class _ProjectDescriptionTextFieldState
    extends State<ProjectDescriptionTextField> {
  bool _isDirty = false;
  List<String> _errors = [];

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    if (!_isDirty) {
      setState(() => _isDirty = true);
      widget.onDirtyChanged?.call(true);
    }
    _validate();
  }

  void _validate() {
    final l10n = context.l10n;
    final errors = <String>[];

    if (widget.controller.text.length > ProjectDescriptionTextField.maxLength) {
      errors.add(l10n.projectDescriptionTooLongError);
    }

    setState(() => _errors = errors);
    widget.onValidationChanged?.call(errors.isEmpty);
  }

  @override
  Widget build(BuildContext context) {
    final colorTheme = context.colorTheme;
    final textTheme = context.textTheme;
    final l10n = context.l10n;
    final charCount = widget.controller.text.length;
    final hasError = _isDirty && _errors.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextFormField(
          controller: widget.controller,
          enabled: widget.enabled,
          minLines: 3,
          maxLines: null,
          keyboardType: TextInputType.multiline,
          style: textTheme.bodyLargeRegular.copyWith(
            color: widget.enabled ? colorTheme.textDark : colorTheme.textDisable,
          ),
          decoration: InputDecoration(
            labelText: l10n.projectDescriptionLabel,
            labelStyle: textTheme.bodyLargeRegular.copyWith(
              color: widget.enabled ? colorTheme.textHeadline : colorTheme.textDisable,
            ),
            floatingLabelStyle: textTheme.bodyLargeRegular.copyWith(
              color: hasError
                  ? colorTheme.textError
                  : (widget.enabled ? colorTheme.textDark : colorTheme.textDisable),
            ),
            hintText: l10n.projectDescriptionHintText,
            hintStyle: textTheme.bodyLargeRegular.copyWith(
              color: colorTheme.textBody,
            ),
            alignLabelWithHint: true,
            filled: true,
            fillColor: widget.enabled
                ? colorTheme.pageBackground
                : colorTheme.backgroundGrayMid,
            contentPadding: const EdgeInsets.symmetric(
              vertical: CoreSpacing.space3,
              horizontal: CoreSpacing.space4,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(CoreSpacing.space1),
              borderSide: BorderSide(
                color: hasError ? colorTheme.statusError : colorTheme.lineDarkOutline,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(CoreSpacing.space1),
              borderSide: BorderSide(
                color: hasError ? colorTheme.statusError : colorTheme.lineDarkOutline,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(CoreSpacing.space1),
              borderSide: BorderSide(
                color: hasError ? colorTheme.statusError : colorTheme.textDark,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(CoreSpacing.space1),
              borderSide: BorderSide(color: colorTheme.lineMid),
            ),
          ),
        ),
        const SizedBox(height: CoreSpacing.space1),
        Row(
          children: [
            if (hasError)
              Expanded(
                child: Text(
                  _errors.first,
                  style: textTheme.bodySmallRegular.copyWith(
                    color: colorTheme.textError,
                  ),
                ),
              )
            else
              const Spacer(),
            Text(
              '$charCount/${ProjectDescriptionTextField.maxLength}',
              style: textTheme.bodySmallRegular.copyWith(
                color: hasError ? colorTheme.textError : colorTheme.textBody,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
