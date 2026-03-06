import 'package:construculator/libraries/auth/data/models/user_profile_dto.dart';
import 'package:construculator/libraries/auth/domain/entities/user_profile_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserProfileDto', () {
    const testDto = UserProfileDto(
      id: 'user-123',
      credentialId: 'cred-456',
      firstName: 'John',
      lastName: 'Doe',
      professionalRole: 'Project Manager',
      profilePhotoUrl: 'https://example.com/photo.jpg',
    );

    final testJson = {
      'id': 'user-123',
      'credential_id': 'cred-456',
      'first_name': 'John',
      'last_name': 'Doe',
      'professional_role': 'Project Manager',
      'profile_photo_url': 'https://example.com/photo.jpg',
    };

    const testEntity = UserProfile(
      id: 'user-123',
      credentialId: 'cred-456',
      firstName: 'John',
      lastName: 'Doe',
      professionalRole: 'Project Manager',
      profilePhotoUrl: 'https://example.com/photo.jpg',
    );

    group('fromJson', () {
      test('creates DTO from complete JSON', () {
        final dto = UserProfileDto.fromJson(testJson);

        expect(dto, testDto);
      });

      test('creates DTO from JSON with null optional fields', () {
        final json = {
          'id': 'user-123',
          'credential_id': null,
          'first_name': 'Jane',
          'last_name': 'Smith',
          'professional_role': 'Engineer',
          'profile_photo_url': null,
        };

        const expectedDto = UserProfileDto(
          id: 'user-123',
          firstName: 'Jane',
          lastName: 'Smith',
          professionalRole: 'Engineer',
        );

        final dto = UserProfileDto.fromJson(json);

        expect(dto, expectedDto);
      });

      test('handles snake_case to camelCase conversion', () {
        final dto = UserProfileDto.fromJson(testJson);

        expect(dto, testDto);
      });
    });

    group('toJson', () {
      test('converts DTO to JSON with all fields', () {
        final json = testDto.toJson();

        expect(json, testJson);
      });

      test('converts DTO to JSON with null optional fields', () {
        const dto = UserProfileDto(
          id: 'user-456',
          firstName: 'Jane',
          lastName: 'Smith',
          professionalRole: 'Engineer',
        );

        final expectedJson = {
          'id': 'user-456',
          'credential_id': null,
          'first_name': 'Jane',
          'last_name': 'Smith',
          'professional_role': 'Engineer',
          'profile_photo_url': null,
        };

        final json = dto.toJson();

        expect(json, expectedJson);
      });

      test('handles camelCase to snake_case conversion', () {
        final json = testDto.toJson();

        expect(json, testJson);
      });
    });

    group('toDomain', () {
      test('converts DTO to domain entity', () {
        final entity = testDto.toDomain();

        expect(entity, testEntity);
      });

      test('preserves null optional fields', () {
        const dto = UserProfileDto(
          id: 'user-789',
          firstName: 'Test',
          lastName: 'User',
          professionalRole: 'Tester',
        );

        const expectedEntity = UserProfile(
          id: 'user-789',
          firstName: 'Test',
          lastName: 'User',
          professionalRole: 'Tester',
        );

        final entity = dto.toDomain();

        expect(entity, expectedEntity);
      });
    });

    group('fromDomain', () {
      test('converts domain entity to DTO', () {
        final dto = UserProfileDto.fromDomain(testEntity);

        expect(dto, testDto);
      });

      test('preserves null optional fields', () {
        const entity = UserProfile(
          id: 'user-999',
          firstName: 'Another',
          lastName: 'User',
          professionalRole: 'Role',
        );

        const expectedDto = UserProfileDto(
          id: 'user-999',
          firstName: 'Another',
          lastName: 'User',
          professionalRole: 'Role',
        );

        final dto = UserProfileDto.fromDomain(entity);

        expect(dto, expectedDto);
      });
    });

    group('round-trip conversion', () {
      test('JSON -> DTO -> Entity conversion is consistent', () {
        final dto = UserProfileDto.fromJson(testJson);
        final entity = dto.toDomain();

        expect(entity, testEntity);
      });

      test('Entity -> DTO -> JSON conversion is consistent', () {
        final dto = UserProfileDto.fromDomain(testEntity);
        final json = dto.toJson();

        expect(json, testJson);
      });

      test('JSON -> DTO -> JSON produces identical result', () {
        final dto = UserProfileDto.fromJson(testJson);
        final resultJson = dto.toJson();

        expect(resultJson, equals(testJson));
      });

      test('Entity -> DTO -> Entity produces equivalent result', () {
        final dto = UserProfileDto.fromDomain(testEntity);
        final resultEntity = dto.toDomain();

        expect(resultEntity, equals(testEntity));
      });
    });

    group('Equatable', () {
      test('two DTOs with same values are equal', () {
        const dto1 = UserProfileDto(
          id: 'user-123',
          credentialId: 'cred-456',
          firstName: 'John',
          lastName: 'Doe',
          professionalRole: 'Project Manager',
          profilePhotoUrl: 'https://example.com/photo.jpg',
        );

        const dto2 = UserProfileDto(
          id: 'user-123',
          credentialId: 'cred-456',
          firstName: 'John',
          lastName: 'Doe',
          professionalRole: 'Project Manager',
          profilePhotoUrl: 'https://example.com/photo.jpg',
        );

        expect(dto1, equals(dto2));
      });

      test('two DTOs with different values are not equal', () {
        const dto1 = UserProfileDto(
          id: 'user-123',
          firstName: 'John',
          lastName: 'Doe',
          professionalRole: 'Project Manager',
        );

        const dto2 = UserProfileDto(
          id: 'user-456',
          firstName: 'Jane',
          lastName: 'Smith',
          professionalRole: 'Engineer',
        );

        expect(dto1, isNot(equals(dto2)));
      });
    });
  });
}
