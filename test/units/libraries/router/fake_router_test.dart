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
      // First add some routes to the history
      await router.pushNamed('/home');
      await router.pushNamed('/profile');
      
      // Navigate to a new route
      router.navigate('/dashboard', arguments: {'page': 'main'});
      
      // History should be cleared and only contain the new route
      expect(router.navigationHistory.length, equals(1));
      expect(router.navigationHistory[0].route, '/dashboard');
      expect(router.navigationHistory[0].arguments, {'page': 'main'});
    });
  });
}
