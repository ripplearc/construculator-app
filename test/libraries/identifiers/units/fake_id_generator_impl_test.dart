import 'package:construculator/libraries/identifiers/testing/fake_id_generator_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FakeIdGeneratorImpl', () {
    test('returns the same ids in the same order on every instance', () {
      final first = FakeIdGeneratorImpl();
      final second = FakeIdGeneratorImpl();

      expect([first.newId(), first.newId()], [second.newId(), second.newId()]);
    });

    test('numbers the ids from 1 and pads them to a UUID', () {
      final generator = FakeIdGeneratorImpl();

      expect(generator.newId(), '00000000-0000-4000-8000-000000000001');
      expect(generator.newId(), '00000000-0000-4000-8000-000000000002');
    });

    test('idAt names the id returned by the nth call', () {
      final generator = FakeIdGeneratorImpl()..newId();

      expect(generator.newId(), FakeIdGeneratorImpl.idAt(2));
    });
  });
}
