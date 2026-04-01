import 'package:construculator/l10n/generated/app_localizations.dart';

/// Formats cost item field names and values for activity log display.
///
/// Provides localized labels and formatted values for cost item fields,
/// handling special formatting for different field types (currencies, quantities,
/// labor values) with proper null and empty value handling.
///
/// Supports field types:
/// - Currency fields (unit_price, item_total_cost): formatted to 2 decimal places
/// - Quantity fields: displayed as-is with localization template
/// - Labor fields (labor_days, labor_hours, crew_size): with unit labels
/// - Other fields: humanized names or raw values
class CostItemEditedFieldFormatter {
  /// Gets the localized display label for a cost item field name.
  ///
  /// Maps internal field names to localized labels. Unknown field names are
  /// humanized (converting snake_case to Title Case).
  ///
  /// Parameters:
  ///   - [l10n]: Localization instance for retrieving field labels
  ///   - [fieldName]: Internal field name (e.g., 'unit_price', 'quantity')
  ///
  /// Returns: Localized field label or humanized field name
  ///
  /// Example:
  /// ```dart
  /// labelFor(l10n, 'unit_price') // Returns l10n.activityEditedFieldUnitPrice
  /// labelFor(l10n, 'custom_field') // Returns "Custom Field"
  /// ```
  static String labelFor(AppLocalizations l10n, String fieldName) {
    switch (fieldName) {
      case 'item_type':
        return l10n.activityEditedFieldItemType;
      case 'item_name':
        return l10n.activityEditedFieldItemName;
      case 'unit_price':
        return l10n.activityEditedFieldUnitPrice;
      case 'quantity':
        return l10n.activityEditedFieldQuantity;
      case 'unit_measurement':
        return l10n.activityEditedFieldUnitMeasurement;
      case 'calculation':
        return l10n.activityEditedFieldCalculation;
      case 'item_total_cost':
        return l10n.activityEditedFieldItemTotalCost;
      case 'currency':
        return l10n.activityEditedFieldCurrency;
      case 'brand':
        return l10n.activityEditedFieldBrand;
      case 'product_link':
        return l10n.activityEditedFieldProductLink;
      case 'description':
        return l10n.activityEditedFieldDescription;
      case 'labor_calc_method':
        return l10n.activityEditedFieldLaborCalcMethod;
      case 'labor_days':
        return l10n.activityEditedFieldLaborDays;
      case 'labor_hours':
        return l10n.activityEditedFieldLaborHours;
      case 'labor_unit_type':
        return l10n.activityEditedFieldLaborUnitType;
      case 'labor_unit_value':
        return l10n.activityEditedFieldLaborUnitValue;
      case 'crew_size':
        return l10n.activityEditedFieldCrewSize;
      default:
        return _humanizeFieldName(fieldName);
    }
  }

  /// Formats a cost item field value for display.
  ///
  /// Applies field-specific formatting (decimals for currency, humanized names
  /// for unknowns, etc.) and returns the value wrapped in a localized template
  /// where applicable. Handles null and empty values consistently.
  ///
  /// Parameters:
  ///   - [l10n]: Localization instance for value templates
  ///   - [fieldName]: Internal field name to determine formatting
  ///   - [value]: The value to format (can be String, int, double, or null)
  ///
  /// Returns: Formatted, localized value string suitable for display
  ///
  /// Example:
  /// ```dart
  /// valueFor(l10n, 'unit_price', 10.5) // Returns "10.50" in currency template
  /// valueFor(l10n, 'quantity', 5) // Returns "5" in quantity template
  /// valueFor(l10n, 'description', null) // Returns empty value placeholder
  /// ```
  static String valueFor(
    AppLocalizations l10n,
    String fieldName,
    dynamic value,
  ) {
    switch (fieldName) {
      case 'quantity':
        return l10n.activityEditedFieldValueQuantity(
          _stringifyValue(l10n, value),
        );
      case 'unit_price':
      case 'item_total_cost':
        return l10n.activityEditedFieldValueCurrency(
          _stringifyCurrencyValue(l10n, value),
        );
      case 'labor_days':
        return l10n.activityEditedFieldValueDays(_stringifyValue(l10n, value));
      case 'labor_hours':
        return l10n.activityEditedFieldValueHours(_stringifyValue(l10n, value));
      case 'crew_size':
        return l10n.activityEditedFieldValueCrew(_stringifyValue(l10n, value));
      default:
        return _stringifyValue(l10n, value);
    }
  }

  static String _stringifyCurrencyValue(AppLocalizations l10n, dynamic value) {
    if (value == null) {
      return l10n.activityEditedFieldEmptyValue;
    }

    if (value is double) {
      return value.toStringAsFixed(2);
    }

    if (value is int) {
      return value.toDouble().toStringAsFixed(2);
    }

    final valueAsString = value.toString().trim();
    if (valueAsString.isEmpty) {
      return l10n.activityEditedFieldEmptyValue;
    }

    return valueAsString;
  }

  static String _stringifyValue(AppLocalizations l10n, dynamic value) {
    if (value == null) {
      return l10n.activityEditedFieldEmptyValue;
    }

    if (value is double && value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    final valueAsString = value.toString().trim();
    if (valueAsString.isEmpty) {
      return l10n.activityEditedFieldEmptyValue;
    }

    return valueAsString;
  }

  static String _humanizeFieldName(String fieldName) {
    final parts = fieldName.split('_');
    if (parts.isEmpty) {
      return fieldName;
    }

    return parts
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }
}
