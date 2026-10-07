import 'package:construculator/features/estimation/presentation/bloc/material_cost_form_bloc/material_cost_form_bloc.dart';
import 'package:construculator/features/estimation/presentation/widgets/add_to_estimate_footer.dart';
import 'package:construculator/features/estimation/presentation/widgets/add_to_estimate_panel.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The material sheet's "Adds to this estimate" card and "Add to estimate"
/// button, driven by [MaterialCostFormBloc].
///
/// The button only sends [MaterialCostFormSubmitted]; the bloc validates. A
/// successful add closes the sheet. A failed save keeps the sheet open and
/// says so in a line above the button, which goes away while the next save
/// runs.
class MaterialAddToEstimateFooter extends StatelessWidget {
  /// The estimate the line is added to.
  final String estimateId;

  /// That estimate's name and running total before this line is added.
  final String estimateName;
  final double estimateTotal;

  const MaterialAddToEstimateFooter({
    super.key,
    required this.estimateId,
    required this.estimateName,
    required this.estimateTotal,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocConsumer<MaterialCostFormBloc, MaterialCostFormState>(
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
        return AddToEstimateFooter(
          lineTotal: data.lineTotal,
          estimateName: estimateName,
          estimateTotal: estimateTotal,
          block: blocker == null ? null : _blockFor(data, blocker, l10n),
          isSubmitting:
              state is MaterialCostFormSubmitting ||
              state is MaterialCostFormSuccess,
          errorMessage: state is MaterialCostFormFailure
              ? l10n.addToEstimateFailedError
              : null,
          onAdd: () => context.read<MaterialCostFormBloc>().add(
            MaterialCostFormSubmitted(estimateId: estimateId),
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
