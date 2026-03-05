import 'package:construculator/features/estimation/presentation/helpers/cost_item_edited_field_formatter.dart';
import 'package:construculator/l10n/generated/app_localizations_en.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CostItemEditedFieldFormatter', () {
    // ignore: no_direct_instantiation
    final l10n = AppLocalizationsEn();

    group('labelFor', () {
      test('returns localized label for known field', () {
        final label = CostItemEditedFieldFormatter.labelFor(l10n, 'quantity');

        expect(label, l10n.activityEditedFieldQuantity);
      });

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
