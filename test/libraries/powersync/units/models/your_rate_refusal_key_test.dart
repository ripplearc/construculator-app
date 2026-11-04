import 'package:construculator/libraries/powersync/models/your_rate_refusal_key.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('YourRateRefusalKey', () {
    String keyFor({
      String userId = 'user-1',
      String companyId = 'company-1',
      String category = 'equipment',
      String itemName = 'Excavator',
      String? equipmentMethod = 'day',
    }) => YourRateRefusalKey.of(
      userId: userId,
      companyId: companyId,
      category: category,
      itemName: itemName,
      equipmentMethod: equipmentMethod,
    );

    test('normalizeName trims, collapses spaces and lower-cases', () {
      expect(
        YourRateRefusalKey.normalizeName('  Mini   EXCAVATOR '),
        'mini excavator',
      );
    });

    test('of joins user, company, category, name and method', () {
      expect(keyFor(), 'user-1|company-1|equipment|excavator|day');
    });

    test('of ends with an empty method when the item has none', () {
      expect(
        keyFor(equipmentMethod: null),
        'user-1|company-1|equipment|excavator|',
      );
    });

    test('of gives one key to names that differ only by case and spacing', () {
      expect(keyFor(itemName: ' excavator  '), keyFor(itemName: 'EXCAVATOR'));
    });

    test('of gives different keys to different users of the same company', () {
      expect(keyFor(userId: 'user-2'), isNot(keyFor()));
    });

    test('of gives different keys to different pricing methods', () {
      expect(keyFor(equipmentMethod: 'job'), isNot(keyFor()));
    });
  });
}
