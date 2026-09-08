import 'dart:async';

import 'package:construculator/libraries/router/testing/fake_router.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FakeAppRouter', () {
    late FakeAppRouter router;

    setUp(() {
      router = FakeAppRouter();
    });

    test('initial state is empty', () {
      expect(router.navigationHistory, isEmpty);
      expect(router.popCalls, equals(0));
    });

    test('pushNamed stores route and arguments', () async {
      await router.pushNamed('/login');
      await router.pushNamed('/profile', arguments: {'userId': 1});

      expect(router.navigationHistory.length, 2);
      expect(router.navigationHistory[0].route, '/login');
      expect(router.navigationHistory[0].arguments, isNull);
      expect(router.navigationHistory[1].route, '/profile');
      expect(router.navigationHistory[1].arguments, {'userId': 1});
    });

    test('pop increments popCalls', () {
      router.pop();
      router.pop();

      expect(router.popCalls, equals(2));
    });

    test('reset clears history and popCalls', () async {
      await router.pushNamed('/home');
      router.pop();

      router.reset();

      expect(router.navigationHistory, isEmpty);
      expect(router.popCalls, equals(0));
    });

    test('navigate clears history and adds new route', () async {
      await router.pushNamed('/home');
      await router.pushNamed('/profile');

      router.navigate('/dashboard', arguments: {'page': 'main'});

      expect(router.navigationHistory.length, equals(1));
      expect(router.navigationHistory[0].route, '/dashboard');
      expect(router.navigationHistory[0].arguments, {'page': 'main'});
    });

    test(
      'pushNamed throws after recording when shouldThrowOnPushNamed is set',
      () async {
        router.shouldThrowOnPushNamed = true;

        await expectLater(router.pushNamed('/home'), throwsA(isA<Exception>()));
        expect(router.navigationHistory.length, equals(1));
        expect(router.navigationHistory[0].route, '/home');
      },
    );

    test('pushNamed waits for pushNamedCompleter before completing', () async {
      final completer = Completer<void>();
      router.pushNamedCompleter = completer;

      var completed = false;
      final future = router.pushNamed('/home').then((_) => completed = true);

      // The call is recorded immediately, but the future stays pending until
      // the completer resolves.
      await null;
      expect(router.navigationHistory.length, equals(1));
      expect(completed, isFalse);

      completer.complete();
      await future;
      expect(completed, isTrue);
    });

    test('reset clears pushNamed error and completer knobs', () async {
      router.shouldThrowOnPushNamed = true;
      router.pushNamedCompleter = Completer<void>();

      router.reset();

      expect(router.shouldThrowOnPushNamed, isFalse);
      expect(router.pushNamedCompleter, isNull);
      await router.pushNamed('/home');
      expect(router.navigationHistory.length, equals(1));
    });
  });

  group('RouteCall', () {
    test('two calls with same route and arguments are equal', () {
      const a = RouteCall('/home', null);
      const b = RouteCall('/home', null);
      expect(a, equals(b));
    });

    test('two calls with different routes are not equal', () {
      const a = RouteCall('/home', null);
      const b = RouteCall('/profile', null);
      expect(a, isNot(equals(b)));
    });
  });
}
