import 'package:construculator/features/estimation/presentation/bloc/equipment_cost_form_bloc/equipment_cost_form_bloc.dart';
import 'package:construculator/features/estimation/presentation/widgets/add_to_estimate_footer.dart';
import 'package:construculator/features/estimation/presentation/widgets/add_to_estimate_panel.dart';
import 'package:construculator/features/estimation/presentation/widgets/confirmation_dialog.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The equipment sheet's "Adds to this estimate" card and "Add to estimate"
/// button, driven by [EquipmentCostFormBloc].
///
/// The button only sends [EquipmentCostSubmittedEvent]; the bloc validates and
/// decides whether the outsized-fee question comes first. A successful add
/// closes the sheet. A failed save keeps the sheet open and says so in a line
/// above the button, which goes away while the next save runs.
class EquipmentAddToEstimateFooter extends StatelessWidget {
  /// The estimate the line is added to.
  final String estimateId;

  /// That estimate's name, shown on the card.
  final String estimateName;

  /// That estimate's running total before this line is added.
  final double estimateTotal;

  const EquipmentAddToEstimateFooter({
    super.key,
    required this.estimateId,
    required this.estimateName,
    required this.estimateTotal,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocConsumer<EquipmentCostFormBloc, EquipmentCostFormState>(
      listener: (context, state) {
        switch (state) {
          case EquipmentCostFormSuccess():
          case EquipmentCostFormDeleted():
            Navigator.of(context).pop();
          case EquipmentCostFormInitial():
          case EquipmentCostFormEditing():
          case EquipmentCostFormFailure():
          case EquipmentCostFormOutsizedFeeConfirm():
          case EquipmentCostFormSubmitting():
            break;
        }
      },
      builder: (context, state) {
        final data = state.formData;
        final blocker = data.submitBlocker;
        return AddToEstimateFooter(
          lineTotal: data.lineTotal,
          deliveryFee: data.deliveryFee,
          changeInEstimateTotal: data.changeInEstimateTotal,
          onDelete: data.isEditingExistingLine
              ? () => _confirmDelete(context, data.lineName)
              : null,
          estimateName: estimateName,
          estimateTotal: estimateTotal,
          block: blocker == null ? null : _blockFor(blocker, l10n),
          isSubmitting:
              state is EquipmentCostFormSubmitting ||
              state is EquipmentCostFormSuccess ||
              state is EquipmentCostFormDeleted,
          errorMessage: switch (state) {
            EquipmentCostFormFailure(whileDeleting: true) =>
              l10n.deleteLineFailedError,
            EquipmentCostFormFailure() when data.isEditingExistingLine =>
              l10n.saveLineFailedError,
            EquipmentCostFormFailure() => l10n.addToEstimateFailedError,
            _ => null,
          },
          onAdd: () => context.read<EquipmentCostFormBloc>().add(
            EquipmentCostSubmittedEvent(estimateId: estimateId),
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, String itemName) async {
    final l10n = context.l10n;
    final bloc = context.read<EquipmentCostFormBloc>();
    final keepLine = await ConfirmationDialog.show(
      context,
      title: l10n.deleteLineDialogTitle,
      body: TextSpan(text: l10n.deleteLineDialogBody(itemName, estimateName)),
      secondaryLabel: l10n.yesDeleteButton,
      primaryLabel: l10n.noKeepButton,
      isSecondaryDestructive: true,
    );
    if (keepLine == false) bloc.add(const EquipmentCostDeleteRequested());
  }

  AddToEstimateBlock _blockFor(
    EquipmentSubmitBlocker blocker,
    AppLocalizations l10n,
  ) => switch (blocker) {
    EquipmentSubmitBlocker.missingName => AddToEstimateBlock(
      note: l10n.addsToEstimateNeedsNameNote,
      buttonLabel: l10n.enterEquipmentNameToContinueButton,
    ),
    EquipmentSubmitBlocker.missingDuration => AddToEstimateBlock(
      note: l10n.addsToEstimateNeedsDurationNote,
      buttonLabel: l10n.enterDurationToContinueButton,
    ),
    EquipmentSubmitBlocker.durationNotAboveZero => AddToEstimateBlock(
      note: l10n.addsToEstimateNeedsDurationAboveZeroNote,
      buttonLabel: l10n.fixDurationToContinueButton,
    ),
    EquipmentSubmitBlocker.invalidDuration => AddToEstimateBlock(
      note: l10n.addsToEstimateInvalidDurationNote,
      buttonLabel: l10n.fixDurationToContinueButton,
    ),
    EquipmentSubmitBlocker.missingRate => AddToEstimateBlock(
      note: l10n.addsToEstimateNeedsRateNote,
      buttonLabel: l10n.enterRateToContinueButton,
    ),
    EquipmentSubmitBlocker.invalidRate => AddToEstimateBlock(
      note: l10n.addsToEstimateInvalidRateNote,
      buttonLabel: l10n.fixRateToContinueButton,
    ),
    EquipmentSubmitBlocker.missingAmount => AddToEstimateBlock(
      note: l10n.addsToEstimateNeedsAmountNote,
      buttonLabel: l10n.enterAmountToContinueButton,
    ),
    EquipmentSubmitBlocker.invalidAmount => AddToEstimateBlock(
      note: l10n.addsToEstimateInvalidAmountNote,
      buttonLabel: l10n.fixAmountToContinueButton,
    ),
  };
}
