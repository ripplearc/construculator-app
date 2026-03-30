import 'package:construculator/features/estimation/presentation/helpers/cost_item_edited_field_formatter.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:equatable/equatable.dart';

/// Represents a single field change in a cost item edit operation.
///
/// Immutable value object containing the field label, original value, and new value.
/// Extends [Equatable] to enable efficient comparison of field changes by value.
class CostItemEditedFieldChange extends Equatable {
  final String fieldLabel;
  final String fromValue;
  final String toValue;

  /// Creates a field change record.
  ///
  /// Parameters:
  ///   - [fieldLabel]: Localized field name to display
  ///   - [fromValue]: Formatted original value
  ///   - [toValue]: Formatted new value
  const CostItemEditedFieldChange({
    required this.fieldLabel,
    required this.fromValue,
    required this.toValue,
  });

  @override
  List<Object?> get props => [fieldLabel, fromValue, toValue];
}

/// Converts activity detail changes into formatted field change records.
///
/// Transforms raw edit data (with oldValue/newValue pairs) into a list of
/// [CostItemEditedFieldChange] objects with fully localized labels and formatted values.
class CostItemEditedFieldMapper {
  /// Extracts and formats field changes from activity details.
  ///
  /// Parses the 'editedFields' map from activity details and creates formatted
  /// change records. Automatically humanizes field labels and applies appropriate
  /// value formatting based on field type.
  ///
  /// Skips entries where:
  /// - Field names are not strings
  /// - Changes don't map to a map structure
  /// - Both oldValue and newValue are null
  ///
  /// Parameters:
  ///   - [l10n]: Localization instance for field labels and value formatting
  ///   - [activityDetails]: Activity metadata containing 'editedFields' map
  ///
  /// Returns: List of [CostItemEditedFieldChange] objects, empty if no valid changes
  ///
  /// Example:
  /// ```dart
  /// final details = {
  ///   'itemName': 'Concrete',
  ///   'editedFields': {
  ///     'quantity': {'oldValue': 10, 'newValue': 15},
  ///     'unit_price': {'oldValue': 20, 'newValue': 25},
  ///   },
  /// };
  /// final changes = CostItemEditedFieldMapper.fromActivityDetails(l10n, details);
  /// // Returns 2 formatted field changes
  /// ```
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
