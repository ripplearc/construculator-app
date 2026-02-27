import 'package:construculator/libraries/auth/domain/entities/user_profile_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserProfile', () {
    const testUserProfile = UserProfile(
      id: 'user-123',
      credentialId: 'cred-456',
      firstName: 'John',
      lastName: 'Doe',
      professionalRole: 'Project Manager',
      profilePhotoUrl: 'https://example.com/photo.jpg',
    );

    group('constructor', () {
      test('creates instance with optional fields as null', () {
        const userProfile = UserProfile(
          id: 'user-123',
          firstName: 'Jane',
          lastName: 'Smith',
          professionalRole: 'Engineer',
        );

        expect(userProfile.credentialId, isNull);
        expect(userProfile.profilePhotoUrl, isNull);
      });
    });

    group('fullName', () {
      test('returns concatenated first and last name', () {
        expect(testUserProfile.fullName, 'John Doe');
      });
    });

    group('initials', () {
      test('returns correct initials for standard names', () {
        expect(testUserProfile.initials, 'JD');
      });

      test('returns uppercase initials', () {
        const userProfile = UserProfile(
          id: 'user-123',
          firstName: 'jane',
          lastName: 'smith',
          professionalRole: 'Engineer',
        );

        expect(userProfile.initials, 'JS');
      });

      test('handles empty first name', () {
        const userProfile = UserProfile(
          id: 'user-123',
          firstName: '',
          lastName: 'Doe',
          professionalRole: 'Engineer',
        );

        expect(userProfile.initials, 'D');
      });

      test('handles empty last name', () {
        const userProfile = UserProfile(
          id: 'user-123',
          firstName: 'John',
          lastName: '',
          professionalRole: 'Engineer',
        );

        expect(userProfile.initials, 'J');
      });

      test('handles both empty names', () {
        const userProfile = UserProfile(
          id: 'user-123',
          firstName: '',
          lastName: '',
          professionalRole: 'Engineer',
        );

        expect(userProfile.initials, '');
      });
    });

    group('copyWith', () {
      test('returns new instance with updated fields', () {
        const expected = UserProfile(
          id: 'user-123',
          credentialId: 'cred-456',
          firstName: 'Jane',
          lastName: 'Doe',
          professionalRole: 'Senior Project Manager',
          profilePhotoUrl: 'https://example.com/photo.jpg',
        );

        final updated = testUserProfile.copyWith(
          firstName: 'Jane',
          professionalRole: 'Senior Project Manager',
        );

        expect(updated, expected);
      });

      test('returns instance with same values when no parameters provided', () {
        final copied = testUserProfile.copyWith();

        expect(copied, testUserProfile);
      });

      test('can update all fields at once', () {
        const expected = UserProfile(
          id: 'new-id',
          credentialId: 'new-cred',
          firstName: 'Jane',
          lastName: 'Smith',
          professionalRole: 'Engineer',
          profilePhotoUrl: 'https://example.com/new-photo.jpg',
        );

        final updated = testUserProfile.copyWith(
          id: 'new-id',
          credentialId: 'new-cred',
          firstName: 'Jane',
          lastName: 'Smith',
          professionalRole: 'Engineer',
          profilePhotoUrl: 'https://example.com/new-photo.jpg',
        );

        expect(updated, expected);
      });
    });

    group('Equatable', () {
      test('two instances with same values are equal', () {
        const userProfile1 = UserProfile(
          id: 'user-123',
          credentialId: 'cred-456',
          firstName: 'John',
          lastName: 'Doe',
          professionalRole: 'Project Manager',
          profilePhotoUrl: 'https://example.com/photo.jpg',
        );

        const userProfile2 = UserProfile(
          id: 'user-123',
          credentialId: 'cred-456',
          firstName: 'John',
          lastName: 'Doe',
          professionalRole: 'Project Manager',
          profilePhotoUrl: 'https://example.com/photo.jpg',
        );

        expect(userProfile1, equals(userProfile2));
      });

      test('two instances with different values are not equal', () {
        const userProfile1 = UserProfile(
          id: 'user-123',
          firstName: 'John',
          lastName: 'Doe',
          professionalRole: 'Project Manager',
        );

        const userProfile2 = UserProfile(
          id: 'user-456',
          firstName: 'Jane',
          lastName: 'Smith',
          professionalRole: 'Engineer',
        );

        expect(userProfile1, isNot(equals(userProfile2)));
      });

      test('instances with different optional field values are not equal', () {
        const userProfile1 = UserProfile(
          id: 'user-123',
          credentialId: 'cred-456',
          firstName: 'John',
          lastName: 'Doe',
          professionalRole: 'Project Manager',
        );

        const userProfile2 = UserProfile(
          id: 'user-123',
          credentialId: 'cred-789',
          firstName: 'John',
          lastName: 'Doe',
          professionalRole: 'Project Manager',
        );

        expect(userProfile1, isNot(equals(userProfile2)));
      });
    });
  });
}
