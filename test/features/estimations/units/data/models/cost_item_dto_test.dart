import 'package:construculator/features/estimation/data/models/cost_item_dto.dart';
import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/cost_item_test_data_map_factory.dart';

void main() {
  group('CostItemDto', () {
    group('MaterialCostItem', () {
      final testJson = CostItemTestDataMapFactory.createMaterialItemData(
        id: 'item-123',
        estimateId: 'estimate-456',
        itemName: 'Concrete Mix',
        description: 'High quality concrete mix',
        unitPrice: 100.0,
        quantity: 50.0,
        unit: 'pieces',
        productLink: 'https://example.com/concrete',
        calculation: {'base': 100.0, 'tax': 10.0},
        itemTotalCost: 5000.0,
        createdAt: '2025-02-25T14:30:00.000Z',
        updatedAt: '2025-02-25T14:30:00.000Z',
      );

      final testDto = CostItemDto(
        id: 'item-123',
        estimateId: 'estimate-456',
        itemName: 'Concrete Mix',
        itemType: 'material',
        calculation: {'base': 100.0, 'tax': 10.0},
        itemTotalCost: 5000.0,
        createdAt: '2025-02-25T14:30:00.000Z',
        updatedAt: '2025-02-25T14:30:00.000Z',
        unitPrice: 100.0,
        quantity: 50.0,
        unitMeasurement: 'pieces',
        productLink: 'https://example.com/concrete',
        description: 'High quality concrete mix',
      );

      final testEntity = MaterialCostItem(
        id: 'item-123',
        estimateId: 'estimate-456',
        itemName: 'Concrete Mix',
        calculation: const {'base': 100.0, 'tax': 10.0},
        itemTotalCost: 5000.0,
        createdAt: DateTime.parse('2025-02-25T14:30:00.000Z'),
        updatedAt: DateTime.parse('2025-02-25T14:30:00.000Z'),
        unitPrice: const Money(amount: 100.0, currency: 'USD'),
        quantity: const Quantity(value: 50.0, unit: Unit.pieces),
        productLink: 'https://example.com/concrete',
        description: 'High quality concrete mix',
      );

      group('fromJson', () {
        test('creates MaterialCostItem DTO from complete JSON', () {
          final dto = CostItemDto.fromJson(testJson);

          expect(dto, testDto);
        });

        test('handles integer values for numeric fields', () {
          final jsonWithInts = {
            ...testJson,
            'unit_price': 100,
            'quantity': 50,
            'item_total_cost': 5000,
          };

          final dto = CostItemDto.fromJson(jsonWithInts);

          expect(dto.unitPrice, 100.0);
          expect(dto.quantity, 50.0);
          expect(dto, testDto);
        });
      });

      group('toJson', () {
        test('converts DTO to JSON with all fields', () {
          final json = testDto.toJson();

          expect(json, testJson);
        });

        test('uses snake_case for JSON keys', () {
          final json = testDto.toJson();

          expect(json.keys, contains('estimate_id'));
          expect(json.keys, contains('item_name'));
          expect(json.keys, contains('item_type'));
          expect(json.keys, contains('item_total_cost'));
          expect(json.keys, contains('created_at'));
          expect(json.keys, contains('updated_at'));
        });
      });

      group('toEntity', () {
        test('converts DTO to MaterialCostItem domain entity', () {
          final entity = testDto.toEntity();

          expect(entity, testEntity);
        });

        test('correctly instantiates MaterialCostItem based on item_type', () {
          final entity = testDto.toEntity();

          expect(entity, isA<MaterialCostItem>());
          expect(entity, testEntity);
        });
      });

      group('fromEntity', () {
        test('converts MaterialCostItem entity to DTO', () {
          final dto = CostItemDto.fromEntity(testEntity);

          expect(dto, testDto);
        });
      });
    });

    group('LaborCostItem', () {
      final testJson = CostItemTestDataMapFactory.createLaborItemData(
        id: 'item-789',
        estimateId: 'estimate-456',
        itemName: 'Electrician Work',
        description: 'Electrical installation',
        laborCalcMethod: 'per_hour',
        laborDays: 5.0,
        laborHours: 40.0,
        laborUnitType: 'hourly',
        laborUnitValue: 50.0,
        crewSize: 2,
        calculation: {'hours': 40.0, 'rate': 50.0},
        itemTotalCost: 2000.0,
        createdAt: '2025-02-25T15:00:00.000Z',
        updatedAt: '2025-02-25T15:00:00.000Z',
      );

      final testDto = CostItemDto(
        id: 'item-789',
        estimateId: 'estimate-456',
        itemName: 'Electrician Work',
        itemType: 'labor',
        calculation: {'hours': 40.0, 'rate': 50.0},
        itemTotalCost: 2000.0,
        createdAt: '2025-02-25T15:00:00.000Z',
        updatedAt: '2025-02-25T15:00:00.000Z',
        laborCalcMethod: 'per_hour',
        laborDays: 5.0,
        laborHours: 40.0,
        laborUnitType: 'hourly',
        laborUnitValue: 50.0,
        crewSize: 2,
        description: 'Electrical installation',
      );

      final testEntity = LaborCostItem(
        id: 'item-789',
        estimateId: 'estimate-456',
        itemName: 'Electrician Work',
        calculation: const {'hours': 40.0, 'rate': 50.0},
        itemTotalCost: 2000.0,
        createdAt: DateTime.parse('2025-02-25T15:00:00.000Z'),
        updatedAt: DateTime.parse('2025-02-25T15:00:00.000Z'),
        laborCalcMethod: LaborCalculationMethodType.perHour,
        laborValue: const LaborValue(
          laborDays: 5.0,
          laborHours: 40.0,
          laborUnitType: 'hourly',
          laborUnitValue: 50.0,
        ),
        crewSize: 2,
        description: 'Electrical installation',
      );

      group('fromJson', () {
        test('creates LaborCostItem DTO from complete JSON', () {
          final dto = CostItemDto.fromJson(testJson);

          expect(dto, testDto);
        });
      });

      group('toEntity', () {
        test('converts DTO to LaborCostItem domain entity', () {
          final entity = testDto.toEntity();

          expect(entity, testEntity);
        });

        test('correctly instantiates LaborCostItem based on item_type', () {
          final entity = testDto.toEntity();

          expect(entity, isA<LaborCostItem>());
          expect(entity, testEntity);
        });
      });

      group('fromEntity', () {
        test('converts LaborCostItem entity to DTO', () {
          final dto = CostItemDto.fromEntity(testEntity);

          expect(dto, testDto);
        });
      });
    });

    group('EquipmentCostItem', () {
      final testJson = CostItemTestDataMapFactory.createEquipmentItemData(
        id: 'item-999',
        estimateId: 'estimate-456',
        itemName: 'Excavator Rental',
        description: 'Heavy equipment rental',
        unitPrice: 500.0,
        quantity: 5.0,
        unit: 'days',
        productLink: 'https://example.com/excavator',
        calculation: {'days': 5.0, 'rate': 500.0},
        itemTotalCost: 2500.0,
        createdAt: '2025-02-25T16:00:00.000Z',
        updatedAt: '2025-02-25T16:00:00.000Z',
      );

      final testDto = CostItemDto(
        id: 'item-999',
        estimateId: 'estimate-456',
        itemName: 'Excavator Rental',
        itemType: 'equipment',
        calculation: {'days': 5.0, 'rate': 500.0},
        itemTotalCost: 2500.0,
        createdAt: '2025-02-25T16:00:00.000Z',
        updatedAt: '2025-02-25T16:00:00.000Z',
        unitPrice: 500.0,
        quantity: 5.0,
        unitMeasurement: 'days',
        productLink: 'https://example.com/excavator',
        description: 'Heavy equipment rental',
      );

      final testEntity = EquipmentCostItem(
        id: 'item-999',
        estimateId: 'estimate-456',
        itemName: 'Excavator Rental',
        calculation: const {'days': 5.0, 'rate': 500.0},
        itemTotalCost: 2500.0,
        createdAt: DateTime.parse('2025-02-25T16:00:00.000Z'),
        updatedAt: DateTime.parse('2025-02-25T16:00:00.000Z'),
        unitPrice: const Money(amount: 500.0, currency: 'USD'),
        quantity: const Quantity(value: 5.0, unit: Unit.days),
        productLink: 'https://example.com/excavator',
        description: 'Heavy equipment rental',
      );

      group('fromJson', () {
        test('creates EquipmentCostItem DTO from complete JSON', () {
          final dto = CostItemDto.fromJson(testJson);

          expect(dto, testDto);
        });
      });

      group('toEntity', () {
        test('converts DTO to EquipmentCostItem domain entity', () {
          final entity = testDto.toEntity();

          expect(entity, testEntity);
        });

        test('correctly instantiates EquipmentCostItem based on item_type', () {
          final entity = testDto.toEntity();

          expect(entity, isA<EquipmentCostItem>());
          expect(entity, testEntity);
        });
      });

      group('fromEntity', () {
        test('converts EquipmentCostItem entity to DTO', () {
          final dto = CostItemDto.fromEntity(testEntity);

          expect(dto, testDto);
        });
      });
    });

    group('round-trip conversion', () {
      test(
        'JSON -> DTO -> Entity conversion is consistent for MaterialCostItem',
        () {
          final json = CostItemTestDataMapFactory.createMaterialItemData(
            id: 'item-123',
            estimateId: 'estimate-456',
            itemName: 'Concrete Mix',
            unitPrice: 100.0,
            quantity: 50.0,
            unit: 'pieces',
            calculation: {'base': 100.0},
            itemTotalCost: 5000.0,
            createdAt: '2025-02-25T14:30:00.000Z',
            updatedAt: '2025-02-25T14:30:00.000Z',
          );

          final dto = CostItemDto.fromJson(json);
          final entity = dto.toEntity();
          final dtoAgain = CostItemDto.fromEntity(entity);
          final jsonAgain = dtoAgain.toJson();

          expect(dtoAgain, dto);
          expect(jsonAgain, json);
        },
      );

      test(
        'Entity -> DTO -> JSON conversion is consistent for LaborCostItem',
        () {
          final entity = LaborCostItem(
            id: 'item-789',
            estimateId: 'estimate-456',
            itemName: 'Electrician Work',
            calculation: const {'hours': 40.0},
            itemTotalCost: 2000.0,
            createdAt: DateTime.parse('2025-02-25T15:00:00.000Z'),
            updatedAt: DateTime.parse('2025-02-25T15:00:00.000Z'),
            laborCalcMethod: LaborCalculationMethodType.perHour,
            laborValue: const LaborValue(laborHours: 40.0),
          );

          final dto = CostItemDto.fromEntity(entity);
          final entityAgain = dto.toEntity();

          expect(entityAgain, entity);
          expect(dto, CostItemDto.fromJson(dto.toJson()));
        },
      );

      test('JSON -> DTO -> JSON produces identical result', () {
        final json = CostItemTestDataMapFactory.createEquipmentItemData(
          id: 'item-999',
          estimateId: 'estimate-456',
          itemName: 'Excavator Rental',
          unitPrice: 500.0,
          quantity: 5.0,
          unit: 'days',
          calculation: {'days': 5.0},
          itemTotalCost: 2500.0,
          description: null,
          createdAt: '2025-02-25T16:00:00.000Z',
          updatedAt: '2025-02-25T16:00:00.000Z',
        );

        final dto = CostItemDto.fromJson(json);
        final resultJson = dto.toJson();

        expect(resultJson, json);
      });

      test('Entity -> DTO -> Entity produces equivalent result', () {
        final entity = MaterialCostItem(
          id: 'item-123',
          estimateId: 'estimate-456',
          itemName: 'Concrete Mix',
          calculation: const {'base': 100.0},
          itemTotalCost: 5000.0,
          createdAt: DateTime.parse('2025-02-25T14:30:00.000Z'),
          updatedAt: DateTime.parse('2025-02-25T14:30:00.000Z'),
          unitPrice: const Money(amount: 100.0, currency: 'USD'),
          quantity: const Quantity(value: 50.0, unit: Unit.pieces),
        );

        final dto = CostItemDto.fromEntity(entity);
        final resultEntity = dto.toEntity();

        expect(resultEntity, entity);
      });
    });

    group('malformed JSON handling', () {
      test('handles non-numeric values in calculation map', () {
        final json = CostItemTestDataMapFactory.createMaterialItemData(
          calculation: {
            'valid_number': 100.0,
            'invalid_string': 'not a number',
            'invalid_map': {'nested': 'value'},
          },
        );

        final dto = CostItemDto.fromJson(json);
        final entity = dto.toEntity();

        expect(entity.calculation, {'valid_number': 100.0});
      });

      test('handles unknown item_type by defaulting to material', () {
        final json = CostItemTestDataMapFactory.createMaterialItemData();
        json['item_type'] = 'unknown_type';

        final dto = CostItemDto.fromJson(json);
        final entity = dto.toEntity();

        expect(entity, isA<MaterialCostItem>());
        expect(entity.itemType, CostItemType.material);
      });

      test('handles unknown unit_measurement by defaulting to pieces', () {
        final json = CostItemTestDataMapFactory.createMaterialItemData();
        json['unit_measurement'] = 'unknown_unit';

        final dto = CostItemDto.fromJson(json);
        final entity = dto.toEntity() as MaterialCostItem;

        expect(entity.quantity.unit, Unit.pieces);
      });

      test('handles null unit_measurement by defaulting to pieces', () {
        final json = CostItemTestDataMapFactory.createMaterialItemData();
        json['unit_measurement'] = null;

        final dto = CostItemDto.fromJson(json);
        final entity = dto.toEntity() as MaterialCostItem;

        expect(entity.quantity.unit, Unit.pieces);
      });

      test('handles unknown labor_calc_method by defaulting to perHour', () {
        final json = CostItemTestDataMapFactory.createLaborItemData();
        json['labor_calc_method'] = 'unknown_method';

        final dto = CostItemDto.fromJson(json);
        final entity = dto.toEntity() as LaborCostItem;

        expect(entity.laborCalcMethod, LaborCalculationMethodType.perHour);
      });

      test('handles null labor_calc_method by defaulting to perHour', () {
        final json = CostItemTestDataMapFactory.createLaborItemData();
        json['labor_calc_method'] = null;

        final dto = CostItemDto.fromJson(json);
        final entity = dto.toEntity() as LaborCostItem;

        expect(entity.laborCalcMethod, LaborCalculationMethodType.perHour);
      });

      test('handles empty calculation map', () {
        final json = CostItemTestDataMapFactory.createMaterialItemData(
          calculation: {},
        );

        final dto = CostItemDto.fromJson(json);
        final entity = dto.toEntity();

        expect(entity.calculation, isEmpty);
      });
    });
  });
}
