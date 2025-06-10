import 'package:flutter_test/flutter_test.dart';
import 'package:construculator/libraries/auth/data/models/auth_user.dart';
import 'package:construculator/libraries/auth/data/types/auth_types.dart';

void main() {
  group('User Model', () {
    group('fromJson', () {
      test('should create User from valid JSON', () {
        // Arrange
        final json = <String, dynamic>{
          'id': 'user123',
          'credential_id': 'cred456',
          'email': 'test@example.com',
          'phone': '+1234567890',
          'first_name': 'John',
          'last_name': 'Doe',
          'professional_role': 'Developer',
          'profile_photo_url': 'https://example.com/photo.jpg',
          'created_at': '2023-01-01T00:00:00.000Z',
          'updated_at': '2023-01-02T00:00:00.000Z',
          'user_status': 'active',
          'user_preferences': <String, dynamic>{'theme': 'dark', 'notifications': true},
        };

        // Act
        final user = User.fromJson(json);

        // Assert
        expect(user.id, 'user123');
        expect(user.credentialId, 'cred456');
        expect(user.email, 'test@example.com');
        expect(user.phone, '+1234567890');
        expect(user.firstName, 'John');
        expect(user.lastName, 'Doe');
        expect(user.professionalRole, 'Developer');
        expect(user.profilePhotoUrl, 'https://example.com/photo.jpg');
        expect(user.createdAt, DateTime.parse('2023-01-01T00:00:00.000Z'));
        expect(user.updatedAt, DateTime.parse('2023-01-02T00:00:00.000Z'));
        expect(user.userStatus, UserProfileStatus.active);
        expect(user.userPreferences, {'theme': 'dark', 'notifications': true});
      });

      test('should create User from JSON with null phone', () {
        // Arrange
        final json = <String, dynamic>{
          'id': 'user123',
          'credential_id': 'cred456',
          'email': 'test@example.com',
          'phone': null,
          'first_name': 'John',
          'last_name': 'Doe',
          'professional_role': 'Developer',
          'profile_photo_url': null,
          'created_at': '2023-01-01T00:00:00.000Z',
          'updated_at': '2023-01-02T00:00:00.000Z',
          'user_status': 'inactive',
          'user_preferences': <String, dynamic>{},
        };

        // Act
        final user = User.fromJson(json);

        // Assert
        expect(user.phone, isNull);
        expect(user.profilePhotoUrl, isNull);
        expect(user.userStatus, UserProfileStatus.inactive);
        expect(user.userPreferences, isEmpty);
      });

      test('should handle inactive user status', () {
        // Arrange
        final json = <String, dynamic>{
          'id': 'user123',
          'credential_id': 'cred456',
          'email': 'test@example.com',
          'phone': null,
          'first_name': 'John',
          'last_name': 'Doe',
          'professional_role': 'Developer',
          'profile_photo_url': null,
          'created_at': '2023-01-01T00:00:00.000Z',
          'updated_at': '2023-01-02T00:00:00.000Z',
          'user_status': 'inactive',
          'user_preferences': <String, dynamic>{},
        };

        // Act
        final user = User.fromJson(json);

        // Assert
        expect(user.userStatus, UserProfileStatus.inactive);
      });

      test('should default to inactive for unknown user status', () {
        // Arrange
        final json = <String, dynamic>{
          'id': 'user123',
          'credential_id': 'cred456',
          'email': 'test@example.com',
          'phone': null,
          'first_name': 'John',
          'last_name': 'Doe',
          'professional_role': 'Developer',
          'profile_photo_url': null,
          'created_at': '2023-01-01T00:00:00.000Z',
          'updated_at': '2023-01-02T00:00:00.000Z',
          'user_status': 'unknown_status',
          'user_preferences': <String, dynamic>{},
        };

        // Act
        final user = User.fromJson(json);

        // Assert
        expect(user.userStatus, UserProfileStatus.inactive);
      });

      test('should throw when required fields are missing', () {
        // Arrange
        final json = <String, dynamic>{
          'id': 'user123',
          // Missing credential_id
          'email': 'test@example.com',
        };

        // Act & Assert
        expect(() => User.fromJson(json), throwsA(isA<TypeError>()));
      });

      test('should throw when date format is invalid', () {
        // Arrange
        final json = <String, dynamic>{
          'id': 'user123',
          'credential_id': 'cred456',
          'email': 'test@example.com',
          'phone': null,
          'first_name': 'John',
          'last_name': 'Doe',
          'professional_role': 'Developer',
          'profile_photo_url': null,
          'created_at': 'invalid-date',
          'updated_at': '2023-01-02T00:00:00.000Z',
          'user_status': 'active',
          'user_preferences': <String, dynamic>{},
        };

        // Act & Assert
        expect(() => User.fromJson(json), throwsA(isA<FormatException>()));
      });

      test('should handle empty user preferences', () {
        // Arrange
        final json = <String, dynamic>{
          'id': 'user123',
          'credential_id': 'cred456',
          'email': 'test@example.com',
          'phone': null,
          'first_name': 'John',
          'last_name': 'Doe',
          'professional_role': 'Developer',
          'profile_photo_url': null,
          'created_at': '2023-01-01T00:00:00.000Z',
          'updated_at': '2023-01-02T00:00:00.000Z',
          'user_status': 'active',
          'user_preferences': <String, dynamic>{},
        };

        // Act
        final user = User.fromJson(json);

        // Assert
        expect(user.userPreferences, isEmpty);
      });

      test('should handle complex user preferences', () {
        // Arrange
        final complexPreferences = <String, dynamic>{
          'theme': 'dark',
          'notifications': {
            'email': true,
            'push': false,
            'sms': true,
          },
          'language': 'en',
          'timezone': 'UTC',
          'features': ['feature1', 'feature2'],
        };
        
        final json = <String, dynamic>{
          'id': 'user123',
          'credential_id': 'cred456',
          'email': 'test@example.com',
          'phone': null,
          'first_name': 'John',
          'last_name': 'Doe',
          'professional_role': 'Developer',
          'profile_photo_url': null,
          'created_at': '2023-01-01T00:00:00.000Z',
          'updated_at': '2023-01-02T00:00:00.000Z',
          'user_status': 'active',
          'user_preferences': complexPreferences,
        };

        // Act
        final user = User.fromJson(json);

        // Assert
        expect(user.userPreferences, complexPreferences);
        expect(user.userPreferences['notifications']['email'], true);
        expect(user.userPreferences['features'], ['feature1', 'feature2']);
      });
    });

    group('toJson', () {
      test('should convert User to JSON correctly', () {
        // Arrange
        final user = User(
          id: 'user123',
          credentialId: 'cred456',
          email: 'test@example.com',
          phone: '+1234567890',
          firstName: 'John',
          lastName: 'Doe',
          professionalRole: 'Developer',
          profilePhotoUrl: 'https://example.com/photo.jpg',
          createdAt: DateTime.parse('2023-01-01T00:00:00.000Z'),
          updatedAt: DateTime.parse('2023-01-02T00:00:00.000Z'),
          userStatus: UserProfileStatus.active,
          userPreferences: {'theme': 'dark', 'notifications': true},
        );

        // Act
        final json = user.toJson();

        // Assert
        expect(json, {
          'id': 'user123',
          'credential_id': 'cred456',
          'email': 'test@example.com',
          'phone': '+1234567890',
          'first_name': 'John',
          'last_name': 'Doe',
          'professional_role': 'Developer',
          'profile_photo_url': 'https://example.com/photo.jpg',
          'created_at': '2023-01-01T00:00:00.000Z',
          'updated_at': '2023-01-02T00:00:00.000Z',
          'user_status': 'active',
          'user_preferences': {'theme': 'dark', 'notifications': true},
        });
      });

      test('should handle null values in toJson', () {
        // Arrange
        final user = User(
          id: 'user123',
          credentialId: 'cred456',
          email: 'test@example.com',
          phone: null,
          firstName: 'John',
          lastName: 'Doe',
          professionalRole: 'Developer',
          profilePhotoUrl: null,
          createdAt: DateTime.parse('2023-01-01T00:00:00.000Z'),
          updatedAt: DateTime.parse('2023-01-02T00:00:00.000Z'),
          userStatus: UserProfileStatus.inactive,
          userPreferences: {},
        );

        // Act
        final json = user.toJson();

        // Assert
        expect(json['phone'], isNull);
        expect(json['profile_photo_url'], isNull);
        expect(json['user_status'], 'inactive');
        expect(json['user_preferences'], isEmpty);
      });

      test('should convert UserProfileStatus enum correctly', () {
        // Arrange - Test active status
        final activeUser = User(
          id: 'user123',
          credentialId: 'cred456',
          email: 'test@example.com',
          firstName: 'John',
          lastName: 'Doe',
          professionalRole: 'Developer',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          userStatus: UserProfileStatus.active,
          userPreferences: {},
        );

        // Arrange - Test inactive status
        final inactiveUser = User(
          id: 'user456',
          credentialId: 'cred789',
          email: 'test2@example.com',
          firstName: 'Jane',
          lastName: 'Smith',
          professionalRole: 'Designer',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          userStatus: UserProfileStatus.inactive,
          userPreferences: {},
        );

        // Act
        final activeJson = activeUser.toJson();
        final inactiveJson = inactiveUser.toJson();

        // Assert
        expect(activeJson['user_status'], 'active');
        expect(inactiveJson['user_status'], 'inactive');
      });

      test('should handle complex user preferences in toJson', () {
        // Arrange
        final complexPreferences = <String, dynamic>{
          'theme': 'dark',
          'notifications': {
            'email': true,
            'push': false,
          },
          'features': ['feature1', 'feature2'],
        };
        
        final user = User(
          id: 'user123',
          credentialId: 'cred456',
          email: 'test@example.com',
          firstName: 'John',
          lastName: 'Doe',
          professionalRole: 'Developer',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          userStatus: UserProfileStatus.active,
          userPreferences: complexPreferences,
        );

        // Act
        final json = user.toJson();

        // Assert
        expect(json['user_preferences'], complexPreferences);
      });
    });

    group('empty factory', () {
      test('should create empty User with default values', () {
        // Act
        final user = User.empty();

        // Assert
        expect(user.id, '');
        expect(user.credentialId, '');
        expect(user.email, '');
        expect(user.phone, '');
        expect(user.firstName, '');
        expect(user.lastName, '');
        expect(user.professionalRole, '');
        expect(user.profilePhotoUrl, '');
        expect(user.userStatus, UserProfileStatus.inactive);
        expect(user.userPreferences, isEmpty);
        expect(user.createdAt, isA<DateTime>());
        expect(user.updatedAt, isA<DateTime>());
      });

      test('should create empty User with recent timestamps', () {
        // Arrange
        final beforeCreation = DateTime.now();
        
        // Act
        final user = User.empty();
        
        // Arrange
        final afterCreation = DateTime.now();

        // Assert
        expect(user.createdAt.isAfter(beforeCreation.subtract(Duration(seconds: 1))), true);
        expect(user.createdAt.isBefore(afterCreation.add(Duration(seconds: 1))), true);
        expect(user.updatedAt.isAfter(beforeCreation.subtract(Duration(seconds: 1))), true);
        expect(user.updatedAt.isBefore(afterCreation.add(Duration(seconds: 1))), true);
      });
    });

    group('fullName getter', () {
      test('should return concatenated first and last name', () {
        // Arrange
        final user = User(
          id: 'user123',
          credentialId: 'cred456',
          email: 'test@example.com',
          firstName: 'John',
          lastName: 'Doe',
          professionalRole: 'Developer',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          userStatus: UserProfileStatus.active,
          userPreferences: {},
        );

        // Act
        final fullName = user.fullName;

        // Assert
        expect(fullName, 'John Doe');
      });

      test('should handle empty names', () {
        // Arrange
        final user = User.empty();

        // Act
        final fullName = user.fullName;

        // Assert
        expect(fullName, ' '); // Empty first name + space + empty last name
      });

      test('should handle single name', () {
        // Arrange
        final user = User(
          id: 'user123',
          credentialId: 'cred456',
          email: 'test@example.com',
          firstName: 'Madonna',
          lastName: '',
          professionalRole: 'Singer',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          userStatus: UserProfileStatus.active,
          userPreferences: {},
        );

        // Act
        final fullName = user.fullName;

        // Assert
        expect(fullName, 'Madonna ');
      });

      test('should handle names with special characters', () {
        // Arrange
        final user = User(
          id: 'user123',
          credentialId: 'cred456',
          email: 'test@example.com',
          firstName: 'José',
          lastName: 'García-López',
          professionalRole: 'Developer',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          userStatus: UserProfileStatus.active,
          userPreferences: {},
        );

        // Act
        final fullName = user.fullName;

        // Assert
        expect(fullName, 'José García-López');
      });

      test('should handle very long names', () {
        // Arrange
        final user = User(
          id: 'user123',
          credentialId: 'cred456',
          email: 'test@example.com',
          firstName: 'VeryLongFirstNameThatExceedsNormalLength',
          lastName: 'VeryLongLastNameThatAlsoExceedsNormalLength',
          professionalRole: 'Developer',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          userStatus: UserProfileStatus.active,
          userPreferences: {},
        );

        // Act
        final fullName = user.fullName;

        // Assert
        expect(fullName, 'VeryLongFirstNameThatExceedsNormalLength VeryLongLastNameThatAlsoExceedsNormalLength');
      });
    });

    group('copyWith', () {
      late User originalUser;

      setUp(() {
        originalUser = User(
          id: 'user123',
          credentialId: 'cred456',
          email: 'test@example.com',
          phone: '+1234567890',
          firstName: 'John',
          lastName: 'Doe',
          professionalRole: 'Developer',
          profilePhotoUrl: 'https://example.com/photo.jpg',
          createdAt: DateTime.parse('2023-01-01T00:00:00.000Z'),
          updatedAt: DateTime.parse('2023-01-02T00:00:00.000Z'),
          userStatus: UserProfileStatus.active,
          userPreferences: {'theme': 'dark', 'notifications': true},
        );
      });

      test('should return identical user when no parameters provided', () {
        // Act
        final copiedUser = originalUser.copyWith();

        // Assert
        expect(copiedUser.id, originalUser.id);
        expect(copiedUser.credentialId, originalUser.credentialId);
        expect(copiedUser.email, originalUser.email);
        expect(copiedUser.phone, originalUser.phone);
        expect(copiedUser.firstName, originalUser.firstName);
        expect(copiedUser.lastName, originalUser.lastName);
        expect(copiedUser.professionalRole, originalUser.professionalRole);
        expect(copiedUser.profilePhotoUrl, originalUser.profilePhotoUrl);
        expect(copiedUser.createdAt, originalUser.createdAt);
        expect(copiedUser.updatedAt, originalUser.updatedAt);
        expect(copiedUser.userStatus, originalUser.userStatus);
        expect(copiedUser.userPreferences, originalUser.userPreferences);
      });

      test('should update only id when provided', () {
        // Act
        final copiedUser = originalUser.copyWith(id: 'newId123');

        // Assert
        expect(copiedUser.id, 'newId123');
        expect(copiedUser.credentialId, originalUser.credentialId);
        expect(copiedUser.email, originalUser.email);
        // ... other fields should remain the same
      });

      test('should update only credentialId when provided', () {
        // Act
        final copiedUser = originalUser.copyWith(credentialId: 'newCred789');

        // Assert
        expect(copiedUser.id, originalUser.id);
        expect(copiedUser.credentialId, 'newCred789');
        expect(copiedUser.email, originalUser.email);
      });

      test('should update only email when provided', () {
        // Act
        final copiedUser = originalUser.copyWith(email: 'newemail@example.com');

        // Assert
        expect(copiedUser.email, 'newemail@example.com');
        expect(copiedUser.id, originalUser.id);
        expect(copiedUser.credentialId, originalUser.credentialId);
      });

      test('should update only phone when provided', () {
        // Act
        final copiedUser = originalUser.copyWith(phone: '+9876543210');

        // Assert
        expect(copiedUser.phone, '+9876543210');
        expect(copiedUser.id, originalUser.id);
        expect(copiedUser.email, originalUser.email);
      });

      test('should update only firstName when provided', () {
        // Act
        final copiedUser = originalUser.copyWith(firstName: 'Jane');

        // Assert
        expect(copiedUser.firstName, 'Jane');
        expect(copiedUser.lastName, originalUser.lastName);
        expect(copiedUser.fullName, 'Jane Doe');
      });

      test('should update only lastName when provided', () {
        // Act
        final copiedUser = originalUser.copyWith(lastName: 'Smith');

        // Assert
        expect(copiedUser.lastName, 'Smith');
        expect(copiedUser.firstName, originalUser.firstName);
        expect(copiedUser.fullName, 'John Smith');
      });

      test('should update only professionalRole when provided', () {
        // Act
        final copiedUser = originalUser.copyWith(professionalRole: 'Designer');

        // Assert
        expect(copiedUser.professionalRole, 'Designer');
        expect(copiedUser.firstName, originalUser.firstName);
        expect(copiedUser.lastName, originalUser.lastName);
      });

      test('should update only profilePhotoUrl when provided', () {
        // Act
        final copiedUser = originalUser.copyWith(profilePhotoUrl: 'https://newurl.com/photo.jpg');

        // Assert
        expect(copiedUser.profilePhotoUrl, 'https://newurl.com/photo.jpg');
        expect(copiedUser.id, originalUser.id);
        expect(copiedUser.email, originalUser.email);
      });

      test('should update only createdAt when provided', () {
        // Arrange
        final newCreatedAt = DateTime.parse('2024-01-01T00:00:00.000Z');

        // Act
        final copiedUser = originalUser.copyWith(createdAt: newCreatedAt);

        // Assert
        expect(copiedUser.createdAt, newCreatedAt);
        expect(copiedUser.updatedAt, originalUser.updatedAt);
        expect(copiedUser.id, originalUser.id);
      });

      test('should update only updatedAt when provided', () {
        // Arrange
        final newUpdatedAt = DateTime.parse('2024-01-02T00:00:00.000Z');

        // Act
        final copiedUser = originalUser.copyWith(updatedAt: newUpdatedAt);

        // Assert
        expect(copiedUser.updatedAt, newUpdatedAt);
        expect(copiedUser.createdAt, originalUser.createdAt);
        expect(copiedUser.id, originalUser.id);
      });

      test('should update only userStatus when provided', () {
        // Act
        final copiedUser = originalUser.copyWith(userStatus: UserProfileStatus.inactive);

        // Assert
        expect(copiedUser.userStatus, UserProfileStatus.inactive);
        expect(copiedUser.id, originalUser.id);
        expect(copiedUser.email, originalUser.email);
      });

      test('should update only userPreferences when provided', () {
        // Arrange
        final newPreferences = {'theme': 'light', 'language': 'es'};

        // Act
        final copiedUser = originalUser.copyWith(userPreferences: newPreferences);

        // Assert
        expect(copiedUser.userPreferences, newPreferences);
        expect(copiedUser.id, originalUser.id);
        expect(copiedUser.email, originalUser.email);
      });

      test('should update multiple fields when provided', () {
        // Arrange
        final newPreferences = {'theme': 'light'};
        final newUpdatedAt = DateTime.parse('2024-01-02T00:00:00.000Z');

        // Act
        final copiedUser = originalUser.copyWith(
          firstName: 'Jane',
          lastName: 'Smith',
          email: 'jane.smith@example.com',
          userStatus: UserProfileStatus.inactive,
          userPreferences: newPreferences,
          updatedAt: newUpdatedAt,
        );

        // Assert
        expect(copiedUser.firstName, 'Jane');
        expect(copiedUser.lastName, 'Smith');
        expect(copiedUser.email, 'jane.smith@example.com');
        expect(copiedUser.userStatus, UserProfileStatus.inactive);
        expect(copiedUser.userPreferences, newPreferences);
        expect(copiedUser.updatedAt, newUpdatedAt);
        expect(copiedUser.fullName, 'Jane Smith');
        
        // Unchanged fields
        expect(copiedUser.id, originalUser.id);
        expect(copiedUser.credentialId, originalUser.credentialId);
        expect(copiedUser.phone, originalUser.phone);
        expect(copiedUser.professionalRole, originalUser.professionalRole);
        expect(copiedUser.profilePhotoUrl, originalUser.profilePhotoUrl);
        expect(copiedUser.createdAt, originalUser.createdAt);
      });

      test('should handle null values in copyWith', () {
        // Arrange - Start with a user that has non-null values
        final userWithValues = User(
          id: 'user123',
          credentialId: 'cred456',
          email: 'test@example.com',
          phone: '+1234567890',
          firstName: 'John',
          lastName: 'Doe',
          professionalRole: 'Developer',
          profilePhotoUrl: 'https://example.com/photo.jpg',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          userStatus: UserProfileStatus.active,
          userPreferences: {'theme': 'dark'},
        );

        // Act - copyWith preserves original values when null is passed (due to ?? operator)
        final copiedUser = userWithValues.copyWith(
          phone: null,
          profilePhotoUrl: null,
        );

        // Assert - Values should remain the same since copyWith uses ?? operator
        expect(copiedUser.phone, '+1234567890'); // Original value preserved
        expect(copiedUser.profilePhotoUrl, 'https://example.com/photo.jpg'); // Original value preserved
        expect(copiedUser.id, userWithValues.id);
        expect(copiedUser.email, userWithValues.email);
      });

      test('should create new instance, not modify original', () {
        // Act
        final copiedUser = originalUser.copyWith(firstName: 'Jane');

        // Assert
        expect(originalUser.firstName, 'John'); // Original unchanged
        expect(copiedUser.firstName, 'Jane'); // Copy changed
        expect(identical(originalUser, copiedUser), false); // Different instances
      });
    });

    group('JSON round-trip', () {
      test('should maintain data integrity through fromJson -> toJson cycle', () {
        // Arrange
        final originalJson = <String, dynamic>{
          'id': 'user123',
          'credential_id': 'cred456',
          'email': 'test@example.com',
          'phone': '+1234567890',
          'first_name': 'John',
          'last_name': 'Doe',
          'professional_role': 'Developer',
          'profile_photo_url': 'https://example.com/photo.jpg',
          'created_at': '2023-01-01T00:00:00.000Z',
          'updated_at': '2023-01-02T00:00:00.000Z',
          'user_status': 'active',
          'user_preferences': <String, dynamic>{'theme': 'dark', 'notifications': true},
        };

        // Act
        final user = User.fromJson(originalJson);
        final resultJson = user.toJson();

        // Assert
        expect(resultJson, originalJson);
      });

      test('should maintain data integrity with null values through round-trip', () {
        // Arrange
        final originalJson = <String, dynamic>{
          'id': 'user123',
          'credential_id': 'cred456',
          'email': 'test@example.com',
          'phone': null,
          'first_name': 'John',
          'last_name': 'Doe',
          'professional_role': 'Developer',
          'profile_photo_url': null,
          'created_at': '2023-01-01T00:00:00.000Z',
          'updated_at': '2023-01-02T00:00:00.000Z',
          'user_status': 'inactive',
          'user_preferences': <String, dynamic>{},
        };

        // Act
        final user = User.fromJson(originalJson);
        final resultJson = user.toJson();

        // Assert
        expect(resultJson, originalJson);
      });

      test('should maintain complex preferences through round-trip', () {
        // Arrange
        final complexPreferences = <String, dynamic>{
          'theme': 'dark',
          'notifications': {
            'email': true,
            'push': false,
            'sms': true,
          },
          'language': 'en',
          'features': ['feature1', 'feature2'],
          'settings': {
            'autoSave': true,
            'timeout': 300,
          },
        };
        
        final originalJson = <String, dynamic>{
          'id': 'user123',
          'credential_id': 'cred456',
          'email': 'test@example.com',
          'phone': '+1234567890',
          'first_name': 'John',
          'last_name': 'Doe',
          'professional_role': 'Developer',
          'profile_photo_url': 'https://example.com/photo.jpg',
          'created_at': '2023-01-01T00:00:00.000Z',
          'updated_at': '2023-01-02T00:00:00.000Z',
          'user_status': 'active',
          'user_preferences': complexPreferences,
        };

        // Act
        final user = User.fromJson(originalJson);
        final resultJson = user.toJson();

        // Assert
        expect(resultJson, originalJson);
        expect(resultJson['user_preferences']['notifications']['email'], true);
        expect(resultJson['user_preferences']['features'], ['feature1', 'feature2']);
      });
    });

    group('Edge Cases and Error Handling', () {
      test('should handle empty strings in JSON', () {
        // Arrange
        final json = <String, dynamic>{
          'id': '',
          'credential_id': '',
          'email': '',
          'phone': '',
          'first_name': '',
          'last_name': '',
          'professional_role': '',
          'profile_photo_url': '',
          'created_at': '2023-01-01T00:00:00.000Z',
          'updated_at': '2023-01-02T00:00:00.000Z',
          'user_status': 'active',
          'user_preferences': <String, dynamic>{},
        };

        // Act
        final user = User.fromJson(json);

        // Assert
        expect(user.id, '');
        expect(user.credentialId, '');
        expect(user.email, '');
        expect(user.phone, '');
        expect(user.firstName, '');
        expect(user.lastName, '');
        expect(user.professionalRole, '');
        expect(user.profilePhotoUrl, '');
        expect(user.fullName, ' '); // Empty first + space + empty last
      });

      test('should handle very large user preferences', () {
        // Arrange
        final largePreferences = <String, dynamic>{};
        for (int i = 0; i < 100; i++) {
          largePreferences['key$i'] = 'value$i';
        }
        
        final user = User(
          id: 'user123',
          credentialId: 'cred456',
          email: 'test@example.com',
          firstName: 'John',
          lastName: 'Doe',
          professionalRole: 'Developer',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          userStatus: UserProfileStatus.active,
          userPreferences: largePreferences,
        );

        // Act
        final json = user.toJson();
        final reconstructedUser = User.fromJson(json);

        // Assert
        expect(reconstructedUser.userPreferences.length, 100);
        expect(reconstructedUser.userPreferences['key50'], 'value50');
      });
    });

    group('Equality and Identity', () {
      test('should create different instances with copyWith', () {
        // Arrange
        final user1 = User(
          id: 'user123',
          credentialId: 'cred456',
          email: 'test@example.com',
          firstName: 'John',
          lastName: 'Doe',
          professionalRole: 'Developer',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          userStatus: UserProfileStatus.active,
          userPreferences: {},
        );

        // Act
        final user2 = user1.copyWith();

        // Assert
        expect(identical(user1, user2), false);
        expect(user1.id, user2.id);
        expect(user1.email, user2.email);
      });

      test('should handle copyWith with all parameters', () {
        // Arrange
        final originalUser = User.empty();
        final newCreatedAt = DateTime.parse('2024-01-01T00:00:00.000Z');
        final newUpdatedAt = DateTime.parse('2024-01-02T00:00:00.000Z');
        final newPreferences = {'theme': 'dark', 'lang': 'en'};

        // Act
        final copiedUser = originalUser.copyWith(
          id: 'new123',
          credentialId: 'newCred456',
          email: 'new@example.com',
          phone: '+9876543210',
          firstName: 'Jane',
          lastName: 'Smith',
          professionalRole: 'Designer',
          profilePhotoUrl: 'https://newphoto.com/pic.jpg',
          createdAt: newCreatedAt,
          updatedAt: newUpdatedAt,
          userStatus: UserProfileStatus.active,
          userPreferences: newPreferences,
        );

        // Assert
        expect(copiedUser.id, 'new123');
        expect(copiedUser.credentialId, 'newCred456');
        expect(copiedUser.email, 'new@example.com');
        expect(copiedUser.phone, '+9876543210');
        expect(copiedUser.firstName, 'Jane');
        expect(copiedUser.lastName, 'Smith');
        expect(copiedUser.professionalRole, 'Designer');
        expect(copiedUser.profilePhotoUrl, 'https://newphoto.com/pic.jpg');
        expect(copiedUser.createdAt, newCreatedAt);
        expect(copiedUser.updatedAt, newUpdatedAt);
        expect(copiedUser.userStatus, UserProfileStatus.active);
        expect(copiedUser.userPreferences, newPreferences);
        expect(copiedUser.fullName, 'Jane Smith');
      });
    });
  });
} 