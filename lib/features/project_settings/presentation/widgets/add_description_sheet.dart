import 'package:construculator/features/project_settings/presentation/widgets/project_description_text_field.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

class AddDescriptionSheet extends StatefulWidget {
  const AddDescriptionSheet({
    super.key,
    this.initialDescription,
    required this.onAdd,
  });

  final String? initialDescription;
  final void Function(String description) onAdd;

  static Future<String?> show(
    BuildContext context, {
    String? initialDescription,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colorTheme.transparent,
      builder: (_) => AddDescriptionSheet(
        initialDescription: initialDescription,
        onAdd: (description) => Navigator.of(context).pop(description),
      ),
    );
  }

  @override
  State<AddDescriptionSheet> createState() => _AddDescriptionSheetState();
}

class _AddDescriptionSheetState extends State<AddDescriptionSheet> {
  late final TextEditingController _controller;
  bool _isValid = true;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialDescription);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleAdd() {
    widget.onAdd(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final colorTheme = context.colorTheme;
    final textTheme = context.textTheme;
    final l10n = context.l10n;

    return Container(
      decoration: BoxDecoration(
        color: colorTheme.pageBackground,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(CoreSpacing.space7),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + CoreSpacing.space4,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: CoreSpacing.space4),
            child: Center(
              child: Container(
                width: CoreSpacing.space8,
                height: CoreSpacing.space1,
                decoration: BoxDecoration(
                  color: colorTheme.lineDarkOutline,
                  borderRadius: BorderRadius.circular(CoreSpacing.space1),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: CoreSpacing.space3,
              horizontal: CoreSpacing.space4,
            ),
            child: Text(
              l10n.addProjectDescriptionTitle,
              style: textTheme.titleMediumSemiBold.copyWith(
                color: colorTheme.textHeadline,
              ),
            ),
          ),
          const SizedBox(height: CoreSpacing.space3),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: CoreSpacing.space4),
            child: ProjectDescriptionTextField(
              controller: _controller,
              onValidationChanged: (isValid) {
                setState(() => _isValid = isValid);
              },
            ),
          ),
          const SizedBox(height: CoreSpacing.space6),
          Container(
            decoration: BoxDecoration(
              boxShadow: CoreShadows.sticky,
              color: colorTheme.pageBackground,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: CoreSpacing.space4,
              vertical: CoreSpacing.space3,
            ),
            child: CoreButton(
              onPressed: _isValid ? _handleAdd : null,
              isDisabled: !_isValid,
              label: l10n.addDescriptionButton,
              variant: CoreButtonVariant.primary,
            ),
          ),
        ],
      ),
    );
  }
}
