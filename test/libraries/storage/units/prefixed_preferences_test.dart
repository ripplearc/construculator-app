import 'package:construculator/libraries/storage/prefixed_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

class _RefusingStore extends SharedPreferencesStorePlatform {
  final Map<String, Object> data;
  bool refusesWrites = false;
  bool refusesRemovals = false;

  _RefusingStore(this.data);

  @override
  Future<Map<String, Object>> getAll() async => Map.of(data);

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    if (refusesWrites) return false;
    data[key] = value;
    return true;
  }

  @override
  Future<bool> remove(String key) async {
    if (refusesRemovals) return false;
    data.remove(key);
    return true;
  }

  @override
  Future<bool> clear() async {
    data.clear();
    return true;
  }
}

PrefixedPreferences buildSpace() =>
    // ignore: no_direct_instantiation, reason: the real preferences wrapper is under test
    PrefixedPreferences(prefix: 'user.');

void main() {
  group('PrefixedPreferences', () {
    late _RefusingStore store;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      // ignore: no_direct_instantiation, reason: the platform store is the boundary that is faked
      store = _RefusingStore({});
      SharedPreferencesStorePlatform.instance = store;
    });

    test('refuses a prefix that is empty or does not end in a dot', () {
      expect(
        // ignore: no_direct_instantiation, reason: the constructor guard is under test
        () => PrefixedPreferences(prefix: ''),
        throwsAssertionError,
      );
      expect(
        // ignore: no_direct_instantiation, reason: the constructor guard is under test
        () => PrefixedPreferences(prefix: 'user'),
        throwsAssertionError,
      );
    });

    test(
      'reads a stored list of strings that the platform returns untyped',
      () async {
        store.data['flutter.user.texts'] = <Object?>['a', 'b'];

        expect(await buildSpace().get<List<String>>('texts'), ['a', 'b']);
      },
    );

    test('reads a stored list with a non-string item as nothing', () async {
      store.data['flutter.user.texts'] = <Object?>['a', 1];

      expect(await buildSpace().get<List<String>>('texts'), isNull);
    });

    test(
      'save throws and leaves the stored value when the platform refuses the write',
      () async {
        final space = buildSpace();
        await space.save<String>('unit', 'kg');
        store.refusesWrites = true;

        await expectLater(space.save<String>('unit', 'm'), throwsStateError);

        expect(store.data['flutter.user.unit'], 'kg');
      },
    );

    test('remove throws when the platform refuses the removal', () async {
      final space = buildSpace();
      await space.save<String>('unit', 'kg');
      store.refusesRemovals = true;

      await expectLater(space.remove('unit'), throwsStateError);
    });

    test(
      'clear removes the rest when it is called again after a refusal',
      () async {
        final space = buildSpace();
        await space.save<String>('one', '1');
        await space.save<String>('two', '2');
        store.refusesRemovals = true;
        await expectLater(space.clear(), throwsStateError);

        store.refusesRemovals = false;
        await space.clear();

        expect(
          store.data.keys.where((key) => key.startsWith('flutter.user.')),
          isEmpty,
        );
      },
    );

    test('reads an empty list that the platform returns untyped', () async {
      store.data['flutter.user.texts'] = <Object?>[];

      expect(await buildSpace().get<List<String>>('texts'), isEmpty);
    });

    test(
      'clear throws when the platform refuses a removal, so the delete is retried',
      () async {
        final space = buildSpace();
        await space.save<String>('unit', 'kg');
        store.refusesRemovals = true;

        await expectLater(space.clear(), throwsStateError);
      },
    );
  });
}
