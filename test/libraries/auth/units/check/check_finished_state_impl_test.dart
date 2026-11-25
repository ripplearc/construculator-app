import 'package:construculator/libraries/auth/check/check_finished_state_impl.dart';
import 'package:construculator/libraries/auth/check/check_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late CheckFinishedStateImpl state;

  setUp(() {
    // ignore: no_direct_instantiation, reason: unit test of the class itself
    state = CheckFinishedStateImpl();
  });
  tearDown(() => state.dispose());

  void finishFor(String userId) =>
      state.settle(result: FinishedFor(userId), isNewestEvent: true);

  group('CheckFinishedStateImpl', () {
    group('start', () {
      test('starts as checking with no active user', () {
        expect(state.value, const Checking());
        expect(state.activeUserId, isNull);
      });
    });

    group('settle', () {
      test('a finished value for a user makes that user active', () {
        finishFor('user-a');

        expect(state.value, const FinishedFor('user-a'));
        expect(state.activeUserId, 'user-a');
      });

      test('finished with nobody signed in has no active user', () {
        state.settle(
          result: const FinishedNobodySignedIn(),
          isNewestEvent: true,
        );

        expect(state.value, const FinishedNobodySignedIn());
        expect(state.activeUserId, isNull);
      });

      test('a failure sets blocked for that user', () {
        state.settle(result: const Blocked('user-a'), isNewestEvent: true);

        expect(state.value, const Blocked('user-a'));
        expect(state.activeUserId, isNull);
      });

      test('an item whose event is not the newest leaves the state alone', () {
        state.settle(result: const FinishedFor('user-a'), isNewestEvent: false);

        expect(state.value, const Checking());
      });

      test('checking and restart required are not settled values', () {
        expect(
          () => state.settle(result: const Checking(), isNewestEvent: true),
          throwsArgumentError,
        );
        expect(
          () => state.settle(
            result: const RestartRequired(),
            isNewestEvent: true,
          ),
          throwsArgumentError,
        );
      });
    });

    group('sessionEventArrived', () {
      test('an event for a different user goes back to checking at once', () {
        finishFor('user-a');

        state.sessionEventArrived(userId: 'user-b', sessionModuleAdded: true);

        expect(state.value, const Checking());
      });

      test('a token renewal for the active user changes nothing', () {
        finishFor('user-a');

        state.sessionEventArrived(userId: 'user-a', sessionModuleAdded: true);

        expect(state.value, const FinishedFor('user-a'));
      });

      test('an event for the active user with no session module added goes '
          'back to checking', () {
        finishFor('user-a');

        state.sessionEventArrived(userId: 'user-a', sessionModuleAdded: false);

        expect(state.value, const Checking());
      });

      test('a sign-in after nobody was signed in goes back to checking', () {
        state.settle(
          result: const FinishedNobodySignedIn(),
          isNewestEvent: true,
        );

        state.sessionEventArrived(userId: 'user-a', sessionModuleAdded: false);

        expect(state.value, const Checking());
      });

      test('a sign-out event for the active user goes back to checking', () {
        finishFor('user-a');

        state.sessionEventArrived(userId: null, sessionModuleAdded: false);

        expect(state.value, const Checking());
      });

      test('a second sign-out event with nobody signed in changes nothing', () {
        state.settle(
          result: const FinishedNobodySignedIn(),
          isNewestEvent: true,
        );

        state.sessionEventArrived(userId: null, sessionModuleAdded: false);

        expect(state.value, const FinishedNobodySignedIn());
      });

      test('blocked ignores an event for the same user', () {
        state.settle(result: const Blocked('user-a'), isNewestEvent: true);

        state.sessionEventArrived(userId: 'user-a', sessionModuleAdded: true);

        expect(state.value, const Blocked('user-a'));
      });

      test('blocked holds an event for a different user', () {
        state.settle(result: const Blocked('user-a'), isNewestEvent: true);

        state.sessionEventArrived(userId: 'user-b', sessionModuleAdded: true);

        expect(state.value, const Blocked('user-a'));
      });

      test('checking stays checking', () {
        state.sessionEventArrived(userId: 'user-a', sessionModuleAdded: true);

        expect(state.value, const Checking());
      });
    });

    group('requireRestart', () {
      test('restart required is final', () {
        state.requireRestart();

        finishFor('user-a');
        state.sessionEventArrived(userId: 'user-b', sessionModuleAdded: true);

        expect(state.value, const RestartRequired());
      });
    });

    group('changes', () {
      test(
        'emits the current value to a new listener and then each change',
        () async {
          final emitted = expectLater(
            state.changes,
            emitsInOrder([
              const Checking(),
              const FinishedFor('user-a'),
              const Checking(),
            ]),
          );

          finishFor('user-a');
          state.sessionEventArrived(userId: 'user-b', sessionModuleAdded: true);

          await emitted;
        },
      );

      test('does not emit the same value twice in a row', () async {
        final emitted = expectLater(
          state.changes,
          emitsInOrder([const Checking(), const FinishedFor('user-a')]),
        );

        finishFor('user-a');
        finishFor('user-a');

        await emitted;
        expect(state.value, const FinishedFor('user-a'));
      });

      test('emits nothing more after a repeated value', () async {
        final emitted = expectLater(
          state.changes,
          emitsInOrder([
            const Checking(),
            const FinishedFor('user-a'),
            emitsDone,
          ]),
        );

        finishFor('user-a');
        finishFor('user-a');
        state.dispose();

        await emitted;
      });
    });

    group('whenFinishedFor', () {
      test('completes true once the check finished for that user', () async {
        final result = state.whenFinishedFor('user-a');

        finishFor('user-a');

        expect(await result, isTrue);
      });

      test('ignores a finished value left over from another user', () async {
        finishFor('user-b');
        var completed = false;
        final result = state.whenFinishedFor('user-a').whenComplete(() {
          completed = true;
        });
        expect(completed, isFalse);

        state.sessionEventArrived(userId: 'user-a', sessionModuleAdded: false);
        finishFor('user-a');

        expect(await result, isTrue);
      });

      test('completes false when only another user finished before it '
          'closes', () async {
        finishFor('user-b');
        final result = state.whenFinishedFor('user-a');

        state.dispose();

        expect(await result, isFalse);
      });

      test('completes false when the state closes first', () async {
        final result = state.whenFinishedFor('user-a');

        state.dispose();

        expect(await result, isFalse);
      });
    });

    group('whenFinished', () {
      test(
        'completes with the user once the check finishes for a user',
        () async {
          final result = state.whenFinished();

          finishFor('user-a');

          expect(await result, 'user-a');
        },
      );

      test('completes with null when the state closes first', () async {
        final result = state.whenFinished();

        state.dispose();

        expect(await result, isNull);
      });

      test('completes with null once the check finishes with nobody', () async {
        final result = state.whenFinished();

        state.settle(
          result: const FinishedNobodySignedIn(),
          isNewestEvent: true,
        );

        expect(await result, isNull);
      });

      test(
        'stays pending while blocked and completes after a finish',
        () async {
          state.settle(result: const Blocked('user-a'), isNewestEvent: true);
          var completed = false;
          final result = state.whenFinished().whenComplete(
            () => completed = true,
          );

          expect(completed, isFalse);

          finishFor('user-a');
          await result;

          expect(completed, isTrue);
        },
      );
    });
  });
}
