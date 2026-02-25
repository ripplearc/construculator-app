import 'package:construculator/features/estimation/data/models/cost_estimation_log_dto.dart';
import 'package:construculator/features/estimation/domain/entities/cost_estimation_activity_type.dart';
import 'package:construculator/features/estimation/domain/entities/cost_estimation_log_entity.dart';
import 'package:construculator/libraries/auth/domain/entities/user_profile_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CostEstimationLogDto', () {
    final testDto = CostEstimationLogDto(
      id: 'log-123',
      estimateId: 'estimate-456',
      activity: 'costEstimationRenamed',
      user: const {
        'id': 'user-123',
        'credential_id': 'cred-456',
        'first_name': 'John',
        'last_name': 'Doe',
        'professional_role': 'Project Manager',
        'profile_photo_url': 'https://example.com/photo.jpg',
      },
      activityDetails: const {
        'oldName': 'Old Estimation',
        'newName': 'New Estimation',
      },
      loggedAt: '2025-02-25T14:30:00.000Z',
    );

    final testJson = {
      'id': 'log-123',
      'estimate_id': 'estimate-456',
      'activity': 'costEstimationRenamed',
      'user': {
        'id': 'user-123',
        'credential_id': 'cred-456',
        'first_name': 'John',
        'last_name': 'Doe',
        'professional_role': 'Project Manager',
        'profile_photo_url': 'https://example.com/photo.jpg',
      },
      'activity_details': {
        'oldName': 'Old Estimation',
        'newName': 'New Estimation',
      },
      'logged_at': '2025-02-25T14:30:00.000Z',
    };

    final testEntity = CostEstimationLog(
      id: 'log-123',
      estimateId: 'estimate-456',
      activity: CostEstimationActivityType.costEstimationRenamed,
      user: const UserProfile(
        id: 'user-123',
        credentialId: 'cred-456',
        firstName: 'John',
        lastName: 'Doe',
        professionalRole: 'Project Manager',
        profilePhotoUrl: 'https://example.com/photo.jpg',
      ),
      activityDetails: const {
        'oldName': 'Old Estimation',
        'newName': 'New Estimation',
      },
      loggedAt: DateTime.parse('2025-02-25T14:30:00.000Z'),
    );

    group('fromJson', () {
      test('creates DTO from complete JSON', () {
        final dto = CostEstimationLogDto.fromJson(testJson);

        expect(dto, testDto);
      });

      test('handles snake_case to camelCase conversion', () {
        final dto = CostEstimationLogDto.fromJson(testJson);

        expect(dto, testDto);
      });

      test('creates DTO for cost item added activity', () {
        final json = {
          'id': 'log-789',
          'estimate_id': 'estimate-123',
          'activity': 'costItemAdded',
          'user': testJson['user'],
          'activity_details': {
            'costItemId': 'item-123',
            'costItemType': 'material',
            'description': 'Concrete',
          },
          'logged_at': '2025-02-25T15:00:00.000Z',
        };

        final expectedDto = CostEstimationLogDto(
          id: 'log-789',
          estimateId: 'estimate-123',
          activity: 'costItemAdded',
          user: testJson['user'] as Map<String, dynamic>,
          activityDetails: const {
            'costItemId': 'item-123',
            'costItemType': 'material',
            'description': 'Concrete',
          },
          loggedAt: '2025-02-25T15:00:00.000Z',
        );

        final dto = CostEstimationLogDto.fromJson(json);

        expect(dto, expectedDto);
      });

      test('creates DTO with empty activity details', () {
        final json = {
          'id': 'log-999',
          'estimate_id': 'estimate-456',
          'activity': 'costEstimationLocked',
          'user': testJson['user'],
          'activity_details': <String, dynamic>{},
          'logged_at': '2025-02-25T16:00:00.000Z',
        };

        final expectedDto = CostEstimationLogDto(
          id: 'log-999',
          estimateId: 'estimate-456',
          activity: 'costEstimationLocked',
          user: testJson['user'] as Map<String, dynamic>,
          activityDetails: const {},
          loggedAt: '2025-02-25T16:00:00.000Z',
        );

        final dto = CostEstimationLogDto.fromJson(json);

        expect(dto, expectedDto);
      });
    });

    group('toJson', () {
      test('converts DTO to JSON with all fields', () {
        final json = testDto.toJson();

        expect(json, testJson);
      });

      test('handles camelCase to snake_case conversion', () {
        final json = testDto.toJson();

        expect(json, testJson);
      });

      test('preserves nested user object structure', () {
        final json = testDto.toJson();

        expect(json, testJson);
      });
    });

    group('toDomain', () {
      test('converts DTO to domain entity', () {
        final entity = testDto.toDomain();

        expect(entity, testEntity);
      });

      test('converts activity string to enum', () {
        final dto = CostEstimationLogDto(
          id: 'log-456',
          estimateId: 'estimate-789',
          activity: 'costItemAdded',
          user: testDto.user,
          activityDetails: const {},
          loggedAt: '2025-02-25T14:30:00.000Z',
        );

        final expectedEntity = CostEstimationLog(
          id: 'log-456',
          estimateId: 'estimate-789',
          activity: CostEstimationActivityType.costItemAdded,
          user: testEntity.user,
          activityDetails: const {},
          loggedAt: DateTime.parse('2025-02-25T14:30:00.000Z'),
        );

        final entity = dto.toDomain();

        expect(entity, expectedEntity);
      });

      test('converts nested user JSON to UserProfile entity', () {
        final entity = testDto.toDomain();

        expect(entity, testEntity);
      });

      test('parses ISO 8601 timestamp to DateTime', () {
        final entity = testDto.toDomain();

        expect(entity, testEntity);
      });

      test('throws ArgumentError for invalid activity type', () {
        final dto = CostEstimationLogDto(
          id: 'log-invalid',
          estimateId: 'estimate-123',
          activity: 'invalidActivityType',
          user: testDto.user,
          activityDetails: const {},
          loggedAt: '2025-02-25T14:30:00.000Z',
        );

        expect(() => dto.toDomain(), throwsArgumentError);
      });
    });

    group('fromDomain', () {
      test('converts domain entity to DTO', () {
        final dto = CostEstimationLogDto.fromDomain(testEntity);

        expect(dto, testDto);
      });

      test('converts activity enum to string', () {
        final entity = CostEstimationLog(
          id: 'log-999',
          estimateId: 'estimate-123',
          activity: CostEstimationActivityType.taskAssigned,
          user: testEntity.user,
          activityDetails: const {},
          loggedAt: DateTime(2025, 2, 25),
        );

        final expectedDto = CostEstimationLogDto(
          id: 'log-999',
          estimateId: 'estimate-123',
          activity: 'taskAssigned',
          user: testDto.user,
          activityDetails: const {},
          loggedAt: DateTime(2025, 2, 25).toIso8601String(),
        );

        final dto = CostEstimationLogDto.fromDomain(entity);

        expect(dto, expectedDto);
      });

      test('converts UserProfile entity to nested JSON', () {
        final dto = CostEstimationLogDto.fromDomain(testEntity);

        expect(dto, testDto);
      });

      test('formats DateTime to ISO 8601 string', () {
        final dto = CostEstimationLogDto.fromDomain(testEntity);

        expect(dto, testDto);
      });
    });

    group('round-trip conversion', () {
      test('JSON -> DTO -> Entity conversion is consistent', () {
        final dto = CostEstimationLogDto.fromJson(testJson);
        final entity = dto.toDomain();

        expect(entity, testEntity);
      });

      test('Entity -> DTO -> JSON conversion is consistent', () {
        final dto = CostEstimationLogDto.fromDomain(testEntity);
        final json = dto.toJson();

        expect(json, testJson);
      });

      test('JSON -> DTO -> JSON produces identical result', () {
        final dto = CostEstimationLogDto.fromJson(testJson);
        final resultJson = dto.toJson();

        expect(resultJson, testJson);
      });

      test('Entity -> DTO -> Entity produces equivalent result', () {
        final dto = CostEstimationLogDto.fromDomain(testEntity);
        final resultEntity = dto.toDomain();

        expect(resultEntity, testEntity);
      });
    });

    group('Equatable', () {
      test('two DTOs with same values are equal', () {
        final dto1 = CostEstimationLogDto(
          id: 'log-123',
          estimateId: 'estimate-456',
          activity: 'costEstimationCreated',
          user: testDto.user,
          activityDetails: const {'key': 'value'},
          loggedAt: '2025-02-25T14:30:00.000Z',
        );

        final dto2 = CostEstimationLogDto(
          id: 'log-123',
          estimateId: 'estimate-456',
          activity: 'costEstimationCreated',
          user: testDto.user,
          activityDetails: const {'key': 'value'},
          loggedAt: '2025-02-25T14:30:00.000Z',
        );

        expect(dto1, equals(dto2));
      });

      test('two DTOs with different values are not equal', () {
        final dto1 = CostEstimationLogDto(
          id: 'log-123',
          estimateId: 'estimate-456',
          activity: 'costEstimationCreated',
          user: testDto.user,
          activityDetails: const {},
          loggedAt: '2025-02-25T14:30:00.000Z',
        );

        final dto2 = CostEstimationLogDto(
          id: 'log-456',
          estimateId: 'estimate-789',
          activity: 'costEstimationDeleted',
          user: testDto.user,
          activityDetails: const {},
          loggedAt: '2025-02-26T10:00:00.000Z',
        );

        expect(dto1, isNot(equals(dto2)));
      });
    });
  });
}
