import 'package:construculator/features/estimation/presentation/helpers/cost_item_edited_field_formatter.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:equatable/equatable.dart';

class CostItemEditedFieldChange extends Equatable {
  final String fieldLabel;
  final String fromValue;
  final String toValue;

  const CostItemEditedFieldChange({
    required this.fieldLabel,
    required this.fromValue,
    required this.toValue,
  });

  @override
  List<Object?> get props => [fieldLabel, fromValue, toValue];
}

class CostItemEditedFieldMapper {
  static List<CostItemEditedFieldChange> fromActivityDetails(
    AppLocalizations l10n,
    Map<String, dynamic> activityDetails,
  ) {
    final editedFields = activityDetails['editedFields'];
    if (editedFields is! Map) {
      return [];
    }

    final changes = <CostItemEditedFieldChange>[];

    for (final entry in editedFields.entries) {
      final fieldName = entry.key;
      final fieldChange = entry.value;

      if (fieldName is! String || fieldChange is! Map) {
        continue;
      }

      final oldValue = fieldChange['oldValue'];
      final newValue = fieldChange['newValue'];
      if (oldValue == null && newValue == null) {
        continue;
      }

      changes.add(
        CostItemEditedFieldChange(
          fieldLabel: CostItemEditedFieldFormatter.labelFor(l10n, fieldName),
          fromValue: CostItemEditedFieldFormatter.valueFor(
            l10n,
            fieldName,
            oldValue,
          ),
          toValue: CostItemEditedFieldFormatter.valueFor(
            l10n,
            fieldName,
            newValue,
          ),
        ),
      );
    }

    return changes;
  }
}
