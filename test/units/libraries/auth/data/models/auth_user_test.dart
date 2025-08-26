import 'package:construculator/libraries/time/interfaces/clock.dart';
import 'package:construculator/libraries/time/testing/clock_test_module.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:construculator/libraries/auth/data/models/auth_user.dart';
import 'package:construculator/libraries/auth/data/types/auth_types.dart';

void main() {
  late Clock clock;
   setUp((){
    Modular.init(_TestAppModule());
    clock = Modular.get<Clock>();
  });
  tearDown((){
    Modular.destroy();
  });
  group('User Model', () {
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
        final beforeCreation = clock.now();

        final user = User.empty();

        final afterCreation = clock.now();

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

    group('fromJson', () {
      test('fromJson should create user from json data', () {
        final user = User(
          id: '123',
          credentialId: '456',
          email: 'test@example.com',
          phone: '1234567890',
          countryCode: '+1',
          firstName: 'John',
          lastName: 'Doe',
          professionalRole: 'Developer',
          profilePhotoUrl: 'https://example.com/photo.jpg',
          createdAt: clock.now(),
          updatedAt: clock.now(),
          userStatus: UserProfileStatus.active,
          userPreferences: {'theme': 'dark'},
        );

        final json = user.toJson();

        final userFromJson = User.fromJson(json);

        expect(userFromJson.id, user.id);
        expect(userFromJson.credentialId, user.credentialId);
        expect(userFromJson.email, user.email);
        expect(userFromJson.phone, user.phone);
        expect(userFromJson.countryCode, user.countryCode);
        expect(userFromJson.firstName, user.firstName);
        expect(userFromJson.lastName, user.lastName);
        expect(userFromJson.professionalRole, user.professionalRole);
        expect(userFromJson.profilePhotoUrl, user.profilePhotoUrl);
        expect(userFromJson.userStatus, user.userStatus);
      });
    });

    group('getters', () {
      test('fullName should combine firstName and lastName', () {
        final user = User(
          id: '123',
          credentialId: '456',
          email: 'test@example.com',
          phone: '1234567890',
          firstName: 'John',
          lastName: 'Doe',
          professionalRole: 'Developer',
          profilePhotoUrl: 'https://example.com/photo.jpg',
          createdAt: clock.now(),
          updatedAt: clock.now(),
          userStatus: UserProfileStatus.active,
          userPreferences: {'theme': 'dark'},
        );

        expect(user.fullName, equals('John Doe'));
      });

      test('fullName should handle empty names', () {
        final user = User(
          id: '123',
          credentialId: '456',
          email: 'test@example.com',
          phone: '1234567890',
          firstName: '',
          lastName: '',
          professionalRole: 'Developer',
          profilePhotoUrl: 'https://example.com/photo.jpg',
          createdAt: clock.now(),
          updatedAt: clock.now(),
          userStatus: UserProfileStatus.active,
          userPreferences: {'theme': 'dark'},
        );

        expect(user.fullName, equals(' '));
      });

      test('phoneNumber should combine countryCode and phone', () {
        final user = User(
          id: '123',
          credentialId: '456',
          email: 'test@example.com',
          phone: '1234567890',
          countryCode: '+1',
          firstName: 'John',
          lastName: 'Doe',
          professionalRole: 'Developer',
          profilePhotoUrl: 'https://example.com/photo.jpg',
          createdAt: clock.now(),
          updatedAt: clock.now(),
          userStatus: UserProfileStatus.active,
          userPreferences: {'theme': 'dark'},
        );

        expect(user.phoneNumber, equals('+11234567890'));
      });

      test('phoneNumber should handle null countryCode', () {
        final user = User(
          id: '123',
          credentialId: '456',
          email: 'test@example.com',
          phone: '1234567890',
          countryCode: null,
          firstName: 'John',
          lastName: 'Doe',
          professionalRole: 'Developer',
          profilePhotoUrl: 'https://example.com/photo.jpg',
          createdAt: clock.now(),
          updatedAt: clock.now(),
          userStatus: UserProfileStatus.active,
          userPreferences: {'theme': 'dark'},
        );

        expect(user.phoneNumber, equals('null1234567890'));
      });

      test('phoneNumber should handle null phone', () {
        final user = User(
          id: '123',
          credentialId: '456',
          email: 'test@example.com',
          phone: null,
          countryCode: '+1',
          firstName: 'John',
          lastName: 'Doe',
          professionalRole: 'Developer',
          profilePhotoUrl: 'https://example.com/photo.jpg',
          createdAt: clock.now(),
          updatedAt: clock.now(),
          userStatus: UserProfileStatus.active,
          userPreferences: {'theme': 'dark'},
        );

        expect(user.phoneNumber, equals('+1null'));
      });
    });
  });
}
class _TestAppModule extends Module {
  @override
  List<Module> get imports => [
    ClockTestModule(),
  ];
}