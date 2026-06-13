import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

class ProjectNameTextField extends StatefulWidget {
  const ProjectNameTextField({
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
  State<ProjectNameTextField> createState() => _ProjectNameTextFieldState();
}

class _ProjectNameTextFieldState extends State<ProjectNameTextField> {
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
    final trimmed = widget.controller.text.trim();
    final errors = <String>[];

    if (trimmed.isEmpty) {
      errors.add(l10n.projectNameRequiredError);
    } else if (trimmed.length > ProjectNameTextField.maxLength) {
      errors.add(l10n.projectNameTooLongError);
    }

    setState(() => _errors = errors);
    widget.onValidationChanged?.call(errors.isEmpty);
  }

  @override
  Widget build(BuildContext context) {
    final colorTheme = context.colorTheme;
    final textTheme = context.textTheme;
    final l10n = context.l10n;
    final hasError = _isDirty && _errors.isNotEmpty;

    return TextFormField(
      controller: widget.controller,
      enabled: widget.enabled,
      style: textTheme.bodyLargeRegular.copyWith(
        color: widget.enabled ? colorTheme.textDark : colorTheme.textDisable,
      ),
      decoration: InputDecoration(
        labelText: l10n.projectNameLabel,
        labelStyle: textTheme.bodyLargeRegular.copyWith(
          color: widget.enabled ? colorTheme.textHeadline : colorTheme.textDisable,
        ),
        floatingLabelStyle: textTheme.bodyLargeRegular.copyWith(
          color: hasError
              ? colorTheme.textError
              : (widget.enabled ? colorTheme.textDark : colorTheme.textDisable),
        ),
        hintText: l10n.projectNameHintText,
        hintStyle: textTheme.bodyLargeRegular.copyWith(
          color: colorTheme.textBody,
        ),
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
          borderSide: BorderSide(color: colorTheme.lineDarkOutline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CoreSpacing.space1),
          borderSide: BorderSide(color: colorTheme.lineDarkOutline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CoreSpacing.space1),
          borderSide: BorderSide(color: colorTheme.textDark),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CoreSpacing.space1),
          borderSide: BorderSide(color: colorTheme.statusError),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CoreSpacing.space1),
          borderSide: BorderSide(color: colorTheme.statusError),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CoreSpacing.space1),
          borderSide: BorderSide(color: colorTheme.lineMid),
        ),
        error: hasError
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _errors
                    .map(
                      (e) => Row(
                        children: [
                          CoreIconWidget(
                            icon: CoreIcons.error,
                            size: 16,
                            color: colorTheme.iconRed,
                          ),
                          const SizedBox(width: CoreSpacing.space1),
                          Expanded(
                            child: Text(
                              e,
                              style: textTheme.bodySmallRegular.copyWith(
                                color: colorTheme.textError,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                    .toList(),
              )
            : null,
      ),
    );
  }
}
