import 'package:construculator/features/estimation/data/models/cost_estimate_dto.dart';
import 'package:construculator/features/estimation/domain/entities/cost_estimate_entity.dart';
import 'package:construculator/features/estimation/domain/entities/enums.dart';
import 'package:construculator/features/estimation/domain/entities/lock_status_entity.dart';
import 'package:construculator/features/estimation/domain/entities/markup_configuration_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final sampleJson = {
    'id': '123',
    'project_id': 'p1',
    'estimate_name': 'Test Estimate',
    'estimate_description': 'Description',
    'creator_user_id': 'user1',
    'markup_type': 'overall',
    'overall_markup_value_type': 'percentage',
    'overall_markup_value': 10,
    'material_markup_value_type': 'amount',
    'material_markup_value': 200,
    'labor_markup_value_type': 'percentage',
    'labor_markup_value': 5,
    'equipment_markup_value_type': 'amount',
    'equipment_markup_value': 50,
    'total_cost': 1000,
    'is_locked': true,
    'locked_by_user_id': 'user2',
    'locked_at': '2025-09-20T12:00:00Z',
    'created_at': '2025-09-19T10:00:00Z',
    'updated_at': '2025-09-20T10:00:00Z',
  };

  group('CostEstimateDto', () {
    test('fromJson should parse all fields correctly', () {
      final dto = CostEstimateDto.fromJson(sampleJson);

      expect(dto.id, '123');
      expect(dto.projectId, 'p1');
      expect(dto.estimateName, 'Test Estimate');
      expect(dto.estimateDescription, 'Description');
      expect(dto.creatorUserId, 'user1');

      expect(dto.markupType, 'overall');

      expect(dto.overallMarkupValueType, 'percentage');
      expect(dto.overallMarkupValue, 10.0);

      expect(dto.materialMarkupValueType, 'amount');
      expect(dto.materialMarkupValue, 200.0);

      expect(dto.laborMarkupValueType, 'percentage');
      expect(dto.laborMarkupValue, 5.0);

      expect(dto.equipmentMarkupValueType, 'amount');
      expect(dto.equipmentMarkupValue, 50.0);

      expect(dto.totalCost, 1000.0);
      expect(dto.isLocked, true);
      expect(dto.lockedByUserID, 'user2');
      expect(dto.lockedAt, '2025-09-20T12:00:00Z');
      expect(dto.createdAt, '2025-09-19T10:00:00Z');
      expect(dto.updatedAt, '2025-09-20T10:00:00Z');
    });

    test('toJson should output the same map as input', () {
      final dto = CostEstimateDto.fromJson(sampleJson);
      final json = dto.toJson();

      expect(json, equals(sampleJson));
    });

    test(
      'toDomain should map all fields and types correctly (nullable granular parts)',
      () {
        final dto = CostEstimateDto.fromJson(sampleJson);
        final domain = dto.toDomain();

        // basic domain type
        expect(domain, isA<CostEstimate>());

        // Scalars
        expect(domain.id, dto.id);
        expect(domain.projectId, dto.projectId);
        expect(domain.estimateName, dto.estimateName);
        expect(domain.estimateDescription, dto.estimateDescription);
        expect(domain.creatorUserId, dto.creatorUserId);
        expect(domain.totalCost, dto.totalCost);

        // MarkupConfiguration: overallValue (required)
        final MarkupConfiguration config = domain.markupConfiguration;
        expect(config.overallValue, isA<MarkupValue>());
        expect(config.overallValue.value, dto.overallMarkupValue);
        expect(config.overallValue.type, isA<MarkupValueType>());

        // overallType is required and should be a MarkupType enum
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

        // Lock status
        expect(domain.lockStatus, isA<LockStatus>());
        expect(domain.lockStatus.isLocked, true);

        // Dates
        expect(domain.createdAt, DateTime.parse(dto.createdAt));
        expect(domain.updatedAt, DateTime.parse(dto.updatedAt));
      },
    );

    test('toDomain should create unlocked LockStatus when isLocked=false', () {
      final unlockedJson = Map<String, dynamic>.from(sampleJson)
        ..['is_locked'] = false;

      final dto = CostEstimateDto.fromJson(unlockedJson);
      final domain = dto.toDomain();

      expect(domain.lockStatus.isLocked, false);
      expect(domain.lockStatus, isA<LockStatus>());
    });
  });
}
