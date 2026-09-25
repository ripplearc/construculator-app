import 'package:construculator/features/estimation/data/models/your_rate_entry_dto.dart';
import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('YourRateEntryDto', () {
    final fullJson = <String, dynamic>{
      'id': 'rate-1',
      'company_id': 'company-1',
      'category': 'equipment',
      'item_name': 'Excavator',
      'rate_amount': 250.0,
      'rate_currency': 'USD',
      'unit': 'days',
      'equipment_method': 'day',
      'entry_label': 'Supplier A',
      'saved_at': '2026-01-01T00:00:00.000Z',
      'created_at': '2026-01-01T00:00:00.000Z',
      'updated_at': '2026-01-01T00:00:00.000Z',
    };

    test('fromJson parses every field', () {
      final dto = YourRateEntryDto.fromJson(fullJson);

      expect(dto.id, 'rate-1');
      expect(dto.companyId, 'company-1');
      expect(dto.category, 'equipment');
      expect(dto.itemName, 'Excavator');
      expect(dto.rateAmount, 250.0);
      expect(dto.rateCurrency, 'USD');
      expect(dto.unit, 'days');
      expect(dto.equipmentMethod, 'day');
      expect(dto.entryLabel, 'Supplier A');
      expect(dto.savedAt, '2026-01-01T00:00:00.000Z');
      expect(dto.createdAt, '2026-01-01T00:00:00.000Z');
      expect(dto.updatedAt, '2026-01-01T00:00:00.000Z');
    });

    test('fromJson handles null optional fields', () {
      final json = Map<String, dynamic>.from(fullJson)
        ..['unit'] = null
        ..['equipment_method'] = null
        ..['entry_label'] = null
        ..['created_at'] = null
        ..['updated_at'] = null;

      final dto = YourRateEntryDto.fromJson(json);

      expect(dto.unit, isNull);
      expect(dto.equipmentMethod, isNull);
      expect(dto.entryLabel, isNull);
      expect(dto.createdAt, isNull);
      expect(dto.updatedAt, isNull);
    });

    test('toJson excludes id, createdAt, and updatedAt', () {
      final dto = YourRateEntryDto.fromJson(fullJson);

      final json = dto.toJson();

      expect(json.containsKey('id'), isFalse);
      expect(json.containsKey('created_at'), isFalse);
      expect(json.containsKey('updated_at'), isFalse);
      expect(json, {
        'company_id': 'company-1',
        'category': 'equipment',
        'item_name': 'Excavator',
        'rate_amount': 250.0,
        'rate_currency': 'USD',
        'unit': 'days',
        'equipment_method': 'day',
        'entry_label': 'Supplier A',
        'saved_at': '2026-01-01T00:00:00.000Z',
      });
    });

    test('toEntity converts every field correctly', () {
      final dto = YourRateEntryDto.fromJson(fullJson);

      final entity = dto.toEntity();

      expect(entity.id, 'rate-1');
      expect(entity.companyId, 'company-1');
      expect(entity.category, CostItemType.equipment);
      expect(entity.itemName, 'Excavator');
      expect(entity.rate, const Money(amount: 250.0, currency: 'USD'));
      expect(entity.unit, Unit.days);
      expect(entity.equipmentMethod, EquipmentPricingMethod.day);
      expect(entity.entryLabel, 'Supplier A');
      expect(entity.savedAt, DateTime.parse('2026-01-01T00:00:00.000Z'));
    });

    test('toEntity leaves unit and equipmentMethod null when absent', () {
      final json = Map<String, dynamic>.from(fullJson)
        ..['unit'] = null
        ..['equipment_method'] = null;

      final entity = YourRateEntryDto.fromJson(json).toEntity();

      expect(entity.unit, isNull);
      expect(entity.equipmentMethod, isNull);
    });

    test('fromEntity converts every field correctly', () {
      final entity = YourRateEntry(
        id: 'rate-1',
        companyId: 'company-1',
        itemName: 'Excavator',
        category: CostItemType.equipment,
        rate: const Money(amount: 250.0, currency: 'USD'),
        unit: Unit.days,
        savedAt: DateTime.parse('2026-01-01T00:00:00.000Z'),
        equipmentMethod: EquipmentPricingMethod.day,
        entryLabel: 'Supplier A',
      );

      final dto = YourRateEntryDto.fromEntity(entity);

      expect(dto.id, 'rate-1');
      expect(dto.companyId, 'company-1');
      expect(dto.category, 'equipment');
      expect(dto.itemName, 'Excavator');
      expect(dto.rateAmount, 250.0);
      expect(dto.rateCurrency, 'USD');
      expect(dto.unit, 'days');
      expect(dto.equipmentMethod, 'day');
      expect(dto.entryLabel, 'Supplier A');
      expect(dto.savedAt, '2026-01-01T00:00:00.000Z');
    });

    test('fromEntity leaves unit and equipmentMethod null for a material entry', () {
      final entity = YourRateEntry(
        id: 'rate-2',
        companyId: 'company-1',
        itemName: 'Cement',
        category: CostItemType.material,
        rate: const Money(amount: 12.5),
        savedAt: DateTime.parse('2026-01-01T00:00:00.000Z'),
      );

      final dto = YourRateEntryDto.fromEntity(entity);

      expect(dto.unit, isNull);
      expect(dto.equipmentMethod, isNull);
      expect(dto.entryLabel, isNull);
    });

    test('round-trips entity -> dto -> entity', () {
      final entity = YourRateEntry(
        id: 'rate-1',
        companyId: 'company-1',
        itemName: 'Excavator',
        category: CostItemType.equipment,
        rate: const Money(amount: 250.0, currency: 'USD'),
        unit: Unit.days,
        savedAt: DateTime.parse('2026-01-01T00:00:00.000Z'),
        equipmentMethod: EquipmentPricingMethod.day,
        entryLabel: 'Supplier A',
      );

      final roundTripped = YourRateEntryDto.fromEntity(entity).toEntity();

      expect(roundTripped, entity);
    });
  });
}
