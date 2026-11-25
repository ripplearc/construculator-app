import 'package:construculator/libraries/auth/check/check_state.dart';
import 'package:construculator/libraries/auth/check/testing/fake_check_finished_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeCheckFinishedState fake;

  setUp(() => fake = FakeCheckFinishedState());
  tearDown(() => fake.dispose());

  group('FakeCheckFinishedState', () {
    test('starts as checking unless told otherwise', () {
      expect(fake.value, const Checking());
      expect(
        FakeCheckFinishedState(initial: const FinishedFor('user-a')).value,
        const FinishedFor('user-a'),
      );
    });

    test('emit sets the value and the active user', () {
      fake.emit(const FinishedFor('user-a'));

      expect(fake.value, const FinishedFor('user-a'));
      expect(fake.activeUserId, 'user-a');
    });

    test('records the user ids of the events it was told about', () {
      fake.sessionEventArrived(userId: 'user-a', sessionModuleAdded: true);
      fake.sessionEventArrived(userId: null, sessionModuleAdded: false);

      expect(fake.arrivedEventUserIds, ['user-a', null]);
    });

    test('settle sets the result only for the newest event', () {
      fake.settle(result: const Blocked('user-a'), isNewestEvent: false);
      expect(fake.value, const Checking());

      fake.settle(result: const Blocked('user-a'), isNewestEvent: true);
      expect(fake.value, const Blocked('user-a'));
    });

    test('whenFinished completes once a finished value is set', () async {
      final result = fake.whenFinished();

      fake.emit(const FinishedFor('user-a'));

      expect(await result, 'user-a');
    });

    test('requireRestart sets restart required', () {
      fake.requireRestart();

      expect(fake.value, const RestartRequired());
    });
  });
}
