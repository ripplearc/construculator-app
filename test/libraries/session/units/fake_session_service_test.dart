import 'package:construculator/libraries/session/testing/fake_session_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeSessionService fake;

  setUp(() => fake = FakeSessionService());

  group('FakeSessionService', () {
    test('starts with no session', () {
      expect(fake.isActive, isFalse);
      expect(fake.startCount, 0);
      expect(fake.endCount, 0);
    });

    test('counts a start that changes the session', () {
      fake.startSession();
      fake.startSession();

      expect(fake.isActive, isTrue);
      expect(fake.startCount, 1);
    });

    test('counts an end that changes the session', () {
      fake.startSession();
      fake.endSession();
      fake.endSession();

      expect(fake.isActive, isFalse);
      expect(fake.endCount, 1);
    });
  });
}
