import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/presentation/helpers/your_rate_recency_label.dart';
import 'package:construculator/l10n/generated/app_localizations_en.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('YourRateRecencyLabel.recencyLabel', () {
    final l10n = AppLocalizationsEn();
    final now = DateTime(2026, 10, 6, 9);

    DateTime daysAgo(int days) => DateTime(2026, 10, 6 - days, 16);

    YourRateEntry usedDaysAgo(int days) => YourRateEntry(
      id: 'rate-1',
      companyId: 'company-1',
      itemName: 'Excavator',
      category: CostItemType.equipment,
      rate: const Money(amount: 250.0),
      savedAt: DateTime(2025, 1, 1),
      lastUsedAt: daysAgo(days),
    );

    YourRateEntry savedDaysAgo(int days) => YourRateEntry(
      id: 'rate-2',
      companyId: 'company-1',
      itemName: 'Excavator',
      category: CostItemType.equipment,
      rate: const Money(amount: 250.0),
      savedAt: daysAgo(days),
    );

    const usedWords = {
      0: 'Used today',
      1: 'Used yesterday',
      2: 'Used 2 days ago',
      3: 'Used 3 days ago',
      6: 'Used 6 days ago',
      7: 'Used last week',
      13: 'Used last week',
      14: 'Used 2 weeks ago',
      20: 'Used 2 weeks ago',
      21: 'Used 3 weeks ago',
      29: 'Used 4 weeks ago',
      30: 'Used last month',
      59: 'Used last month',
      60: 'Used 2 months ago',
      365: 'Used 12 months ago',
    };

    for (final MapEntry(key: days, value: words) in usedWords.entries) {
      test('a rate last added $days days ago reads "$words"', () {
        expect(usedDaysAgo(days).recencyLabel(l10n, now: now), words);
      });

      test('a rate only saved $days days ago reads the Saved form', () {
        expect(
          savedDaysAgo(days).recencyLabel(l10n, now: now),
          words.replaceFirst('Used', 'Saved'),
        );
      });
    }

    test('a rate used today reads Used today even when saved long ago', () {
      expect(usedDaysAgo(0).recencyLabel(l10n, now: now), 'Used today');
    });

    test('a new save after the last use does not change the Used date', () {
      final entry = usedDaysAgo(20).copyWith(savedAt: daysAgo(1));

      expect(entry.recencyLabel(l10n, now: now), 'Used 2 weeks ago');
    });
  });
}
