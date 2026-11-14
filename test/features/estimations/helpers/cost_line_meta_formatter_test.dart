import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/presentation/helpers/cost_line_meta_formatter.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'cost_line_test_items.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));

  String? metaText(CostItem item, AppLocalizations l10n) =>
      CostLineMetaFormatter.format(item, l10n)?.text;

  group('equipment', () {
    test('writes days, the daily rate and a priced delivery fee', () {
      expect(
        metaText(equipmentLine(), l10n),
        r'4 days · $145.00/day + $85.00 delivery',
      );
    });

    test('puts no delivery on the row when there is no fee', () {
      expect(
        metaText(equipmentLine(deliveryFee: null), l10n),
        r'4 days · $145.00/day',
      );
    });

    test('says 1 day, not 1 days', () {
      expect(
        metaText(equipmentLine(duration: 1, deliveryFee: null), l10n),
        r'1 day · $145.00/day',
      );
    });

    test('keeps a fractional number of days', () {
      expect(
        metaText(equipmentLine(duration: 2.5, deliveryFee: null), l10n),
        r'2.5 days · $145.00/day',
      );
    });

    test('shows a zero delivery fee as zero dollars', () {
      expect(
        metaText(equipmentLine(deliveryFee: const Money(amount: 0)), l10n),
        r'4 days · $145.00/day + $0.00 delivery',
      );
    });

    test('shows a job line as the amount and the fee, never a quantity', () {
      expect(
        metaText(
          equipmentLine(
            method: EquipmentPricingMethod.job,
            duration: null,
            dailyRate: null,
            jobAmount: const Money(amount: 520),
          ),
          l10n,
        ),
        r'$520.00 job + $85.00 delivery',
      );
    });

    test('shows nothing for a day line with no duration', () {
      expect(metaText(equipmentLine(duration: null), l10n), isNull);
    });
  });

  group('material', () {
    test('writes quantity, unit and the price per unit', () {
      expect(metaText(materialLine(), l10n), r'13.25 sheets · $14.50/sheet');
    });

    test('adds a thousands separator and keeps two decimals at most', () {
      expect(
        metaText(
          materialLine(quantity: 1234567.891, unit: Unit.kilograms),
          l10n,
        ),
        r'1,234,567.89 kilograms · $14.50/kilogram',
      );
    });

    test('says one sheet, not one sheets, and prices a single sheet', () {
      expect(
        metaText(materialLine(quantity: 1), l10n),
        r'1 sheet · $14.50/sheet',
      );
    });

    test('drops the decimals of a whole quantity', () {
      expect(
        metaText(
          materialLine(quantity: 3, unit: Unit.liters, unitPrice: 52),
          l10n,
        ),
        r'3 liters · $52.00/liter',
      );
    });
  });

  group('lead and tail', () {
    CostLineMeta? meta(CostItem item) =>
        CostLineMetaFormatter.format(item, l10n);

    test('a material line is led by the quantity and its price follows', () {
      final material = meta(materialLine())!;

      expect(material.lead, '13.25 sheets');
      expect(material.tail, r' · $14.50/sheet');
    });

    test('a day line is led by the days and the rate and fee follow', () {
      final day = meta(equipmentLine())!;

      expect(day.lead, '4 days');
      expect(day.tail, r' · $145.00/day + $85.00 delivery');
    });

    test('a job line is led by the amount and the word job follows', () {
      final job = meta(
        equipmentLine(
          method: EquipmentPricingMethod.job,
          duration: null,
          dailyRate: null,
          jobAmount: const Money(amount: 400),
          deliveryFee: null,
        ),
      )!;

      expect(job.lead, r'$400.00');
      expect(job.tail, ' job');
    });

    test('a labor line has the hours as lead and the rate as tail', () {
      final labor = meta(laborLine(calculation: const {'laborRate': 52}))!;

      expect(labor.lead, '10 h');
      expect(labor.tail, r' · $52.00/h');
    });

    test('a labor line with no rate has no tail', () {
      final labor = meta(laborLine())!;

      expect(labor.lead, '10 h');
      expect(labor.tail, isEmpty);
    });
  });

  group('labor', () {
    test('writes hours for a per-hour line', () {
      expect(metaText(laborLine(), l10n), '10 h');
    });

    test('keeps decimal hours', () {
      expect(
        metaText(laborLine(value: const LaborValue(laborHours: 10.5)), l10n),
        '10.5 h',
      );
    });

    test('writes zero hours as 0 h', () {
      expect(
        metaText(laborLine(value: const LaborValue(laborHours: 0)), l10n),
        '0 h',
      );
    });

    test('writes days for a per-day line', () {
      expect(
        metaText(
          laborLine(
            method: LaborCalculationMethodType.perDay,
            value: const LaborValue(laborDays: 2.5),
          ),
          l10n,
        ),
        '2.5 days',
      );
    });

    test('writes the rate after the hours for one person', () {
      expect(
        metaText(
          laborLine(
            value: const LaborValue(laborHours: 16),
            calculation: const {'laborRate': 52},
          ),
          l10n,
        ),
        r'16 h · $52.00/h',
      );
    });

    test('writes the crew size and the rate for a crew of three', () {
      expect(
        metaText(
          laborLine(
            value: const LaborValue(laborHours: 16),
            calculation: const {'laborRate': 52},
            crewSize: 3,
          ),
          l10n,
        ),
        r'16 h · 3 people × $52.00/h',
      );
    });

    test('treats a crew of one as one person', () {
      expect(
        metaText(
          laborLine(calculation: const {'laborRate': 52}, crewSize: 1),
          l10n,
        ),
        r'10 h · $52.00/h',
      );
    });

    test('writes a crew of two with the people count', () {
      expect(
        metaText(
          laborLine(calculation: const {'laborRate': 58}, crewSize: 2),
          l10n,
        ),
        r'10 h · 2 people × $58.00/h',
      );
    });

    test('writes the rate per day for a per-day line', () {
      expect(
        metaText(
          laborLine(
            method: LaborCalculationMethodType.perDay,
            value: const LaborValue(laborDays: 3),
            calculation: const {'laborRate': 200},
            crewSize: 2,
          ),
          l10n,
        ),
        r'3 days · 2 people × $200.00/day',
      );
      expect(
        metaText(
          laborLine(
            method: LaborCalculationMethodType.perDay,
            value: const LaborValue(laborDays: 3),
            calculation: const {'laborRate': 200},
          ),
          l10n,
        ),
        r'3 days · $200.00/day',
      );
    });

    test('keeps the hours alone when the line has no rate', () {
      expect(metaText(laborLine(crewSize: 3), l10n), '10 h');
    });

    test('shows nothing when the hours are missing', () {
      expect(metaText(laborLine(value: const LaborValue()), l10n), isNull);
    });

    test('shows nothing for a per-unit line', () {
      expect(
        metaText(laborLine(method: LaborCalculationMethodType.perUnit), l10n),
        isNull,
      );
    });
  });
}
