import 'package:construculator/l10n/generated/app_localizations.dart';

class CostItemEditedFieldFormatter {
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
