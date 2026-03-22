import 'package:construculator/features/estimation/presentation/helpers/cost_item_edited_field_formatter.dart';
import 'package:construculator/l10n/generated/app_localizations_en.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CostItemEditedFieldFormatter', () {
    final l10n = AppLocalizationsEn();

    group('labelFor', () {
      final knownFieldMappings = {
        'item_type': l10n.activityEditedFieldItemType,
        'item_name': l10n.activityEditedFieldItemName,
        'unit_price': l10n.activityEditedFieldUnitPrice,
        'quantity': l10n.activityEditedFieldQuantity,
        'unit_measurement': l10n.activityEditedFieldUnitMeasurement,
        'calculation': l10n.activityEditedFieldCalculation,
        'item_total_cost': l10n.activityEditedFieldItemTotalCost,
        'currency': l10n.activityEditedFieldCurrency,
        'brand': l10n.activityEditedFieldBrand,
        'product_link': l10n.activityEditedFieldProductLink,
        'description': l10n.activityEditedFieldDescription,
        'labor_calc_method': l10n.activityEditedFieldLaborCalcMethod,
        'labor_days': l10n.activityEditedFieldLaborDays,
        'labor_hours': l10n.activityEditedFieldLaborHours,
        'labor_unit_type': l10n.activityEditedFieldLaborUnitType,
        'labor_unit_value': l10n.activityEditedFieldLaborUnitValue,
        'crew_size': l10n.activityEditedFieldCrewSize,
      };

      for (final entry in knownFieldMappings.entries) {
        test('returns localized label for ${entry.key}', () {
          final label = CostItemEditedFieldFormatter.labelFor(l10n, entry.key);
          expect(label, entry.value);
        });
      }

      test('humanizes unknown field name', () {
        final label = CostItemEditedFieldFormatter.labelFor(
          l10n,
          'custom_field_name',
        );

        expect(label, 'Custom Field Name');
      });
    });

    group('valueFor', () {
      test('formats quantity with localized template', () {
        final value = CostItemEditedFieldFormatter.valueFor(
          l10n,
          'quantity',
          12,
        );

        expect(value, l10n.activityEditedFieldValueQuantity('12'));
      });

      test('formats integer currency with two decimal places', () {
        final value = CostItemEditedFieldFormatter.valueFor(
          l10n,
          'unit_price',
          125,
        );

        expect(value, l10n.activityEditedFieldValueCurrency('125.00'));
      });

      test('formats non-whole double currency with two decimal places', () {
        final value = CostItemEditedFieldFormatter.valueFor(
          l10n,
          'unit_price',
          10.5,
        );

        expect(value, l10n.activityEditedFieldValueCurrency('10.50'));
      });

      test('formats whole double currency with two decimal places', () {
        final value = CostItemEditedFieldFormatter.valueFor(
          l10n,
          'item_total_cost',
          10.0,
        );

        expect(value, l10n.activityEditedFieldValueCurrency('10.00'));
      });

      test('returns empty placeholder for null currency value', () {
        final value = CostItemEditedFieldFormatter.valueFor(
          l10n,
          'unit_price',
          null,
        );

        expect(
          value,
          l10n.activityEditedFieldValueCurrency(
            l10n.activityEditedFieldEmptyValue,
          ),
        );
      });

      test('returns empty placeholder for blank string currency value', () {
        final value = CostItemEditedFieldFormatter.valueFor(
          l10n,
          'unit_price',
          '   ',
        );

        expect(
          value,
          l10n.activityEditedFieldValueCurrency(
            l10n.activityEditedFieldEmptyValue,
          ),
        );
      });

      test('formats labor days with localized template', () {
        final value = CostItemEditedFieldFormatter.valueFor(
          l10n,
          'labor_days',
          3,
        );

        expect(value, l10n.activityEditedFieldValueDays('3'));
      });

      test('formats labor hours with localized template', () {
        final value = CostItemEditedFieldFormatter.valueFor(
          l10n,
          'labor_hours',
          8,
        );

        expect(value, l10n.activityEditedFieldValueHours('8'));
      });

      test('formats crew size with localized template', () {
        final value = CostItemEditedFieldFormatter.valueFor(
          l10n,
          'crew_size',
          4,
        );

        expect(value, l10n.activityEditedFieldValueCrew('4'));
      });

      test('returns localized empty placeholder for null value', () {
        final value = CostItemEditedFieldFormatter.valueFor(
          l10n,
          'description',
          null,
        );

        expect(value, l10n.activityEditedFieldEmptyValue);
      });

      test('returns localized empty placeholder for blank string value', () {
        final value = CostItemEditedFieldFormatter.valueFor(
          l10n,
          'description',
          '   ',
        );

        expect(value, l10n.activityEditedFieldEmptyValue);
      });

      test('normalizes whole-number double values', () {
        final value = CostItemEditedFieldFormatter.valueFor(
          l10n,
          'description',
          10.0,
        );

        expect(value, '10');
      });
    });
  });
}
