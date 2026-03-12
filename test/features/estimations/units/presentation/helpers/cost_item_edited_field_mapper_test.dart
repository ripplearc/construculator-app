import 'package:construculator/features/estimation/presentation/helpers/cost_item_edited_field_mapper.dart';
import 'package:construculator/l10n/generated/app_localizations_en.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CostItemEditedFieldMapper', () {
    // ignore: no_direct_instantiation
    final l10n = AppLocalizationsEn();

    test('maps edited fields into localized field changes', () {
      const activityDetails = {
        'editedFields': {
          'quantity': {'oldValue': 10, 'newValue': 15},
          'unit_price': {'oldValue': 20, 'newValue': 25},
        },
      };

      final changes = CostItemEditedFieldMapper.fromActivityDetails(
        l10n,
        activityDetails,
      );

      expect(changes, hasLength(2));

      final quantityChange = changes.firstWhere(
        (c) => c.fieldLabel == l10n.activityEditedFieldQuantity,
      );
      expect(
        quantityChange.fromValue,
        l10n.activityEditedFieldValueQuantity('10'),
      );
      expect(
        quantityChange.toValue,
        l10n.activityEditedFieldValueQuantity('15'),
      );

      final unitPriceChange = changes.firstWhere(
        (c) => c.fieldLabel == l10n.activityEditedFieldUnitPrice,
      );
      expect(
        unitPriceChange.fromValue,
        l10n.activityEditedFieldValueCurrency('20.00'),
      );
      expect(
        unitPriceChange.toValue,
        l10n.activityEditedFieldValueCurrency('25.00'),
      );
    });

    test('returns empty list when editedFields is missing', () {
      const activityDetails = {'itemName': 'Concrete'};

      final changes = CostItemEditedFieldMapper.fromActivityDetails(
        l10n,
        activityDetails,
      );

      expect(changes, isEmpty);
    });

    test('returns empty list when editedFields is not a map', () {
      const activityDetails = {
        'editedFields': ['invalid'],
      };

      final changes = CostItemEditedFieldMapper.fromActivityDetails(
        l10n,
        activityDetails,
      );

      expect(changes, isEmpty);
    });

    test('skips entries with invalid shape', () {
      const activityDetails = {
        'editedFields': {
          1: {'oldValue': 1, 'newValue': 2},
          'quantity': 'invalid',
          'labor_days': {'oldValue': 1, 'newValue': 2},
        },
      };

      final changes = CostItemEditedFieldMapper.fromActivityDetails(
        l10n,
        activityDetails,
      );

      expect(changes, hasLength(1));
      expect(changes.first.fieldLabel, l10n.activityEditedFieldLaborDays);
      expect(changes.first.fromValue, l10n.activityEditedFieldValueDays('1'));
      expect(changes.first.toValue, l10n.activityEditedFieldValueDays('2'));
    });

    test('skips entries where both values are null', () {
      const activityDetails = {
        'editedFields': {
          'description': {'oldValue': null, 'newValue': null},
          'brand': {'oldValue': null, 'newValue': 'Acme'},
        },
      };

      final changes = CostItemEditedFieldMapper.fromActivityDetails(
        l10n,
        activityDetails,
      );

      expect(changes, hasLength(1));
      expect(changes.first.fieldLabel, l10n.activityEditedFieldBrand);
      expect(changes.first.fromValue, l10n.activityEditedFieldEmptyValue);
      expect(changes.first.toValue, 'Acme');
    });
  });
}
