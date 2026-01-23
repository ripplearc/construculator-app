import 'package:construculator/features/estimation/data/models/cost_estimate_dto.dart';
import 'package:construculator/features/estimation/domain/entities/cost_estimate_entity.dart';
import 'package:construculator/features/estimation/domain/entities/enums.dart';
import 'package:construculator/features/estimation/domain/entities/lock_status_entity.dart';
import 'package:construculator/features/estimation/domain/entities/markup_configuration_entity.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/estimation_test_data_map_factory.dart';

void main() {
  const jsonWithNulls = {
    'id': '123',
    'project_id': 'p1',
    'estimate_name': 'Test Estimate',
    'estimate_description': null,
    'creator_user_id': 'user1',
    'markup_type': null,
    'overall_markup_value_type': null,
    'overall_markup_value': null,
    'material_markup_value_type': null,
    'material_markup_value': null,
    'labor_markup_value_type': null,
    'labor_markup_value': null,
    'equipment_markup_value_type': null,
    'equipment_markup_value': null,
    'total_cost': null,
    'is_locked': false,
    'locked_by_user_id': null,
    'locked_at': null,
    'created_at': '2025-09-19T10:00:00Z',
    'updated_at': '2025-09-20T10:00:00Z',
  };

  group('CostEstimateDto', () {
    test('fromJson should parse all fields correctly', () {
      final sampleData = EstimationTestDataMapFactory.createFakeEstimationData(
        isLocked: true,
        lockedByUserId: 'locking-user',
        lockedAt: '2025-01-01T10:00:00.000Z',
      );
      final dto = CostEstimateDto.fromJson(sampleData);

      const expected = CostEstimateDto(
        id: estimateIdDefault,
        projectId: testProjectId,
        estimateName: estimateNameDefault,
        estimateDescription: estimateDescDefault,
        creatorUserId: userIdDefault,
        markupType: markupTypeOverall,
        overallMarkupValueType: markupValueTypePercentage,
        overallMarkupValue: overallMarkupDefault,
        materialMarkupValueType: markupValueTypePercentage,
        materialMarkupValue: materialMarkupDefault,
        laborMarkupValueType: markupValueTypePercentage,
        laborMarkupValue: laborMarkupDefault,
        equipmentMarkupValueType: markupValueTypePercentage,
        equipmentMarkupValue: equipmentMarkupDefault,
        totalCost: totalCostDefault,
        isLocked: true,
        lockedByUserID: 'locking-user',
        lockedAt: '2025-01-01T10:00:00.000Z',
        createdAt: timestampDefault,
        updatedAt: timestampDefault,
      );

      expect(dto, equals(expected));
    });

    test('toJson should output the same map as input with out the id', () {
      final sampleData =
          EstimationTestDataMapFactory.createFakeEstimationData();
      final dto = CostEstimateDto.fromJson(sampleData);
      final json = dto.toJson();

      expect(json, equals(sampleData..remove('id')));
    });

    test(
      'toDomain should map all fields and types correctly (nullable granular parts)',
      () {
        final sampleData =
            EstimationTestDataMapFactory.createFakeEstimationData(
              isLocked: true,
              lockedByUserId: 'locking-user',
              lockedAt: '2025-01-01T10:00:00.000Z',
            );
        final dto = CostEstimateDto.fromJson(sampleData);
        final domain = dto.toDomain();

        final expected = CostEstimate(
          id: dto.id,
          projectId: dto.projectId,
          estimateName: dto.estimateName,
          estimateDescription: dto.estimateDescription,
          creatorUserId: dto.creatorUserId,
          markupConfiguration: MarkupConfiguration(
            overallType: MarkupType.overall,
            overallValue: const MarkupValue(
              type: MarkupValueType.percentage,
              value: overallMarkupDefault,
            ),
            materialValue: const MarkupValue(
              type: MarkupValueType.percentage,
              value: materialMarkupDefault,
            ),
            laborValue: const MarkupValue(
              type: MarkupValueType.percentage,
              value: laborMarkupDefault,
            ),
            equipmentValue: const MarkupValue(
              type: MarkupValueType.percentage,
              value: equipmentMarkupDefault,
            ),
          ),
          totalCost: dto.totalCost,
          lockStatus: LockedStatus(
            'locking-user',
            DateTime.parse('2025-01-01T10:00:00.000Z'),
          ),
          createdAt: DateTime.parse(timestampDefault),
          updatedAt: DateTime.parse(timestampDefault),
        );

        expect(domain, equals(expected));
      },
    );

    test(
      'toDomain should create CostEstimate with UnlockedStatus when isLocked is false',
      () {
        final unlockedJson = Map<String, dynamic>.from(
          EstimationTestDataMapFactory.createFakeEstimationData(),
        )..['is_locked'] = false;

        final dto = CostEstimateDto.fromJson(unlockedJson);
        final domain = dto.toDomain();

        expect(domain.lockStatus.isLocked, false);
        expect(domain.lockStatus, isA<UnlockedStatus>());
        expect(domain.lockStatus, equals(UnlockedStatus()));
        expect(domain.lockStatus.isLockedBy('any-user'), isFalse);
      },
    );

    test('two CostEstimateDto instances from identical data are equal', () {
      final data = EstimationTestDataMapFactory.createFakeEstimationData();

      expect(
        CostEstimateDto.fromJson(data),
        equals(CostEstimateDto.fromJson(data)),
      );
    });

    test('toDomain maps markup type: overall', () {
      final data = EstimationTestDataMapFactory.createFakeEstimationData(
        markupType: 'overall',
      );
      final domain = CostEstimateDto.fromJson(data).toDomain();
      expect(domain.markupConfiguration.overallType, MarkupType.overall);
    });

    test('toDomain maps markup type: granular', () {
      final data = EstimationTestDataMapFactory.createFakeEstimationData(
        markupType: 'granular',
      );
      final domain = CostEstimateDto.fromJson(data).toDomain();
      expect(domain.markupConfiguration.overallType, MarkupType.granular);
    });

    test('toDomain maps overall markup value type: percentage', () {
      final data = EstimationTestDataMapFactory.createFakeEstimationData(
        overallMarkupValueType: 'percentage',
      );
      final domain = CostEstimateDto.fromJson(data).toDomain();
      expect(
        domain.markupConfiguration.overallValue.type,
        MarkupValueType.percentage,
      );
    });

    test('toDomain maps overall markup value type: amount', () {
      final data = EstimationTestDataMapFactory.createFakeEstimationData(
        overallMarkupValueType: 'amount',
      );
      final domain = CostEstimateDto.fromJson(data).toDomain();
      expect(
        domain.markupConfiguration.overallValue.type,
        MarkupValueType.amount,
      );
    });

    test('toDomain throws ArgumentError for unknown markup type', () {
      final data = EstimationTestDataMapFactory.createFakeEstimationData(
        markupType: 'unknown-type',
      );
      expect(
        () => CostEstimateDto.fromJson(data).toDomain(),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('toDomain throws ArgumentError for unknown markup value type', () {
      final data = EstimationTestDataMapFactory.createFakeEstimationData(
        overallMarkupValueType: 'unknown-value',
      );
      expect(
        () => CostEstimateDto.fromJson(data).toDomain(),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('fromJson should handle null numeric fields gracefully', () {
      final dto = CostEstimateDto.fromJson(jsonWithNulls);

      const expected = CostEstimateDto(
        id: '123',
        projectId: 'p1',
        estimateName: 'Test Estimate',
        estimateDescription: null,
        creatorUserId: 'user1',
        markupType: null,
        overallMarkupValueType: null,
        overallMarkupValue: null,
        materialMarkupValueType: null,
        materialMarkupValue: null,
        laborMarkupValueType: null,
        laborMarkupValue: null,
        equipmentMarkupValueType: null,
        equipmentMarkupValue: null,
        totalCost: null,
        isLocked: false,
        lockedByUserID: null,
        lockedAt: null,
        createdAt: '2025-09-19T10:00:00Z',
        updatedAt: '2025-09-20T10:00:00Z',
      );

      expect(dto, equals(expected));
    });

    test('toDomain should handle null fields with default values', () {
      final dto = CostEstimateDto.fromJson(jsonWithNulls);
      final domain = dto.toDomain();

      final expected = CostEstimate(
        id: '123',
        projectId: 'p1',
        estimateName: 'Test Estimate',
        estimateDescription: null,
        creatorUserId: 'user1',
        markupConfiguration: const MarkupConfiguration(
          overallType: MarkupType.overall,
          overallValue: MarkupValue(
            type: MarkupValueType.percentage,
            value: 0.0,
          ),
        ),
        totalCost: 0.0,
        lockStatus: const UnlockedStatus(),
        createdAt: DateTime.parse('2025-09-19T10:00:00Z'),
        updatedAt: DateTime.parse('2025-09-20T10:00:00Z'),
      );

      expect(domain, equals(expected));
    });

    test('fromDomain should convert domain entity to DTO correctly', () {
      final sampleData = EstimationTestDataMapFactory.createFakeEstimationData(
        isLocked: true,
        lockedByUserId: 'locking-user',
        lockedAt: '2025-01-01T10:00:00.000Z',
      );
      final originalDto = CostEstimateDto.fromJson(sampleData);
      final domain = originalDto.toDomain();

      final convertedDto = CostEstimateDto.fromDomain(domain);

      expect(convertedDto, equals(originalDto));
    });

    test('fromDomain should map MarkupType.granular correctly', () {
      final sampleData = EstimationTestDataMapFactory.createFakeEstimationData(
        markupType: 'granular',
      );
      final originalDto = CostEstimateDto.fromJson(sampleData);
      final domain = originalDto.toDomain();

      final convertedDto = CostEstimateDto.fromDomain(domain);

      expect(convertedDto.markupType, equals('granular'));
      expect(domain.markupConfiguration.overallType, MarkupType.granular);
    });

    test('fromDomain should map MarkupValueType.amount correctly', () {
      final sampleData = EstimationTestDataMapFactory.createFakeEstimationData(
        overallMarkupValueType: 'amount',
        materialMarkupValueType: 'amount',
        laborMarkupValueType: 'amount',
        equipmentMarkupValueType: 'amount',
        isLocked: true,
        lockedByUserId: 'locking-user',
        lockedAt: '2025-01-01T10:00:00.000Z',
      );
      final originalDto = CostEstimateDto.fromJson(sampleData);
      final domain = originalDto.toDomain();

      final convertedDto = CostEstimateDto.fromDomain(domain);

      expect(convertedDto, equals(originalDto));
    });
  });
}
