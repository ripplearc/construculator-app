import 'package:construculator/features/estimation/data/models/cost_estimate_dto.dart';
import 'package:construculator/features/estimation/domain/entities/cost_estimate_entity.dart';
import 'package:construculator/features/estimation/domain/entities/enums.dart';
import 'package:construculator/features/estimation/domain/entities/lock_status_entity.dart';
import 'package:construculator/features/estimation/domain/entities/markup_configuration_entity.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_estimation_data_helper.dart';

void main() {
  group('CostEstimateDto', () {
    test('fromJson should parse all fields correctly', () {
      final sampleData = TestEstimationDataHelper.createFakeEstimationData(
        isLocked: true,
        lockedByUserId: 'locking-user',
        lockedAt: '2025-01-01T10:00:00.000Z',
      );
      final dto = CostEstimateDto.fromJson(sampleData);

      expect(dto.id, estimateIdDefault);
      expect(dto.projectId, testProjectId);
      expect(dto.estimateName, estimateNameDefault);
      expect(dto.estimateDescription, estimateDescDefault);
      expect(dto.creatorUserId, userIdDefault);

      expect(dto.markupType, markupTypeOverall);

      expect(dto.overallMarkupValueType, markupValueTypePercentage);
      expect(dto.overallMarkupValue, overallMarkupDefault);

      expect(dto.materialMarkupValueType, markupValueTypePercentage);
      expect(dto.materialMarkupValue, materialMarkupDefault);

      expect(dto.laborMarkupValueType, markupValueTypePercentage);
      expect(dto.laborMarkupValue, laborMarkupDefault);

      expect(dto.equipmentMarkupValueType, markupValueTypePercentage);
      expect(dto.equipmentMarkupValue, equipmentMarkupDefault);

      expect(dto.totalCost, totalCostDefault);
      expect(dto.isLocked, true);
      expect(dto.lockedByUserID, 'locking-user');
      expect(dto.lockedAt, '2025-01-01T10:00:00.000Z');
      expect(dto.createdAt, timestampDefault);
      expect(dto.updatedAt, timestampDefault);
    });

    test('toJson should output the same map as input', () {
      final sampleData = TestEstimationDataHelper.createFakeEstimationData();
      final dto = CostEstimateDto.fromJson(sampleData);
      final json = dto.toJson();

      expect(json, equals(sampleData));
    });

    test(
      'toDomain should map all fields and types correctly (nullable granular parts)',
      () {
        final sampleData = TestEstimationDataHelper.createFakeEstimationData(
          isLocked: true,
          lockedByUserId: 'locking-user',
          lockedAt: '2025-01-01T10:00:00.000Z',
        );
        final dto = CostEstimateDto.fromJson(sampleData);
        final domain = dto.toDomain();

        expect(domain, isA<CostEstimate>());

        expect(domain.id, dto.id);
        expect(domain.projectId, dto.projectId);
        expect(domain.estimateName, dto.estimateName);
        expect(domain.estimateDescription, dto.estimateDescription);
        expect(domain.creatorUserId, dto.creatorUserId);
        expect(domain.totalCost, dto.totalCost);

        final MarkupConfiguration config = domain.markupConfiguration;
        expect(config.overallValue, isA<MarkupValue>());
        expect(config.overallValue.value, dto.overallMarkupValue);
        expect(config.overallValue.type, isA<MarkupValueType>());

        expect(config.overallType, isA<MarkupType>());

        expect(config.materialValue, isA<MarkupValue>());
        expect(config.materialValue!.type, isA<MarkupValueType>());
        expect(config.materialValue!.value, dto.materialMarkupValue);

        expect(config.laborValue, isA<MarkupValue>());
        expect(config.laborValue!.type, isA<MarkupValueType>());
        expect(config.laborValue!.value, dto.laborMarkupValue);

        expect(config.equipmentValue, isA<MarkupValue>());
        expect(config.equipmentValue!.type, isA<MarkupValueType>());
        expect(config.equipmentValue!.value, dto.equipmentMarkupValue);

        expect(domain.lockStatus, isA<LockedStatus>());

        final lockedStatus = domain.lockStatus as LockedStatus;
        expect(lockedStatus.lockedByUserId, dto.lockedByUserID);
        expect(lockedStatus.lockedAt, DateTime.parse(dto.lockedAt));
        expect(lockedStatus.isLocked, true);
        expect(lockedStatus.isLockedBy('locking-user'), isTrue);
        expect(lockedStatus.isLockedBy('different-user'), isFalse);

        expect(domain.createdAt, DateTime.parse(dto.createdAt));
        expect(domain.updatedAt, DateTime.parse(dto.updatedAt));
      },
    );

    test(
      'toDomain should create CostEstimate with UnlockedStatus when isLocked is false',
      () {
        final unlockedJson = Map<String, dynamic>.from(
          TestEstimationDataHelper.createFakeEstimationData(),
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
      final data = TestEstimationDataHelper.createFakeEstimationData();

      expect(
        CostEstimateDto.fromJson(data),
        equals(CostEstimateDto.fromJson(data)),
      );
    });

    test('toDomain maps markup type: overall', () {
      final data = TestEstimationDataHelper.createFakeEstimationData(
        markupType: 'overall',
      );
      final domain = CostEstimateDto.fromJson(data).toDomain();
      expect(domain.markupConfiguration.overallType, MarkupType.overall);
    });

    test('toDomain maps markup type: granular', () {
      final data = TestEstimationDataHelper.createFakeEstimationData(
        markupType: 'granular',
      );
      final domain = CostEstimateDto.fromJson(data).toDomain();
      expect(domain.markupConfiguration.overallType, MarkupType.granular);
    });

    test('toDomain maps overall markup value type: percentage', () {
      final data = TestEstimationDataHelper.createFakeEstimationData(
        overallMarkupValueType: 'percentage',
      );
      final domain = CostEstimateDto.fromJson(data).toDomain();
      expect(
        domain.markupConfiguration.overallValue.type,
        MarkupValueType.percentage,
      );
    });

    test('toDomain maps overall markup value type: amount', () {
      final data = TestEstimationDataHelper.createFakeEstimationData(
        overallMarkupValueType: 'amount',
      );
      final domain = CostEstimateDto.fromJson(data).toDomain();
      expect(
        domain.markupConfiguration.overallValue.type,
        MarkupValueType.amount,
      );
    });

    test('toDomain throws ArgumentError for unknown markup type', () {
      final data = TestEstimationDataHelper.createFakeEstimationData(
        markupType: 'unknown-type',
      );
      expect(
        () => CostEstimateDto.fromJson(data).toDomain(),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('toDomain throws ArgumentError for unknown markup value type', () {
      final data = TestEstimationDataHelper.createFakeEstimationData(
        overallMarkupValueType: 'unknown-value',
      );
      expect(
        () => CostEstimateDto.fromJson(data).toDomain(),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
