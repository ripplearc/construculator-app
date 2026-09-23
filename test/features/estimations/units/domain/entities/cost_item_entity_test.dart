import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CostItemType enum', () {
    test('name returns correct string values', () {
      expect(CostItemType.material.name, 'material');
      expect(CostItemType.labor.name, 'labor');
      expect(CostItemType.equipment.name, 'equipment');
    });

    test('fromJson creates correct enum from string', () {
      expect(CostItemType.fromJson('material'), CostItemType.material);
      expect(CostItemType.fromJson('labor'), CostItemType.labor);
      expect(CostItemType.fromJson('equipment'), CostItemType.equipment);
    });

    test('fromJson is case-insensitive', () {
      expect(CostItemType.fromJson('MATERIAL'), CostItemType.material);
      expect(CostItemType.fromJson('Labor'), CostItemType.labor);
      expect(CostItemType.fromJson('EQUIPMENT'), CostItemType.equipment);
    });

    test('fromJson returns material for invalid value', () {
      expect(CostItemType.fromJson('invalid'), CostItemType.material);
      expect(CostItemType.fromJson(''), CostItemType.material);
    });

    test('round-trip serialization preserves all values', () {
      for (final type in CostItemType.values) {
        expect(CostItemType.fromJson(type.name), type);
      }
    });
  });

  group('Unit enum', () {
    test('name returns correct string values', () {
      expect(Unit.pieces.name, 'pieces');
      expect(Unit.meters.name, 'meters');
      expect(Unit.squareMeters.name, 'squareMeters');
      expect(Unit.cubicMeters.name, 'cubicMeters');
      expect(Unit.kilograms.name, 'kilograms');
      expect(Unit.tons.name, 'tons');
      expect(Unit.liters.name, 'liters');
      expect(Unit.hours.name, 'hours');
      expect(Unit.days.name, 'days');
      expect(Unit.boxes.name, 'boxes');
      expect(Unit.bags.name, 'bags');
      expect(Unit.rolls.name, 'rolls');
      expect(Unit.sheets.name, 'sheets');
    });

    test('fromJson creates correct enum from string', () {
      expect(Unit.fromJson('pieces'), Unit.pieces);
      expect(Unit.fromJson('meters'), Unit.meters);
      expect(Unit.fromJson('squareMeters'), Unit.squareMeters);
      expect(Unit.fromJson('hours'), Unit.hours);
    });

    test('fromJson is case-insensitive', () {
      expect(Unit.fromJson('PIECES'), Unit.pieces);
      expect(Unit.fromJson('Meters'), Unit.meters);
      expect(Unit.fromJson('HOURS'), Unit.hours);
    });

    test('fromJson returns pieces for invalid value', () {
      expect(Unit.fromJson('invalid'), Unit.pieces);
      expect(Unit.fromJson(''), Unit.pieces);
    });

    test('round-trip serialization preserves all values', () {
      for (final unit in Unit.values) {
        expect(Unit.fromJson(unit.name), unit);
      }
    });
  });

  group('LaborCalculationMethodType enum', () {
    test('toJson returns correct string values', () {
      expect(LaborCalculationMethodType.perHour.toJson(), 'per_hour');
      expect(LaborCalculationMethodType.perDay.toJson(), 'per_day');
      expect(LaborCalculationMethodType.perUnit.toJson(), 'per_unit');
    });

    test('fromJson creates correct enum from string', () {
      expect(
        LaborCalculationMethodType.fromJson('per_hour'),
        LaborCalculationMethodType.perHour,
      );
      expect(
        LaborCalculationMethodType.fromJson('per_day'),
        LaborCalculationMethodType.perDay,
      );
      expect(
        LaborCalculationMethodType.fromJson('per_unit'),
        LaborCalculationMethodType.perUnit,
      );
    });

    test('fromJson is case-sensitive and exact match', () {
      // These should fall back to perHour as they don't match exactly
      expect(
        LaborCalculationMethodType.fromJson('PER_HOUR'),
        LaborCalculationMethodType.perHour,
      );
      expect(
        LaborCalculationMethodType.fromJson('Per_Day'),
        LaborCalculationMethodType.perHour,
      );
    });

    test('fromJson returns perHour for invalid value', () {
      expect(
        LaborCalculationMethodType.fromJson('invalid'),
        LaborCalculationMethodType.perHour,
      );
      expect(
        LaborCalculationMethodType.fromJson(''),
        LaborCalculationMethodType.perHour,
      );
      // Old format should also fall back
      expect(
        LaborCalculationMethodType.fromJson('hourly'),
        LaborCalculationMethodType.perHour,
      );
      expect(
        LaborCalculationMethodType.fromJson('daily'),
        LaborCalculationMethodType.perHour,
      );
    });

    test('round-trip serialization preserves all values', () {
      for (final method in LaborCalculationMethodType.values) {
        expect(LaborCalculationMethodType.fromJson(method.toJson()), method);
      }
    });
  });

  group('Money value object', () {
    test('creates Money with amount and currency', () {
      const money = Money(amount: 100.50, currency: 'USD');

      expect(money.amount, 100.50);
      expect(money.currency, 'USD');
    });

    test('defaults currency to USD when not specified', () {
      const money = Money(amount: 100.50);

      expect(money.currency, 'USD');
    });

    test('copyWith creates new instance with updated values', () {
      const money = Money(amount: 100.50, currency: 'USD');
      final updated = money.copyWith(amount: 200.75);

      expect(updated.amount, 200.75);
      expect(updated.currency, 'USD');
    });

    test('copyWith preserves original values when not specified', () {
      const money = Money(amount: 100.50, currency: 'EUR');
      final updated = money.copyWith(amount: 200.75);

      expect(updated.currency, 'EUR');
    });

    test('two Money objects with same values are equal', () {
      const money1 = Money(amount: 100.50, currency: 'USD');
      const money2 = Money(amount: 100.50, currency: 'USD');

      expect(money1, money2);
    });

    test('two Money objects with different values are not equal', () {
      const money1 = Money(amount: 100.50, currency: 'USD');
      const money2 = Money(amount: 200.75, currency: 'USD');

      expect(money1, isNot(money2));
    });

    test('two Money objects with different currencies are not equal', () {
      const money1 = Money(amount: 100.50, currency: 'USD');
      const money2 = Money(amount: 100.50, currency: 'EUR');

      expect(money1, isNot(money2));
    });
  });

  group('Quantity value object', () {
    test('creates Quantity with value and unit', () {
      const quantity = Quantity(value: 50.0, unit: Unit.meters);

      expect(quantity.value, 50.0);
      expect(quantity.unit, Unit.meters);
    });

    test('copyWith creates new instance with updated values', () {
      const quantity = Quantity(value: 50.0, unit: Unit.meters);
      final updated = quantity.copyWith(value: 100.0);

      expect(updated.value, 100.0);
      expect(updated.unit, Unit.meters);
    });

    test('copyWith can update unit', () {
      const quantity = Quantity(value: 50.0, unit: Unit.meters);
      final updated = quantity.copyWith(unit: Unit.squareMeters);

      expect(updated.value, 50.0);
      expect(updated.unit, Unit.squareMeters);
    });

    test('two Quantity objects with same values are equal', () {
      const quantity1 = Quantity(value: 50.0, unit: Unit.meters);
      const quantity2 = Quantity(value: 50.0, unit: Unit.meters);

      expect(quantity1, quantity2);
    });

    test('two Quantity objects with different values are not equal', () {
      const quantity1 = Quantity(value: 50.0, unit: Unit.meters);
      const quantity2 = Quantity(value: 100.0, unit: Unit.meters);

      expect(quantity1, isNot(quantity2));
    });

    test('two Quantity objects with different units are not equal', () {
      const quantity1 = Quantity(value: 50.0, unit: Unit.meters);
      const quantity2 = Quantity(value: 50.0, unit: Unit.squareMeters);

      expect(quantity1, isNot(quantity2));
    });
  });

  group('LaborValue value object', () {
    test('creates LaborValue with all fields', () {
      const laborValue = LaborValue(
        laborDays: 5.0,
        laborHours: 40.0,
        laborUnitType: 'hourly',
        laborUnitValue: 25.0,
      );

      expect(laborValue.laborDays, 5.0);
      expect(laborValue.laborHours, 40.0);
      expect(laborValue.laborUnitType, 'hourly');
      expect(laborValue.laborUnitValue, 25.0);
    });

    test('creates LaborValue with null fields', () {
      const laborValue = LaborValue();

      expect(laborValue.laborDays, isNull);
      expect(laborValue.laborHours, isNull);
      expect(laborValue.laborUnitType, isNull);
      expect(laborValue.laborUnitValue, isNull);
    });

    test('copyWith updates specified fields', () {
      const laborValue = LaborValue(laborDays: 5.0, laborHours: 40.0);
      final updated = laborValue.copyWith(laborDays: 10.0);

      expect(updated.laborDays, 10.0);
      expect(updated.laborHours, 40.0);
    });

    test('copyWith can clear nullable fields using clearField', () {
      const laborValue = LaborValue(
        laborDays: 5.0,
        laborHours: 40.0,
        laborUnitType: 'hourly',
        laborUnitValue: 25.0,
      );

      final updated = laborValue.copyWith(
        laborDays: clearField,
        laborUnitType: clearField,
      );

      expect(updated.laborDays, isNull);
      expect(updated.laborHours, 40.0); // Preserved
      expect(updated.laborUnitType, isNull);
      expect(updated.laborUnitValue, 25.0); // Preserved
    });

    test('copyWith preserves existing value when parameter omitted', () {
      const laborValue = LaborValue(laborDays: 5.0);
      final updated = laborValue.copyWith(laborHours: 40.0);

      expect(updated.laborDays, 5.0);
      expect(updated.laborHours, 40.0);
      expect(updated.laborUnitType, isNull); // Still null
      expect(updated.laborUnitValue, isNull); // Still null
    });

    test('two LaborValue objects with same values are equal', () {
      const laborValue1 = LaborValue(laborDays: 5.0, laborHours: 40.0);
      const laborValue2 = LaborValue(laborDays: 5.0, laborHours: 40.0);

      expect(laborValue1, laborValue2);
    });

    test('two LaborValue objects with different values are not equal', () {
      const laborValue1 = LaborValue(laborDays: 5.0, laborHours: 40.0);
      const laborValue2 = LaborValue(laborDays: 10.0, laborHours: 40.0);

      expect(laborValue1, isNot(laborValue2));
    });
  });

  group('MaterialCostItem', () {
    final testItem = MaterialCostItem(
      id: 'item-1',
      estimateId: 'estimate-1',
      itemName: 'Concrete',
      calculation: const {'base': 100.0},
      itemTotalCost: 5000.0,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
      currency: 'USD',
      unitPrice: const Money(amount: 100.0, currency: 'USD'),
      quantity: const Quantity(value: 50.0, unit: Unit.cubicMeters),
      productLink: 'https://example.com/concrete',
      description: 'High quality concrete',
    );

    test('creates MaterialCostItem with all fields', () {
      expect(testItem.id, 'item-1');
      expect(testItem.estimateId, 'estimate-1');
      expect(testItem.itemName, 'Concrete');
      expect(testItem.itemType, CostItemType.material);
      expect(testItem.calculation, const {'base': 100.0});
      expect(testItem.itemTotalCost, 5000.0);
      expect(testItem.unitPrice.amount, 100.0);
      expect(testItem.quantity.value, 50.0);
      expect(testItem.quantity.unit, Unit.cubicMeters);
      expect(testItem.productLink, 'https://example.com/concrete');
      expect(testItem.description, 'High quality concrete');
    });

    test('itemType is always material', () {
      expect(testItem.itemType, CostItemType.material);
    });

    test('copyWith creates new instance with updated values', () {
      final updated = testItem.copyWith(itemName: 'Updated Concrete');

      expect(updated.itemName, 'Updated Concrete');
      expect(updated.id, testItem.id);
      expect(updated.estimateId, testItem.estimateId);
    });

    test('copyWith preserves original values when not specified', () {
      final updated = testItem.copyWith(itemTotalCost: 6000.0);

      expect(updated.itemName, testItem.itemName);
      expect(updated.unitPrice, testItem.unitPrice);
      expect(updated.quantity, testItem.quantity);
    });

    test('copyWith can clear nullable fields using clearField', () {
      final updated = testItem.copyWith(
        productLink: clearField,
        description: clearField,
      );

      expect(updated.productLink, isNull);
      expect(updated.description, isNull);
      expect(updated.itemName, testItem.itemName); // Preserved
      expect(updated.unitPrice, testItem.unitPrice); // Preserved
    });

    test('copyWith preserves nullable fields when not specified', () {
      final updated = testItem.copyWith(itemName: 'Updated Name');

      expect(updated.itemName, 'Updated Name');
      expect(updated.productLink, testItem.productLink); // Preserved
      expect(updated.description, testItem.description); // Preserved
    });

    test('two MaterialCostItem objects with same values are equal', () {
      final item1 = MaterialCostItem(
        id: 'item-1',
        estimateId: 'estimate-1',
        itemName: 'Concrete',
        calculation: const {'base': 100.0},
        itemTotalCost: 5000.0,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        currency: 'USD',
        unitPrice: const Money(amount: 100.0),
        quantity: const Quantity(value: 50.0, unit: Unit.cubicMeters),
      );

      final item2 = MaterialCostItem(
        id: 'item-1',
        estimateId: 'estimate-1',
        itemName: 'Concrete',
        calculation: const {'base': 100.0},
        itemTotalCost: 5000.0,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        currency: 'USD',
        unitPrice: const Money(amount: 100.0),
        quantity: const Quantity(value: 50.0, unit: Unit.cubicMeters),
      );

      expect(item1, item2);
    });

    test(
      'two MaterialCostItem objects with different values are not equal',
      () {
        final item2 = testItem.copyWith(itemName: 'Different Material');

        expect(testItem, isNot(item2));
      },
    );
  });

  group('LaborCostItem', () {
    final testItem = LaborCostItem(
      id: 'item-2',
      estimateId: 'estimate-1',
      itemName: 'Electrician Work',
      calculation: const {'hours': 40.0, 'rate': 50.0},
      itemTotalCost: 2000.0,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
      currency: 'USD',
      laborCalcMethod: LaborCalculationMethodType.perHour,
      laborValue: const LaborValue(
        laborHours: 40.0,
        laborUnitType: 'hourly',
        laborUnitValue: 50.0,
      ),
      crewSize: 2,
      description: 'Electrical installation',
    );

    test('creates LaborCostItem with all fields', () {
      expect(testItem.id, 'item-2');
      expect(testItem.estimateId, 'estimate-1');
      expect(testItem.itemName, 'Electrician Work');
      expect(testItem.itemType, CostItemType.labor);
      expect(testItem.laborCalcMethod, LaborCalculationMethodType.perHour);
      expect(testItem.laborValue.laborHours, 40.0);
      expect(testItem.crewSize, 2);
      expect(testItem.description, 'Electrical installation');
    });

    test('itemType is always labor', () {
      expect(testItem.itemType, CostItemType.labor);
    });

    test('copyWith creates new instance with updated values', () {
      final updated = testItem.copyWith(
        laborCalcMethod: LaborCalculationMethodType.perDay,
      );

      expect(updated.laborCalcMethod, LaborCalculationMethodType.perDay);
      expect(updated.id, testItem.id);
      expect(updated.itemName, testItem.itemName);
    });

    test('copyWith can update crew size', () {
      final updated = testItem.copyWith(crewSize: 5);

      expect(updated.crewSize, 5);
      expect(updated.laborCalcMethod, testItem.laborCalcMethod);
    });

    test('copyWith can clear nullable fields using clearField', () {
      final updated = testItem.copyWith(
        crewSize: clearField,
        productLink: clearField,
        description: clearField,
      );

      expect(updated.crewSize, isNull);
      expect(updated.productLink, isNull);
      expect(updated.description, isNull);
      expect(updated.itemName, testItem.itemName); // Preserved
      expect(updated.laborCalcMethod, testItem.laborCalcMethod); // Preserved
    });

    test('copyWith preserves nullable fields when not specified', () {
      final updated = testItem.copyWith(itemName: 'Updated Labor');

      expect(updated.itemName, 'Updated Labor');
      expect(updated.crewSize, testItem.crewSize); // Preserved
      expect(updated.description, testItem.description); // Preserved
    });

    test('two LaborCostItem objects with same values are equal', () {
      final item1 = LaborCostItem(
        id: 'item-2',
        estimateId: 'estimate-1',
        itemName: 'Electrician Work',
        calculation: const {'hours': 40.0},
        itemTotalCost: 2000.0,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        currency: 'USD',
        laborCalcMethod: LaborCalculationMethodType.perHour,
        laborValue: const LaborValue(laborHours: 40.0),
      );

      final item2 = LaborCostItem(
        id: 'item-2',
        estimateId: 'estimate-1',
        itemName: 'Electrician Work',
        calculation: const {'hours': 40.0},
        itemTotalCost: 2000.0,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        currency: 'USD',
        laborCalcMethod: LaborCalculationMethodType.perHour,
        laborValue: const LaborValue(laborHours: 40.0),
      );

      expect(item1, item2);
    });

    test('two LaborCostItem objects with different values are not equal', () {
      final item2 = testItem.copyWith(crewSize: 5);

      expect(testItem, isNot(item2));
    });
  });

  group('EquipmentPricingMethod enum', () {
    test('fromJson creates correct enum from string', () {
      expect(EquipmentPricingMethod.fromJson('day'), EquipmentPricingMethod.day);
      expect(EquipmentPricingMethod.fromJson('job'), EquipmentPricingMethod.job);
    });

    test('fromJson returns day for invalid value', () {
      expect(EquipmentPricingMethod.fromJson('invalid'), EquipmentPricingMethod.day);
    });

    test('round-trip serialization preserves all values', () {
      for (final method in EquipmentPricingMethod.values) {
        expect(EquipmentPricingMethod.fromJson(method.toJson()), method);
      }
    });
  });

  group('DeliveryFeeStatus enum', () {
    test('fromJson creates correct enum from string', () {
      expect(DeliveryFeeStatus.fromJson('unset'), DeliveryFeeStatus.unset);
      expect(
        DeliveryFeeStatus.fromJson('estimated'),
        DeliveryFeeStatus.estimated,
      );
      expect(
        DeliveryFeeStatus.fromJson('confirmed'),
        DeliveryFeeStatus.confirmed,
      );
    });

    test('fromJson returns unset for invalid value', () {
      expect(DeliveryFeeStatus.fromJson('invalid'), DeliveryFeeStatus.unset);
    });

    test('round-trip serialization preserves all values', () {
      for (final status in DeliveryFeeStatus.values) {
        expect(DeliveryFeeStatus.fromJson(status.toJson()), status);
      }
    });
  });

  group('RateStatus enum', () {
    test('fromJson creates correct enum from string', () {
      expect(
        RateStatus.fromJson('sample_rate_unverified'),
        RateStatus.sampleRateUnverified,
      );
      expect(
        RateStatus.fromJson('own_rate_confirmed'),
        RateStatus.ownRateConfirmed,
      );
      expect(RateStatus.fromJson('missing'), RateStatus.missing);
    });

    test('fromJson returns missing for invalid value', () {
      expect(RateStatus.fromJson('invalid'), RateStatus.missing);
    });

    test('round-trip serialization preserves all values', () {
      for (final status in RateStatus.values) {
        expect(RateStatus.fromJson(status.toJson()), status);
      }
    });
  });

  group('EquipmentCostItem', () {
    final dayPricedItem = EquipmentCostItem(
      id: 'item-3',
      estimateId: 'estimate-1',
      itemName: 'Excavator Rental',
      calculation: const {'daily_rate': 500.0, 'duration': 5.0},
      itemTotalCost: 2500.0,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
      currency: 'USD',
      pricingMethod: EquipmentPricingMethod.day,
      duration: 5.0,
      dailyRate: const Money(amount: 500.0, currency: 'USD'),
      deliveryFee: const Money(amount: 50.0, currency: 'USD'),
      deliveryFeeStatus: DeliveryFeeStatus.confirmed,
      rateStatus: RateStatus.ownRateConfirmed,
      productLink: 'https://example.com/excavator',
      description: 'Heavy equipment rental',
    );

    final jobPricedItem = EquipmentCostItem(
      id: 'item-4',
      estimateId: 'estimate-1',
      itemName: 'Crane Rental',
      calculation: const {'job_amount': 3000.0},
      itemTotalCost: 3000.0,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
      currency: 'USD',
      pricingMethod: EquipmentPricingMethod.job,
      jobAmount: const Money(amount: 3000.0, currency: 'USD'),
      deliveryFeeStatus: DeliveryFeeStatus.unset,
      rateStatus: RateStatus.sampleRateUnverified,
    );

    test('creates a day-priced EquipmentCostItem with all fields', () {
      expect(dayPricedItem.id, 'item-3');
      expect(dayPricedItem.estimateId, 'estimate-1');
      expect(dayPricedItem.itemName, 'Excavator Rental');
      expect(dayPricedItem.itemType, CostItemType.equipment);
      expect(dayPricedItem.pricingMethod, EquipmentPricingMethod.day);
      expect(dayPricedItem.duration, 5.0);
      expect(dayPricedItem.dailyRate?.amount, 500.0);
      expect(dayPricedItem.jobAmount, isNull);
      expect(dayPricedItem.deliveryFee?.amount, 50.0);
      expect(dayPricedItem.deliveryFeeStatus, DeliveryFeeStatus.confirmed);
      expect(dayPricedItem.rateStatus, RateStatus.ownRateConfirmed);
      expect(dayPricedItem.productLink, 'https://example.com/excavator');
      expect(dayPricedItem.description, 'Heavy equipment rental');
    });

    test('creates a job-priced EquipmentCostItem with all fields', () {
      expect(jobPricedItem.pricingMethod, EquipmentPricingMethod.job);
      expect(jobPricedItem.jobAmount?.amount, 3000.0);
      expect(jobPricedItem.duration, isNull);
      expect(jobPricedItem.dailyRate, isNull);
      expect(jobPricedItem.deliveryFee, isNull);
      expect(jobPricedItem.deliveryFeeStatus, DeliveryFeeStatus.unset);
      expect(jobPricedItem.rateStatus, RateStatus.sampleRateUnverified);
    });

    test(
      'deliveryFee null means unquoted, Money(0) means confirmed free',
      () {
        final unquoted = dayPricedItem.copyWith(deliveryFee: clearField);
        final confirmedFree = dayPricedItem.copyWith(
          deliveryFee: const Money(amount: 0.0),
          deliveryFeeStatus: DeliveryFeeStatus.confirmed,
        );

        expect(unquoted.deliveryFee, isNull);
        expect(confirmedFree.deliveryFee, const Money(amount: 0.0));
        expect(confirmedFree.deliveryFee, isNot(unquoted.deliveryFee));
      },
    );

    test('itemType is always equipment', () {
      expect(dayPricedItem.itemType, CostItemType.equipment);
      expect(jobPricedItem.itemType, CostItemType.equipment);
    });

    test('copyWith creates new instance with updated values', () {
      final updated = dayPricedItem.copyWith(itemName: 'Updated Equipment');

      expect(updated.itemName, 'Updated Equipment');
      expect(updated.id, dayPricedItem.id);
      expect(updated.estimateId, dayPricedItem.estimateId);
    });

    test('copyWith can update duration and dailyRate', () {
      final updated = dayPricedItem.copyWith(
        duration: 10.0,
        dailyRate: const Money(amount: 600.0),
      );

      expect(updated.duration, 10.0);
      expect(updated.dailyRate?.amount, 600.0);
    });

    test('copyWith does not expose a way to change pricingMethod', () {
      final updated = dayPricedItem.copyWith(itemName: 'Renamed');

      // copyWith has no pricingMethod parameter, so the pricing method of a
      // saved line can never change through it.
      expect(updated.pricingMethod, dayPricedItem.pricingMethod);
    });

    test('copyWith can clear nullable fields using clearField', () {
      final updated = dayPricedItem.copyWith(
        productLink: clearField,
        description: clearField,
        deliveryFee: clearField,
      );

      expect(updated.productLink, isNull);
      expect(updated.description, isNull);
      expect(updated.deliveryFee, isNull);
      expect(updated.itemName, dayPricedItem.itemName); // Preserved
      expect(updated.dailyRate, dayPricedItem.dailyRate); // Preserved
    });

    test('copyWith preserves nullable fields when not specified', () {
      final updated = dayPricedItem.copyWith(itemName: 'Updated Equipment');

      expect(updated.itemName, 'Updated Equipment');
      expect(updated.productLink, dayPricedItem.productLink); // Preserved
      expect(updated.description, dayPricedItem.description); // Preserved
      expect(updated.dailyRate, dayPricedItem.dailyRate); // Preserved
    });

    test('two EquipmentCostItem objects with same values are equal', () {
      final item1 = EquipmentCostItem(
        id: 'item-3',
        estimateId: 'estimate-1',
        itemName: 'Excavator Rental',
        calculation: const {'daily_rate': 500.0},
        itemTotalCost: 2500.0,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        currency: 'USD',
        pricingMethod: EquipmentPricingMethod.day,
        duration: 5.0,
        dailyRate: const Money(amount: 500.0),
        deliveryFeeStatus: DeliveryFeeStatus.unset,
        rateStatus: RateStatus.sampleRateUnverified,
      );

      final item2 = EquipmentCostItem(
        id: 'item-3',
        estimateId: 'estimate-1',
        itemName: 'Excavator Rental',
        calculation: const {'daily_rate': 500.0},
        itemTotalCost: 2500.0,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        currency: 'USD',
        pricingMethod: EquipmentPricingMethod.day,
        duration: 5.0,
        dailyRate: const Money(amount: 500.0),
        deliveryFeeStatus: DeliveryFeeStatus.unset,
        rateStatus: RateStatus.sampleRateUnverified,
      );

      expect(item1, item2);
    });

    test(
      'two EquipmentCostItem objects with different values are not equal',
      () {
        final item2 = dayPricedItem.copyWith(itemName: 'Different Equipment');

        expect(dayPricedItem, isNot(item2));
      },
    );

    test(
      'day-priced and job-priced items with otherwise equal fields are not equal',
      () {
        final dayVariant = EquipmentCostItem(
          id: 'item-5',
          estimateId: 'estimate-1',
          itemName: 'Same Name',
          calculation: const {},
          itemTotalCost: 100.0,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
          currency: 'USD',
          pricingMethod: EquipmentPricingMethod.day,
          deliveryFeeStatus: DeliveryFeeStatus.unset,
          rateStatus: RateStatus.missing,
        );
        final jobVariant = EquipmentCostItem(
          id: 'item-5',
          estimateId: 'estimate-1',
          itemName: 'Same Name',
          calculation: const {},
          itemTotalCost: 100.0,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
          currency: 'USD',
          pricingMethod: EquipmentPricingMethod.job,
          deliveryFeeStatus: DeliveryFeeStatus.unset,
          rateStatus: RateStatus.missing,
        );

        expect(dayVariant, isNot(jobVariant));
      },
    );
  });

  group('CostItem polymorphism', () {
    test('can store different cost item types in same list', () {
      final items = <CostItem>[
        MaterialCostItem(
          id: 'item-1',
          estimateId: 'estimate-1',
          itemName: 'Concrete',
          calculation: const {},
          itemTotalCost: 5000.0,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
          currency: 'USD',
          unitPrice: const Money(amount: 100.0),
          quantity: const Quantity(value: 50.0, unit: Unit.cubicMeters),
        ),
        LaborCostItem(
          id: 'item-2',
          estimateId: 'estimate-1',
          itemName: 'Electrician Work',
          calculation: const {},
          itemTotalCost: 2000.0,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
          currency: 'USD',
          laborCalcMethod: LaborCalculationMethodType.perHour,
          laborValue: const LaborValue(laborHours: 40.0),
        ),
        EquipmentCostItem(
          id: 'item-3',
          estimateId: 'estimate-1',
          itemName: 'Excavator Rental',
          calculation: const {},
          itemTotalCost: 2500.0,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
          currency: 'USD',
          pricingMethod: EquipmentPricingMethod.day,
          duration: 5.0,
          dailyRate: const Money(amount: 500.0),
          deliveryFeeStatus: DeliveryFeeStatus.unset,
          rateStatus: RateStatus.sampleRateUnverified,
        ),
      ];

      expect(items.length, 3);
      expect(items[0].itemType, CostItemType.material);
      expect(items[1].itemType, CostItemType.labor);
      expect(items[2].itemType, CostItemType.equipment);
    });

    test('can filter items by type using pattern matching', () {
      final items = <CostItem>[
        MaterialCostItem(
          id: 'item-1',
          estimateId: 'estimate-1',
          itemName: 'Concrete',
          calculation: const {},
          itemTotalCost: 5000.0,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
          currency: 'USD',
          unitPrice: const Money(amount: 100.0),
          quantity: const Quantity(value: 50.0, unit: Unit.cubicMeters),
        ),
        LaborCostItem(
          id: 'item-2',
          estimateId: 'estimate-1',
          itemName: 'Electrician Work',
          calculation: const {},
          itemTotalCost: 2000.0,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
          currency: 'USD',
          laborCalcMethod: LaborCalculationMethodType.perHour,
          laborValue: const LaborValue(laborHours: 40.0),
        ),
      ];

      final materialItems = items.whereType<MaterialCostItem>().toList();
      final laborItems = items.whereType<LaborCostItem>().toList();

      expect(materialItems.length, 1);
      expect(laborItems.length, 1);
    });
  });

  group('YourRateEntry', () {
    final testEntry = YourRateEntry(
      id: 'rate-1',
      companyId: 'company-1',
      itemName: 'Excavator',
      category: CostItemType.equipment,
      rate: const Money(amount: 250.0),
      savedAt: DateTime(2024, 1, 1),
      unit: Unit.days,
      equipmentMethod: EquipmentPricingMethod.day,
      entryLabel: 'Supplier A',
    );

    test('two entries with the same values are equal', () {
      final other = YourRateEntry(
        id: 'rate-1',
        companyId: 'company-1',
        itemName: 'Excavator',
        category: CostItemType.equipment,
        rate: const Money(amount: 250.0),
        savedAt: DateTime(2024, 1, 1),
        unit: Unit.days,
        equipmentMethod: EquipmentPricingMethod.day,
        entryLabel: 'Supplier A',
      );

      expect(testEntry, other);
    });

    test('copyWith creates new instance with updated values', () {
      final updated = testEntry.copyWith(itemName: 'Bulldozer', entryLabel: 'Supplier B');

      expect(updated.itemName, 'Bulldozer');
      expect(updated.entryLabel, 'Supplier B');
      expect(updated.id, testEntry.id);
      expect(updated.rate, testEntry.rate);
    });

    test('copyWith preserves original values when not specified', () {
      final updated = testEntry.copyWith(itemName: 'Bulldozer');

      expect(updated.unit, testEntry.unit);
      expect(updated.equipmentMethod, testEntry.equipmentMethod);
      expect(updated.entryLabel, testEntry.entryLabel);
    });

    test('copyWith can clear nullable fields using clearField', () {
      final updated = testEntry.copyWith(
        unit: clearField,
        equipmentMethod: clearField,
        entryLabel: clearField,
      );

      expect(updated.unit, isNull);
      expect(updated.equipmentMethod, isNull);
      expect(updated.entryLabel, isNull);
    });
  });
}
