import 'package:construculator/libraries/network_status/testing/fake_internet_reachability_sdk.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeInternetReachabilitySdk fake;

  setUp(() {
    fake = FakeInternetReachabilitySdk();
    addTearDown(fake.dispose);
  });

  group('FakeInternetReachabilitySdk', () {
    test('answers reachable and counts the check', () async {
      expect(await fake.checkReachable(), isTrue);
      expect(fake.checkCount, 1);
    });

    test('fails the check when it is told to throw', () async {
      fake.shouldThrowOnCheck = true;

      await expectLater(fake.checkReachable(), throwsStateError);
      expect(fake.checkCount, 1);
    });

    test('holds a check until it is released', () async {
      fake.holdChecks();
      var answer = 'waiting';
      final check = fake.checkReachable().then((reachable) {
        answer = reachable ? 'reachable' : 'unreachable';
      });

      expect(answer, 'waiting');
      await fake.releaseCheck(false);
      await check;

      expect(answer, 'unreachable');
    });

    test('releases the oldest check first and the newest on request', () async {
      fake.holdChecks();
      final oldest = fake.checkReachable();
      final newest = fake.checkReachable();

      await fake.releaseNewestCheck(false);
      await fake.releaseCheck(true);

      expect(await newest, isFalse);
      expect(await oldest, isTrue);
    });

    test('emits a tick to each listener', () async {
      final ticks = expectLater(fake.checkTicks, emitsInOrder([null, null]));

      fake.tick();
      fake.tick();

      await ticks;
    });

    test('reports polling only while checkTicks is listened to', () async {
      expect(fake.isPolling, isFalse);

      final subscription = fake.checkTicks.listen((_) {});
      expect(fake.isPolling, isTrue);

      await subscription.cancel();
      expect(fake.isPolling, isFalse);
    });

    test('dispose closes checkTicks', () async {
      final done = expectLater(fake.checkTicks, emitsDone);

      fake.dispose();

      await done;
    });
  });
}
