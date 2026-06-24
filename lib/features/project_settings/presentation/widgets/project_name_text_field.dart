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

  @override
  void didUpdateWidget(covariant ProjectNameTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onTextChanged);
      widget.controller.addListener(_onTextChanged);
      _validate();
    }
  }

  void _onTextChanged() {
    final wasDirty = _isDirty;
    _validate(markDirty: !wasDirty);
    if (!wasDirty) widget.onDirtyChanged?.call(true);
  }

  void _validate({bool markDirty = false}) {
    final l10n = context.l10n;
    final trimmed = widget.controller.text.trim();
    final errors = <String>[];

    if (trimmed.isEmpty) {
      errors.add(l10n.projectNameRequiredError);
    } else if (trimmed.length > ProjectNameTextField.maxLength) {
      errors.add(l10n.projectNameTooLongError);
    }

    setState(() {
      if (markDirty) _isDirty = true;
      _errors = errors;
    });
    widget.onValidationChanged?.call(errors.isEmpty);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return CoreTextField(
      controller: widget.controller,
      label: l10n.projectNameLabel,
      hintText: l10n.projectNameHintText,
      enabled: widget.enabled,
      errorTextList: (_isDirty && _errors.isNotEmpty) ? _errors : null,
    );
  }
}
