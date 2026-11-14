import 'package:construculator/libraries/storage/interfaces/owner_record_storage_service.dart';
import 'package:construculator/libraries/storage/models/owner_record.dart';
import 'package:construculator/libraries/storage/testing/fake_owner_record_storage_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FakeOwnerRecordStorageService', () {
    late FakeOwnerRecordStorageService fake;
    final userOne = OwnerRecord(userId: 'user-1');
    final userTwo = OwnerRecord(userId: 'user-2');

    setUp(() => fake = FakeOwnerRecordStorageService());

    test('reads as absent before anything is stored', () async {
      expect(await fake.read(), isA<OwnerRecordAbsent>());
      expect(fake.record, isNull);
    });

    test('reads back a written record and records the write', () async {
      await fake.write(userOne);

      final read = await fake.read() as OwnerRecordFound;
      expect(read.record, userOne);
      expect(fake.record, userOne);
      expect(fake.writes, [userOne]);
    });

    test('a second write replaces the first and both are recorded', () async {
      await fake.write(userOne);
      await fake.write(userTwo);

      expect(fake.record, userTwo);
      expect(fake.writes, [userOne, userTwo]);
    });

    test('seed puts a record in place without recording a write', () async {
      fake.seed(userOne);

      expect(fake.record, userOne);
      expect(fake.writes, isEmpty);
    });

    test('remove makes the next read absent', () async {
      fake.seed(userOne);

      await fake.remove();

      expect(await fake.read(), isA<OwnerRecordAbsent>());
    });

    test('reads as unknown while shouldReadUnknown is set', () async {
      fake.seed(userOne);
      fake.shouldReadUnknown = true;

      expect(await fake.read(), isA<OwnerRecordUnknown>());
    });

    test('a failing write throws and stores nothing', () async {
      fake.shouldThrowOnWrite = true;

      await expectLater(fake.write(userOne), throwsStateError);

      expect(fake.record, isNull);
      expect(fake.writes, isEmpty);
    });

    test('a failing remove throws and keeps the record', () async {
      fake.seed(userOne);
      fake.shouldThrowOnRemove = true;

      await expectLater(fake.remove(), throwsStateError);

      expect(fake.record, userOne);
    });

    test('reset clears the record, the writes and every switch', () async {
      await fake.write(userOne);
      fake.shouldReadUnknown = true;
      fake.shouldThrowOnWrite = true;
      fake.shouldThrowOnRemove = true;

      fake.reset();

      expect(fake.record, isNull);
      expect(fake.writes, isEmpty);
      expect(await fake.read(), isA<OwnerRecordAbsent>());
      await fake.write(userOne);
      await fake.remove();
    });
  });
}
