import 'package:construculator/libraries/storage/models/owner_record.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OwnerRecord', () {
    final signedOutAt = DateTime.utc(2026, 11, 10, 8, 30);

    OwnerRecord roundTrip(OwnerRecord record) =>
        OwnerRecord.fromJson(record.toJson());

    test('keeps a user with no flag and no date', () {
      final record = OwnerRecord(userId: 'user-1');

      expect(roundTrip(record), record);
      expect(roundTrip(record).pendingDelete, isNull);
      expect(roundTrip(record).signOutDate, isNull);
    });

    test('keeps the sign-out date', () {
      final record = OwnerRecord(userId: 'user-1', signOutDate: signedOutAt);

      final read = roundTrip(record);

      expect(read.signOutDate, signedOutAt);
      expect(read.signOutDate!.isUtc, isTrue);
    });

    test(
      'stores a local sign-out date in UTC, so it equals the one read back',
      () {
        final record = OwnerRecord(
          userId: 'user-1',
          signOutDate: DateTime(2026, 11, 10, 8, 30),
        );

        expect(record.signOutDate!.isUtc, isTrue);
        expect(roundTrip(record), record);
      },
    );

    test('writes a local sign-out date as a UTC time', () {
      final record = OwnerRecord(
        userId: 'user-1',
        signOutDate: DateTime(2026, 11, 10, 8, 30),
      );

      expect(record.toJson()['signOutDate'], endsWith('Z'));
    });

    test('keeps a flag that names the arriving user', () {
      final record = OwnerRecord(
        userId: 'user-1',
        pendingDelete: const PendingDelete.arrivalOf('user-2'),
      );

      final read = roundTrip(record);

      expect(read.pendingDelete!.kind, PendingDeleteKind.arrivalOfNewUser);
      expect(read.pendingDelete!.arrivingUserId, 'user-2');
    });

    test('keeps a flag that names nobody, with no user id', () {
      final record = OwnerRecord(
        pendingDelete: const PendingDelete.logoutOrNoOwnerRecord(),
      );

      final read = roundTrip(record);

      expect(read.userId, isNull);
      expect(read.pendingDelete!.kind, PendingDeleteKind.logoutOrNoOwnerRecord);
      expect(read.pendingDelete!.arrivingUserId, isNull);
    });

    test('refuses a record with no user id and no flag', () {
      expect(() => OwnerRecord(), throwsArgumentError);
      expect(() => OwnerRecord(signOutDate: signedOutAt), throwsArgumentError);
    });

    test('refuses an empty user id, in the record or in the flag', () {
      expect(() => OwnerRecord(userId: ''), throwsArgumentError);
      expect(
        () => OwnerRecord(
          userId: 'user-1',
          pendingDelete: const PendingDelete.arrivalOf(''),
        ),
        throwsArgumentError,
      );
    });

    test('treats two flags of different kinds as different records', () {
      final arrival = OwnerRecord(
        userId: 'user-1',
        pendingDelete: const PendingDelete.arrivalOf('user-2'),
      );
      final logout = OwnerRecord(
        userId: 'user-1',
        pendingDelete: const PendingDelete.logoutOrNoOwnerRecord(),
      );

      expect(arrival, isNot(logout));
    });

    group('fromJson rejects', () {
      final cases = <String, Map<String, Object?>>{
        'no user id and no flag': {},
        'a user id that is not a string': {'userId': 7},
        'an empty user id': {'userId': ''},
        'an arrival flag that names a user that is not a string': {
          'userId': 'user-1',
          'pendingDelete': {'kind': 'arrivalOfNewUser', 'userId': 7},
        },
        'an arrival flag that names an empty user': {
          'userId': 'user-1',
          'pendingDelete': {'kind': 'arrivalOfNewUser', 'userId': ''},
        },
        'a sign-out date that is not a string': {
          'userId': 'user-1',
          'signOutDate': 7,
        },
        'a sign-out date that is not a date': {
          'userId': 'user-1',
          'signOutDate': 'yesterday',
        },
        'a flag that is not an object': {
          'userId': 'user-1',
          'pendingDelete': true,
        },
        'a flag of an unknown kind': {
          'userId': 'user-1',
          'pendingDelete': {'kind': 'other'},
        },
        'an arrival flag that names nobody': {
          'userId': 'user-1',
          'pendingDelete': {'kind': 'arrivalOfNewUser'},
        },
        'a logout flag that names a user': {
          'userId': 'user-1',
          'pendingDelete': {'kind': 'logoutOrNoOwnerRecord', 'userId': 'x'},
        },
      };

      cases.forEach((name, json) {
        test(name, () {
          expect(() => OwnerRecord.fromJson(json), throwsFormatException);
        });
      });
    });
  });
}
