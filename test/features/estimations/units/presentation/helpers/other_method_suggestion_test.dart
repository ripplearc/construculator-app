import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/presentation/helpers/other_method_suggestion.dart';
import 'package:construculator/l10n/generated/app_localizations_en.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l10n = AppLocalizationsEn();

  YourRateEntry rate(
    double amount,
    EquipmentPricingMethod? method, {
    String id = 'rate',
  }) => YourRateEntry(
    id: id,
    companyId: 'company-1',
    itemName: 'Excavator',
    category: CostItemType.equipment,
    rate: Money(amount: amount),
    savedAt: DateTime(2026, 1, 1),
    equipmentMethod: method,
  );

  OtherMethodSuggestion? suggestionFor(
    List<YourRateEntry> results,
    EquipmentPricingMethod active,
  ) => OtherMethodSuggestion.from(results, active: active);

  group('OtherMethodSuggestion.from', () {
    test('is absent when the search found nothing', () {
      expect(suggestionFor([], EquipmentPricingMethod.day), isNull);
    });

    test('is absent when a rate under the active method matches', () {
      final results = [
        rate(120, EquipmentPricingMethod.day, id: 'day'),
        rate(340, EquipmentPricingMethod.job, id: 'job'),
      ];

      expect(suggestionFor(results, EquipmentPricingMethod.day), isNull);
      expect(suggestionFor(results, EquipmentPricingMethod.job), isNull);
    });

    test('is absent when the only matches have no pricing method', () {
      expect(
        suggestionFor([rate(340, null)], EquipmentPricingMethod.day),
        isNull,
      );
    });

    test('points at job when Day is active and only a job price matches', () {
      final suggestion = suggestionFor([
        rate(340, EquipmentPricingMethod.job),
      ], EquipmentPricingMethod.day)!;

      expect(suggestion.method, EquipmentPricingMethod.job);
      expect(suggestion.count, 1);
      expect(suggestion.lowest, 340);
      expect(suggestion.highest, 340);
    });

    test('points at day when Job is active and only a day rate matches', () {
      final suggestion = suggestionFor([
        rate(120, EquipmentPricingMethod.day),
      ], EquipmentPricingMethod.job)!;

      expect(suggestion.method, EquipmentPricingMethod.day);
      expect(suggestion.count, 1);
    });

    test('counts every match and spans the range whatever the order', () {
      final suggestion = suggestionFor([
        rate(400, EquipmentPricingMethod.job, id: 'a'),
        rate(520, EquipmentPricingMethod.job, id: 'b'),
        rate(340, EquipmentPricingMethod.job, id: 'c'),
      ], EquipmentPricingMethod.day)!;

      expect(suggestion.count, 3);
      expect(suggestion.lowest, 340);
      expect(suggestion.highest, 520);
    });

    test('ignores matches that have no pricing method when counting', () {
      final suggestion = suggestionFor([
        rate(999, null, id: 'none'),
        rate(340, EquipmentPricingMethod.job, id: 'job'),
      ], EquipmentPricingMethod.day)!;

      expect(suggestion.count, 1);
      expect(suggestion.highest, 340);
    });
  });

  group('OtherMethodSuggestion.message', () {
    String messageFor(
      List<YourRateEntry> results,
      EquipmentPricingMethod active, {
      String query = 'excavator half day',
    }) => suggestionFor(results, active)!.message(l10n, query: query);

    test('names the amount of the one job price, as the storyboard words it', () {
      expect(
        messageFor([
          rate(340, EquipmentPricingMethod.job),
        ], EquipmentPricingMethod.day),
        'No day rates for “excavator half day”. It has a job price of \$340.00.',
      );
    });

    test('words the other direction with day rates', () {
      expect(
        messageFor(
          [rate(120, EquipmentPricingMethod.day)],
          EquipmentPricingMethod.job,
          query: 'mini excavator',
        ),
        'No job prices for “mini excavator”. It has a day rate of \$120.00.',
      );
    });

    test('gives the count and the range for several job prices', () {
      expect(
        messageFor([
          rate(340, EquipmentPricingMethod.job, id: 'a'),
          rate(520, EquipmentPricingMethod.job, id: 'b'),
          rate(400, EquipmentPricingMethod.job, id: 'c'),
        ], EquipmentPricingMethod.day),
        'No day rates for “excavator half day”. It has 3 job prices, from \$340.00 to \$520.00.',
      );
    });

    test('gives the count and the range for several day rates', () {
      expect(
        messageFor([
          rate(120, EquipmentPricingMethod.day, id: 'a'),
          rate(180, EquipmentPricingMethod.day, id: 'b'),
        ], EquipmentPricingMethod.job),
        'No job prices for “excavator half day”. It has 2 day rates, from \$120.00 to \$180.00.',
      );
    });
  });

  group('OtherMethodSuggestion.actionLabel', () {
    test('offers the job prices when the matches are job prices', () {
      expect(
        suggestionFor([
          rate(340, EquipmentPricingMethod.job),
        ], EquipmentPricingMethod.day)!.actionLabel(l10n),
        'Show job prices',
      );
    });

    test('offers the day rates when the matches are day rates', () {
      expect(
        suggestionFor([
          rate(120, EquipmentPricingMethod.day),
        ], EquipmentPricingMethod.job)!.actionLabel(l10n),
        'Show day rates',
      );
    });
  });
}
