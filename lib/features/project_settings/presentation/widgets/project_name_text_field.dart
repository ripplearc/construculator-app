import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// A text field for entering and validating a project name.
class ProjectNameTextField extends StatefulWidget {
  const ProjectNameTextField({
    super.key,
    required this.controller,
    this.onValidationChanged,
    this.onDirtyChanged,
    this.enabled = true,
  });

  /// Controls the text being edited.
  final TextEditingController controller;

  /// Called whenever the validity of the current text changes.
  final void Function(bool isValid)? onValidationChanged;

  /// Called once when the field is first edited; never called again.
  final void Function(bool isDirty)? onDirtyChanged;

  /// Whether the field accepts user input.
  final bool enabled;

  /// Maximum allowed character count for a project name.
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _validate();
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final wasDirty = _isDirty;
    if (!wasDirty) _isDirty = true;
    _validate();
    if (!wasDirty) widget.onDirtyChanged?.call(true);
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
    final borderRadius = BorderRadius.circular(CoreSpacing.space1);

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
          borderRadius: borderRadius,
          borderSide: BorderSide(color: colorTheme.lineDarkOutline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: colorTheme.lineDarkOutline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: colorTheme.textDark),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: colorTheme.statusError),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: colorTheme.statusError),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: borderRadius,
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
