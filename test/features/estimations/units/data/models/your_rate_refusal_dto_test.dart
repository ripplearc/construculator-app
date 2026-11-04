import 'package:construculator/features/estimation/data/models/your_rate_refusal_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('YourRateRefusalDto', () {
    final fullJson = <String, dynamic>{
      'id': 'user-1|company-1|equipment|excavator|day',
      'user_id': 'user-1',
      'company_id': 'company-1',
      'category': 'equipment',
      'refused_row_id': 'row-1',
      'item_name': 'Excavator',
      'equipment_method': 'day',
      'entry_label': 'Supplier A',
      'refused_amount': 900,
      'accepted_amount': 250.5,
      'shown_at': '2026-01-01T00:00:00.000Z',
    };

    test('fromJson parses every field', () {
      final dto = YourRateRefusalDto.fromJson(fullJson);

      expect(dto.id, 'user-1|company-1|equipment|excavator|day');
      expect(dto.userId, 'user-1');
      expect(dto.companyId, 'company-1');
      expect(dto.category, 'equipment');
      expect(dto.refusedRowId, 'row-1');
      expect(dto.itemName, 'Excavator');
      expect(dto.equipmentMethod, 'day');
      expect(dto.entryLabel, 'Supplier A');
      expect(dto.refusedAmount, 900.0);
      expect(dto.acceptedAmount, 250.5);
      expect(dto.shownAt, '2026-01-01T00:00:00.000Z');
    });

    test('fromJson leaves the optional fields null when they are null', () {
      final json = Map<String, dynamic>.from(fullJson)
        ..['equipment_method'] = null
        ..['entry_label'] = null
        ..['accepted_amount'] = null
        ..['shown_at'] = null;

      final dto = YourRateRefusalDto.fromJson(json);

      expect(dto.equipmentMethod, isNull);
      expect(dto.entryLabel, isNull);
      expect(dto.acceptedAmount, isNull);
      expect(dto.shownAt, isNull);
    });

    test('fromJson throws when a required column is missing', () {
      final json = Map<String, dynamic>.from(fullJson)
        ..remove('refused_amount');

      expect(
        () => YourRateRefusalDto.fromJson(json),
        throwsA(isA<TypeError>()),
      );
    });

    test('two refusals read from the same row are equal', () {
      expect(
        YourRateRefusalDto.fromJson(fullJson),
        YourRateRefusalDto.fromJson(Map<String, dynamic>.from(fullJson)),
      );
    });

    test('refusals differing in one field are not equal', () {
      final changed = Map<String, dynamic>.from(fullJson)
        ..['shown_at'] = '2026-02-02T00:00:00.000Z';

      expect(
        YourRateRefusalDto.fromJson(fullJson),
        isNot(YourRateRefusalDto.fromJson(changed)),
      );
    });
  });
}
