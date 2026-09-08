import 'package:construculator/libraries/auth/domain/entities/user_profile_entity.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/owner/testing/fake_owner_repository.dart';
import 'package:flutter_test/flutter_test.dart';

UserProfile _owner({
  required String id,
  required String firstName,
  required String lastName,
}) {
  return UserProfile(
    id: id,
    firstName: firstName,
    lastName: lastName,
    professionalRole: 'Engineer',
  );
}

void main() {
  group('FakeOwnerRepository', () {
    late FakeOwnerRepository repository;

    setUp(() {
      repository = FakeOwnerRepository();
    });

    test('getOwners returns seeded owners', () async {
      repository.addOwners([
        _owner(id: 'owner-1', firstName: 'John', lastName: 'Doe'),
        _owner(id: 'owner-2', firstName: 'Floyd', lastName: 'Miles'),
      ]);

      final result = await repository.getOwners();

      result.fold((_) => fail('Expected Right but got Left'), (owners) {
        expect(owners.length, 2);
        expect(owners.first.fullName, 'John Doe');
      });
    });

    test('getOwners returns configured failure', () async {
      repository.shouldFailOnGetOwners = true;
      repository.getOwnersFailure = UnexpectedFailure();

      final result = await repository.getOwners();

      result.fold(
        (failure) => expect(failure, isA<UnexpectedFailure>()),
        (_) => fail('Expected Left but got Right'),
      );
    });

    test('getOwners records method calls', () async {
      await repository.getOwners();
      await repository.getOwners();

      expect(repository.getMethodCallsFor('getOwners').length, 2);
    });

    test('reset clears owners, calls, and failure flags', () async {
      repository.addOwners([
        _owner(id: 'owner-1', firstName: 'John', lastName: 'Doe'),
      ]);
      repository.shouldFailOnGetOwners = true;
      await repository.getOwners();

      repository.reset();

      final result = await repository.getOwners();
      result.fold(
        (_) => fail('Expected Right but got Left'),
        (owners) => expect(owners, isEmpty),
      );
      expect(repository.getMethodCallsFor('getOwners').length, 1);
    });
  });
}
