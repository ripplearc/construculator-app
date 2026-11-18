import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/presentation/bloc/your_rates_bloc/your_rates_bloc.dart';
import 'package:construculator/features/estimation/presentation/widgets/sheet_surface.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// The "Name this rate" dialog, shown when a rate is saved under a name that
/// Your rates already holds: it asks for a label, such as "Supplier A", and
/// saves the rate again under it (Decision 55). Reads the [YourRatesBloc]
/// above it and closes once the save ends; a label already used for that name
/// keeps it open with an error.
class EntryLabelDialog extends StatefulWidget {
  const EntryLabelDialog({super.key, required this.entry});

  /// The rate being saved, without a label yet.
  final YourRateEntry entry;

  @override
  State<EntryLabelDialog> createState() => _EntryLabelDialogState();
}

class _EntryLabelDialogState extends State<EntryLabelDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final label = _controller.text.trim();
    if (label.isEmpty) {
      setState(() => _error = context.l10n.yourRatesEntryLabelRequiredError);
      return;
    }
    context.read<YourRatesBloc>().add(
      YourRatesSaveRequested(widget.entry.copyWith(entryLabel: label)),
    );
  }

  void _handleSaveState(BuildContext context, YourRatesState state) {
    switch (state) {
      case YourRatesSaveLabelTaken():
        setState(() => _error = context.l10n.yourRatesEntryLabelTakenError);
      case YourRatesSaveSucceeded() ||
          YourRatesSaveFailed() ||
          YourRatesSaveNoCompany():
        Navigator.of(context).pop();
      case YourRatesSaving() ||
          YourRatesLoading() ||
          YourRatesRetrying() ||
          YourRatesLoaded() ||
          YourRatesSearchResults() ||
          YourRatesError() ||
          YourRatesSaveCollision():
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorTheme = context.colorTheme;
    final textTheme = context.textTheme;
    return BlocListener<YourRatesBloc, YourRatesState>(
      listener: _handleSaveState,
      child: Dialog(
        backgroundColor: sheetSurface(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CoreSpacing.space5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(CoreSpacing.space6),
          child: SizedBox(
            width: 340,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.yourRatesEntryLabelDialogTitle,
                  key: const Key('entry_label_dialog_title'),
                  style: textTheme.titleMediumSemiBold.copyWith(
                    color: colorTheme.textHeadline,
                  ),
                ),
                const SizedBox(height: CoreSpacing.space3),
                Text(
                  l10n.yourRatesEntryLabelDialogBody,
                  style: textTheme.bodyMediumRegular.copyWith(
                    color: colorTheme.textBody,
                  ),
                ),
                const SizedBox(height: CoreSpacing.space3),
                CoreTextField(
                  key: const Key('entry_label_field'),
                  hintText: l10n.yourRatesEntryLabelHint,
                  controller: _controller,
                  errorTextList: switch (_error) {
                    final error? => [error],
                    null => null,
                  },
                ),
                const SizedBox(height: CoreSpacing.space3),
                Row(
                  children: [
                    Expanded(
                      child: CoreButton(
                        key: const Key('entry_label_dialog_cancel_button'),
                        label: l10n.yourRatesEntryLabelCancel,
                        variant: CoreButtonVariant.secondary,
                        size: CoreButtonSize.medium,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(width: CoreSpacing.space3),
                    Expanded(
                      child: CoreButton(
                        key: const Key('entry_label_dialog_save_button'),
                        label: l10n.yourRatesEntryLabelSave,
                        variant: CoreButtonVariant.primary,
                        size: CoreButtonSize.medium,
                        onPressed: _submit,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
