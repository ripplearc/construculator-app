import 'package:construculator/features/estimation/presentation/bloc/material_cost_form_bloc/material_cost_form_bloc.dart';
import 'package:construculator/features/estimation/presentation/widgets/add_to_estimate_footer.dart';
import 'package:construculator/features/estimation/presentation/widgets/add_to_estimate_panel.dart';
import 'package:construculator/features/estimation/presentation/widgets/number_pad_session.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
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
/// While the app's own number pad is up on a number field, [numberPad] is
/// set and the pad takes the button's place: its confirm key submits exactly
/// like the button, and its put-back key restores the value the field held
/// when the pad opened and drops focus, which closes the pad.
class MaterialAddToEstimateFooter extends StatelessWidget {
  /// The estimate the line is added to.
  final String estimateId;

  /// The estimate's name, shown on the card.
  final String estimateName;

  /// The estimate's running total before this line is added.
  final double estimateTotal;

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
            state is MaterialCostFormSuccess;
        // The fields are read-only while the line saves; the pad's keys
        // never reach the platform input, so they are locked here instead.
        VoidCallback unlessSaving(VoidCallback edit) =>
            isSubmitting ? () {} : edit;
        return AddToEstimateFooter(
          lineTotal: data.lineTotal,
          estimateName: estimateName,
          estimateTotal: estimateTotal,
          block: blocker == null ? null : _blockFor(data, blocker, l10n),
          isBusy: isSubmitting,
          errorMessage: state is MaterialCostFormFailure
              ? l10n.addToEstimatePhoneSaveFailedError
              : null,
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
                  confirmLabel: l10n.addToEstimateButton,
                  isConfirmEnabled: blocker == null && !isSubmitting,
                ),
        );
      },
    );
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
