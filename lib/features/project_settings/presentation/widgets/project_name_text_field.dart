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
    return CoreTextField(
      controller: widget.controller,
      label: context.l10n.projectNameLabel,
      hintText: context.l10n.projectNameHintText,
      enabled: widget.enabled,
      errorTextList: _isDirty && _errors.isNotEmpty ? _errors : null,
    );
  }
}
