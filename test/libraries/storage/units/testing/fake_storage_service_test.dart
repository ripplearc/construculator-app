import 'package:construculator/libraries/storage/testing/fake_storage_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FakeStorageService', () {
    late FakeStorageService fake;

    setUp(() => fake = FakeStorageService());

    test('reads back a saved value and exposes it through valueOf', () async {
      await fake.saveData<String>('unit', 'kg');

      expect(await fake.getData<String>('unit'), 'kg');
      expect(fake.valueOf('unit'), 'kg');
    });

    test('a value of another type reads as nothing', () async {
      await fake.saveData<int>('count', 1);

      expect(await fake.getData<String>('count'), isNull);
    });

    test('removeData forgets one key and keeps the others', () async {
      await fake.saveData<String>('one', '1');
      await fake.saveData<String>('two', '2');

      await fake.removeData('one');

      expect(fake.valueOf('one'), isNull);
      expect(fake.valueOf('two'), '2');
    });

    test('clearAll forgets every key', () async {
      await fake.saveData<String>('one', '1');

      await fake.clearAll();

      expect(fake.valueOf('one'), isNull);
    });

    test('a read fails while shouldThrowOnRead is set', () async {
      fake.shouldThrowOnRead = true;

      await expectLater(fake.getData<String>('one'), throwsStateError);
    });

    test(
      'a write fails and stores nothing while shouldThrowOnWrite is set',
      () async {
        fake.shouldThrowOnWrite = true;

        await expectLater(fake.saveData<String>('one', '1'), throwsStateError);
        expect(fake.valueOf('one'), isNull);
      },
    );

    test(
      'clearAll fails and keeps the data while shouldThrowOnClear is set',
      () async {
        await fake.saveData<String>('one', '1');
        fake.shouldThrowOnClear = true;

        await expectLater(fake.clearAll(), throwsStateError);
        expect(fake.valueOf('one'), '1');
      },
    );

    test('reset clears the data and every failure switch', () async {
      await fake.saveData<String>('one', '1');
      fake.shouldThrowOnRead = true;
      fake.shouldThrowOnWrite = true;
      fake.shouldThrowOnClear = true;

      fake.reset();

      expect(await fake.getData<String>('one'), isNull);
      await fake.saveData<String>('two', '2');
      await fake.clearAll();
      expect(fake.valueOf('two'), isNull);
    });
  });
}
