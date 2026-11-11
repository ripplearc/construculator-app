import 'package:construculator/libraries/storage/prefixed_preferences.dart';
import 'package:construculator/libraries/storage/shared_pref_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SharedPrefService', () {
    late SharedPrefService userSpace;

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      // ignore: no_direct_instantiation, reason: the real service over the platform preferences is under test
      userSpace = SharedPrefService(
        // ignore: no_direct_instantiation, reason: the real preferences wrapper is under test
        preferences: PrefixedPreferences(prefix: SharedPrefService.keyPrefix),
      );
    });

    test('refuses preferences that use another prefix', () {
      expect(
        () =>
            // ignore: no_direct_instantiation, reason: the constructor guard is under test
            SharedPrefService(
              // ignore: no_direct_instantiation, reason: the real preferences wrapper is under test
              preferences: PrefixedPreferences(prefix: 'device.'),
            ),
        throwsAssertionError,
      );
    });

    test('reads nothing before anything is saved', () async {
      expect(await userSpace.getData<String>('last_used_unit.a'), isNull);
    });

    test('reads back each kind of value it can store', () async {
      await userSpace.saveData<String>('text', 'kg');
      await userSpace.saveData<int>('whole', 3);
      await userSpace.saveData<double>('fraction', 1.5);
      await userSpace.saveData<bool>('flag', true);
      await userSpace.saveData<List<String>>('texts', ['a', 'b']);

      expect(await userSpace.getData<String>('text'), 'kg');
      expect(await userSpace.getData<int>('whole'), 3);
      expect(await userSpace.getData<double>('fraction'), 1.5);
      expect(await userSpace.getData<bool>('flag'), isTrue);
      expect(await userSpace.getData<List<String>>('texts'), ['a', 'b']);
    });

    test('an empty list reads back as an empty list', () async {
      await userSpace.saveData<List<String>>('texts', <String>[]);

      expect(await userSpace.getData<List<String>>('texts'), isEmpty);
    });

    test('an empty key is stored and cleared like any other', () async {
      await userSpace.saveData<String>('', 'value');

      expect(await userSpace.getData<String>(''), 'value');

      await userSpace.clearAll();

      expect(await userSpace.getData<String>(''), isNull);
    });

    test('a stored value of another type reads as nothing', () async {
      await userSpace.saveData<int>('whole', 3);

      expect(await userSpace.getData<String>('whole'), isNull);
    });

    test('refuses a value it cannot store and stores nothing', () async {
      await expectLater(
        userSpace.saveData<DateTime>('when', DateTime(2026)),
        throwsArgumentError,
      );

      expect(await userSpace.getData<DateTime>('when'), isNull);
    });

    test('removeData forgets one key and keeps the others', () async {
      await userSpace.saveData<String>('one', '1');
      await userSpace.saveData<String>('two', '2');

      await userSpace.removeData('one');

      expect(await userSpace.getData<String>('one'), isNull);
      expect(await userSpace.getData<String>('two'), '2');
    });

    test('clearAll removes the user space only', () async {
      SharedPreferences.setMockInitialValues({
        'sb-project-auth-token': 'session',
        'device.onboardingSeen': true,
        'user.one': '1',
      });
      await userSpace.saveData<String>('two', '2');

      await userSpace.clearAll();

      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getKeys(), {
        'sb-project-auth-token',
        'device.onboardingSeen',
      });
    });

    test('clearAll leaves a key that only resembles the prefix', () async {
      SharedPreferences.setMockInitialValues({'users.one': '1'});

      await userSpace.clearAll();

      expect(
        (await SharedPreferences.getInstance()).getString('users.one'),
        '1',
      );
    });

    test('initialize does nothing and keeps saved values', () async {
      await userSpace.saveData<String>('one', '1');

      await userSpace.initialize();

      expect(await userSpace.getData<String>('one'), '1');
    });
  });
}
