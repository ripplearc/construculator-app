import 'package:flutter_test/flutter_test.dart';
import 'package:construculator/libraries/auth/data/models/auth_user.dart';
import 'package:construculator/libraries/auth/data/types/auth_types.dart';

void main() {
  group('User Model', () {
    group('fromJson', () {
      test('should create User from valid JSON', () {
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
          'user_preferences': <String, dynamic>{
            'theme': 'dark',
            'notifications': true,
          },
        };

        final user = User.fromJson(json);

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

        final user = User.fromJson(json);

        expect(user.phone, isNull);
        expect(user.profilePhotoUrl, isNull);
        expect(user.userStatus, UserProfileStatus.inactive);
        expect(user.userPreferences, isEmpty);
      });

      test('should handle inactive user status', () {
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

        final user = User.fromJson(json);

        expect(user.userStatus, UserProfileStatus.inactive);
      });

      test('should default to inactive for unknown user status', () {
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

        final user = User.fromJson(json);

        expect(user.userStatus, UserProfileStatus.inactive);
      });

      test('should throw when required fields are missing', () {
        final json = <String, dynamic>{
          'id': 'user123',
          'email': 'test@example.com',
        };

        expect(() => User.fromJson(json), throwsA(isA<TypeError>()));
      });

      test('should throw when date format is invalid', () {
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

        expect(() => User.fromJson(json), throwsA(isA<FormatException>()));
      });

      test('should handle empty user preferences', () {
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

        final user = User.fromJson(json);

        expect(user.userPreferences, isEmpty);
      });

      test('should handle complex user preferences', () {
        final complexPreferences = <String, dynamic>{
          'theme': 'dark',
          'notifications': {'email': true, 'push': false, 'sms': true},
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

        final user = User.fromJson(json);

        expect(user.userPreferences, complexPreferences);
        expect(user.userPreferences['notifications']['email'], true);
        expect(user.userPreferences['features'], ['feature1', 'feature2']);
      });
    });

    group('toJson', () {
      test('should convert User to JSON correctly', () {
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

        final json = user.toJson();

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

        final json = user.toJson();

        expect(json['phone'], isNull);
        expect(json['profile_photo_url'], isNull);
        expect(json['user_status'], 'inactive');
        expect(json['user_preferences'], isEmpty);
      });

      test('should convert UserProfileStatus enum correctly', () {
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

        final activeJson = activeUser.toJson();
        final inactiveJson = inactiveUser.toJson();

        expect(activeJson['user_status'], 'active');
        expect(inactiveJson['user_status'], 'inactive');
      });

      test('should handle complex user preferences in toJson', () {
        final complexPreferences = <String, dynamic>{
          'theme': 'dark',
          'notifications': {'email': true, 'push': false},
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

        final json = user.toJson();

        expect(json['user_preferences'], complexPreferences);
      });
    });

    group('empty factory', () {
      test('should create empty User with default values', () {
        final user = User.empty();

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
        final beforeCreation = DateTime.now();

        final user = User.empty();

        final afterCreation = DateTime.now();

        expect(
          user.createdAt.isAfter(beforeCreation.subtract(Duration(seconds: 1))),
          true,
        );
        expect(
          user.createdAt.isBefore(afterCreation.add(Duration(seconds: 1))),
          true,
        );
        expect(
          user.updatedAt.isAfter(beforeCreation.subtract(Duration(seconds: 1))),
          true,
        );
        expect(
          user.updatedAt.isBefore(afterCreation.add(Duration(seconds: 1))),
          true,
        );
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
        final copiedUser = originalUser.copyWith();

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
        final copiedUser = originalUser.copyWith(id: 'newId123');

        expect(copiedUser.id, 'newId123');
        expect(copiedUser.credentialId, originalUser.credentialId);
        expect(copiedUser.email, originalUser.email);
      });

      test('should update only credentialId when provided', () {
        final copiedUser = originalUser.copyWith(credentialId: 'newCred789');

        expect(copiedUser.id, originalUser.id);
        expect(copiedUser.credentialId, 'newCred789');
        expect(copiedUser.email, originalUser.email);
      });

      test('should update only email when provided', () {
        final copiedUser = originalUser.copyWith(email: 'newemail@example.com');

        expect(copiedUser.email, 'newemail@example.com');
        expect(copiedUser.id, originalUser.id);
        expect(copiedUser.credentialId, originalUser.credentialId);
      });

      test('should update only phone when provided', () {
        final copiedUser = originalUser.copyWith(phone: '+9876543210');

        expect(copiedUser.phone, '+9876543210');
        expect(copiedUser.id, originalUser.id);
        expect(copiedUser.email, originalUser.email);
      });

      test('should update only firstName when provided', () {
        final copiedUser = originalUser.copyWith(firstName: 'Jane');

        expect(copiedUser.firstName, 'Jane');
        expect(copiedUser.lastName, originalUser.lastName);
        expect(copiedUser.fullName, 'Jane Doe');
      });

      test('should update only lastName when provided', () {
        final copiedUser = originalUser.copyWith(lastName: 'Smith');

        expect(copiedUser.lastName, 'Smith');
        expect(copiedUser.firstName, originalUser.firstName);
        expect(copiedUser.fullName, 'John Smith');
      });

      test('should update only professionalRole when provided', () {
        final copiedUser = originalUser.copyWith(professionalRole: 'Designer');

        expect(copiedUser.professionalRole, 'Designer');
        expect(copiedUser.firstName, originalUser.firstName);
        expect(copiedUser.lastName, originalUser.lastName);
      });

      test('should update only profilePhotoUrl when provided', () {
        final copiedUser = originalUser.copyWith(
          profilePhotoUrl: 'https://newurl.com/photo.jpg',
        );

        expect(copiedUser.profilePhotoUrl, 'https://newurl.com/photo.jpg');
        expect(copiedUser.id, originalUser.id);
        expect(copiedUser.email, originalUser.email);
      });

      test('should update only createdAt when provided', () {
        final newCreatedAt = DateTime.parse('2024-01-01T00:00:00.000Z');

        final copiedUser = originalUser.copyWith(createdAt: newCreatedAt);

        expect(copiedUser.createdAt, newCreatedAt);
        expect(copiedUser.updatedAt, originalUser.updatedAt);
        expect(copiedUser.id, originalUser.id);
      });

      test('should update only updatedAt when provided', () {
        final newUpdatedAt = DateTime.parse('2024-01-02T00:00:00.000Z');

        final copiedUser = originalUser.copyWith(updatedAt: newUpdatedAt);

        expect(copiedUser.updatedAt, newUpdatedAt);
        expect(copiedUser.createdAt, originalUser.createdAt);
        expect(copiedUser.id, originalUser.id);
      });

      test('should update only userStatus when provided', () {
        final copiedUser = originalUser.copyWith(
          userStatus: UserProfileStatus.inactive,
        );

        expect(copiedUser.userStatus, UserProfileStatus.inactive);
        expect(copiedUser.id, originalUser.id);
        expect(copiedUser.email, originalUser.email);
      });

      test('should update only userPreferences when provided', () {
        final newPreferences = {'theme': 'light', 'language': 'es'};

        final copiedUser = originalUser.copyWith(
          userPreferences: newPreferences,
        );

        expect(copiedUser.userPreferences, newPreferences);
        expect(copiedUser.id, originalUser.id);
        expect(copiedUser.email, originalUser.email);
      });

      test('should update multiple fields when provided', () {
        final newPreferences = {'theme': 'light'};
        final newUpdatedAt = DateTime.parse('2024-01-02T00:00:00.000Z');

        final copiedUser = originalUser.copyWith(
          firstName: 'Jane',
          lastName: 'Smith',
          email: 'jane.smith@example.com',
          userStatus: UserProfileStatus.inactive,
          userPreferences: newPreferences,
          updatedAt: newUpdatedAt,
        );

        expect(copiedUser.firstName, 'Jane');
        expect(copiedUser.lastName, 'Smith');
        expect(copiedUser.email, 'jane.smith@example.com');
        expect(copiedUser.userStatus, UserProfileStatus.inactive);
        expect(copiedUser.userPreferences, newPreferences);
        expect(copiedUser.updatedAt, newUpdatedAt);
        expect(copiedUser.fullName, 'Jane Smith');

        expect(copiedUser.id, originalUser.id);
        expect(copiedUser.credentialId, originalUser.credentialId);
        expect(copiedUser.phone, originalUser.phone);
        expect(copiedUser.professionalRole, originalUser.professionalRole);
        expect(copiedUser.profilePhotoUrl, originalUser.profilePhotoUrl);
        expect(copiedUser.createdAt, originalUser.createdAt);
      });

      test('should handle null values in copyWith', () {
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

        final copiedUser = userWithValues.copyWith(
          phone: null,
          profilePhotoUrl: null,
        );

        expect(copiedUser.phone, '+1234567890');
        expect(copiedUser.profilePhotoUrl, 'https://example.com/photo.jpg');
        expect(copiedUser.id, userWithValues.id);
        expect(copiedUser.email, userWithValues.email);
      });

      test('should create new instance, not modify original', () {
        final copiedUser = originalUser.copyWith(firstName: 'Jane');

        expect(originalUser.firstName, 'John');
        expect(copiedUser.firstName, 'Jane');
        expect(identical(originalUser, copiedUser), false);
      });
    });
  });
}
