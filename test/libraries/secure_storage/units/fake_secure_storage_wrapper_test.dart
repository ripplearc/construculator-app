import 'package:construculator/libraries/secure_storage/testing/fake_secure_storage_wrapper.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FakeSecureStorageWrapper', () {
    late FakeSecureStorageWrapper fake;

    setUp(() => fake = FakeSecureStorageWrapper());

    test('stores, reads and deletes values', () async {
      await fake.write('k', 'v');
      expect(await fake.read('k'), 'v');
      expect(fake.storedKeys, ['k']);

      await fake.delete('k');

      expect(await fake.read('k'), isNull);
      expect(fake.storedKeys, isEmpty);
    });

    test('seed and peek bypass the throwing switches', () async {
      fake.shouldThrowOnRead = true;
      fake.shouldThrowOnWrite = true;

      fake.seed('k', 'v');

      expect(fake.peek('k'), 'v');
    });

    test('each switch makes only its own operation throw', () async {
      fake.shouldThrowOnRead = true;
      await fake.write('k', 'v');
      await fake.delete('k');
      expect(() => fake.read('k'), throwsA(isA<PlatformException>()));

      fake.reset();
      fake.shouldThrowOnWrite = true;
      expect(() => fake.write('k', 'v'), throwsA(isA<PlatformException>()));
      expect(await fake.read('k'), isNull);

      fake.reset();
      fake.shouldThrowOnDelete = true;
      expect(() => fake.delete('k'), throwsA(isA<PlatformException>()));
    });

    test('untilWritten completes when the key is written later', () async {
      var released = false;
      final waiting = fake.untilWritten('k').then((_) => released = true);

      await fake.write('other', 'v');
      expect(released, isFalse);
      await fake.write('k', 'v');
      await waiting;

      expect(released, isTrue);
    });

    test('untilWritten completes at once for a key already written', () async {
      fake.seed('k', 'v');

      await expectLater(fake.untilWritten('k'), completes);
    });

    test('untilRemoved completes when the key is deleted later', () async {
      fake.seed('k', 'v');
      final waiting = fake.untilRemoved('k');

      await fake.delete('k');

      await expectLater(waiting, completes);
    });

    test('untilRemoved completes at once for a key never written', () async {
      await expectLater(fake.untilRemoved('k'), completes);
    });

    test('reset empties the store and clears the switches', () async {
      fake.seed('k', 'v');
      fake.shouldThrowOnRead = true;
      fake.shouldThrowOnWrite = true;
      fake.shouldThrowOnDelete = true;

      fake.reset();

      expect(fake.storedKeys, isEmpty);
      await fake.write('k', 'v');
      expect(await fake.read('k'), 'v');
      await fake.delete('k');
    });
  });
}
