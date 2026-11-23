import 'package:construculator/features/estimation/presentation/bloc/material_cost_form_bloc/material_cost_form_bloc.dart';
import 'package:construculator/features/estimation/presentation/widgets/add_to_estimate_footer.dart';
import 'package:construculator/features/estimation/presentation/widgets/add_to_estimate_panel.dart';
import 'package:construculator/features/estimation/presentation/widgets/confirmation_dialog.dart';
import 'package:construculator/features/estimation/presentation/widgets/number_pad_session.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:construculator/libraries/formatting/display_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// The material sheet's "Adds to this estimate" card and "Add to estimate"
/// button, driven by [MaterialCostFormBloc].
///
/// The button only sends [MaterialCostFormSubmitted]; the bloc validates. A
/// successful add closes the sheet. A failed save on the phone keeps the sheet
/// open and says so in a line above the button, which goes away while the next
/// save runs.
///
/// For a line already on the estimate the button reads "Save this line", the
/// card shows the change to the estimate total, and a red "Delete this line"
/// button asks first, then deletes the line.
///
/// While the app's own number pad is up on a number field, [numberPad] is
/// set and the pad takes the button's place: its confirm key submits exactly
/// like the button, and its put-back key restores the value the field held
/// when the pad opened and drops focus, which closes the pad.
class MaterialAddToEstimateFooter extends StatelessWidget {
  /// The estimate the line is added to.
  final String estimateId;

  /// The estimate's name, shown on the card.
  final String estimateName;

  /// The estimate's running total before this line is added, or null while it
  /// is not known.
  final double? estimateTotal;

  /// The field the number pad is typing into, or null while the pad is down.
  final NumberPadSession? numberPad;

  /// Which parts to draw. Only a part with the button or pad closes the sheet
  /// after a successful add, so a split footer closes it once.
  final AddToEstimateFooterPart part;

  const MaterialAddToEstimateFooter({
    super.key,
    required this.estimateId,
    required this.estimateName,
    required this.estimateTotal,
    this.numberPad,
    this.part = AddToEstimateFooterPart.all,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final session = numberPad;
    void submit() => context.read<MaterialCostFormBloc>().add(
      MaterialCostFormSubmitted(estimateId: estimateId),
    );
    return BlocConsumer<MaterialCostFormBloc, MaterialCostFormState>(
      listenWhen: (_, _) => part != AddToEstimateFooterPart.panel,
      listener: (context, state) {
        switch (state) {
          case MaterialCostFormSuccess():
          case MaterialCostFormDeleted():
            Navigator.of(context).pop();
          case MaterialCostFormInitial():
          case MaterialCostFormEditing():
          case MaterialCostFormSubmitting():
          case MaterialCostFormFailure():
            break;
        }
      },
      builder: (context, state) {
        final data = state.data;
        final blocker = data.blocker;
        final isSubmitting =
            state is MaterialCostFormSubmitting ||
            state is MaterialCostFormSuccess ||
            state is MaterialCostFormDeleted;
        // The fields are read-only while the line saves; the pad's keys
        // never reach the platform input, so they are locked here instead.
        VoidCallback unlessSaving(VoidCallback edit) =>
            isSubmitting ? () {} : edit;
        return AddToEstimateFooter(
          lineTotal: data.lineTotal,
          charge: switch (data.wastePercent) {
            final waste? => AddToEstimateCharge(
              label: l10n.addsToEstimateIncludesWaste(
                DisplayFormatter.formatPercent(waste),
              ),
              amount: data.wasteAmount,
            ),
            null => null,
          },
          estimateName: estimateName,
          estimateTotal: estimateTotal,
          isEditingExistingLine: data.isEditingExistingLine,
          changeInEstimateTotal: data.changeInEstimateTotal,
          hasUnsavedChanges: data.hasUnsavedChanges,
          deleteFailed: switch (state) {
            MaterialCostFormFailure(whileDeleting: true) => true,
            _ => false,
          },
          onDelete: data.isEditingExistingLine
              ? () => _confirmDelete(context, data.lineName)
              : null,
          block: blocker == null ? null : _blockFor(data, blocker, l10n),
          isBusy: isSubmitting,
          errorMessage: switch (state) {
            MaterialCostFormFailure(whileDeleting: true) =>
              l10n.deleteLineFailedError,
            MaterialCostFormFailure() when data.isEditingExistingLine =>
              l10n.saveLineFailedError,
            MaterialCostFormFailure() => l10n.addToEstimateFailedError,
            _ => null,
          },
          onAdd: submit,
          part: part,
          keypad: session == null
              ? null
              : CoreNumberKeypad(
                  onDigitPressed: (digit) =>
                      unlessSaving(() => session.typeDigit(digit))(),
                  onDecimalPressed: unlessSaving(session.typeDecimal),
                  onBackspacePressed: unlessSaving(session.backspace),
                  onClearPressed: unlessSaving(() {
                    session.putBack();
                    FocusManager.instance.primaryFocus?.unfocus();
                  }),
                  onConfirmPressed: submit,
                  clearLabel: session.putBackLabel,
                  confirmLabel: data.isEditingExistingLine
                      ? l10n.saveThisLineButton
                      : l10n.addToEstimateButton,
                  isConfirmEnabled: blocker == null && !isSubmitting,
                ),
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, String itemName) async {
    final l10n = context.l10n;
    final bloc = context.read<MaterialCostFormBloc>();
    final keepLine = await ConfirmationDialog.show(
      context,
      title: l10n.deleteLineDialogTitle,
      body: TextSpan(text: l10n.deleteLineDialogBody(itemName, estimateName)),
      secondaryLabel: l10n.deleteLineYesDeleteButton,
      primaryLabel: l10n.deleteLineNoKeepButton,
      isSecondaryDestructive: true,
    );
    if (keepLine == false) bloc.add(const MaterialCostDeleteRequested());
  }

  AddToEstimateBlock _blockFor(
    MaterialCostFormData data,
    MaterialFormBlocker blocker,
    AppLocalizations l10n,
  ) {
    final isMissing = blocker.kind == MaterialBlockerKind.missing;
    return switch (blocker.field) {
      MaterialFormField.itemName => AddToEstimateBlock(
        note: l10n.addsToEstimateNeedsNameNote,
        buttonLabel: l10n.enterMaterialNameToContinueButton,
      ),
      MaterialFormField.quantity => AddToEstimateBlock(
        note: isMissing
            ? l10n.addsToEstimateNeedsQuantityNote
            : data.fieldErrors[MaterialFormField.quantity] ==
                  MaterialFieldError.quantityNotPositive
            ? l10n.addsToEstimateNeedsQuantityAboveZeroNote
            : l10n.addsToEstimateInvalidQuantityNote,
        buttonLabel: isMissing
            ? l10n.enterQuantityToContinueButton
            : l10n.fixQuantityToContinueButton,
      ),
      MaterialFormField.unit => AddToEstimateBlock(
        note: l10n.addsToEstimateNeedsUnitNote,
        buttonLabel: l10n.enterUnitToContinueButton,
      ),
      MaterialFormField.rate => AddToEstimateBlock(
        note: isMissing
            ? l10n.addsToEstimateNeedsRateNote
            : l10n.addsToEstimateInvalidRateNote,
        buttonLabel: isMissing
            ? l10n.enterRateToContinueButton
            : l10n.fixRateToContinueButton,
      ),
    };
  }
}
