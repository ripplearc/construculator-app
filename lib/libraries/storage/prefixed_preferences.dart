import 'package:shared_preferences/shared_preferences.dart';

/// The preferences of one storage space.
///
/// Every key is stored under [prefix], so the space can be cleared without
/// touching a key it does not own, such as the Supabase session.
class PrefixedPreferences {
  /// The text put in front of every key of this space.
  final String prefix;

  /// A space whose keys all start with [prefix], which must not be empty and
  /// must end in a dot, so that no space can match another space's keys.
  PrefixedPreferences({required this.prefix})
    : assert(prefix.isNotEmpty && prefix.endsWith('.'));

  /// The value stored under [key], or null when nothing is stored or the
  /// stored value is not a [T].
  Future<T?> get<T>(String key) async {
    final preferences = await SharedPreferences.getInstance();
    final storedKey = '$prefix$key';
    final value = preferences.get(storedKey);
    final Object? stored = switch (value) {
      List<Object?>() when value.every((item) => item is String) =>
        preferences.getStringList(storedKey),
      _ => value,
    };
    return stored is T ? stored : null;
  }

  /// Stores [value] under [key].
  ///
  /// Throws an [ArgumentError] when [value] is not a string, int, double,
  /// bool or list of strings, and a [StateError] when the platform refuses
  /// the write.
  Future<void> save<T>(String key, T value) async {
    final preferences = await SharedPreferences.getInstance();
    final storedKey = '$prefix$key';
    final written = switch (value) {
      final String text => preferences.setString(storedKey, text),
      final int number => preferences.setInt(storedKey, number),
      final double number => preferences.setDouble(storedKey, number),
      final bool flag => preferences.setBool(storedKey, flag),
      final List<String> texts => preferences.setStringList(storedKey, texts),
      _ => throw ArgumentError.value(value, 'value', 'is not storable'),
    };
    if (!await written) throw StateError('Could not write $storedKey');
  }

  /// Removes the value stored under [key].
  ///
  /// Throws a [StateError] when the platform refuses the removal.
  Future<void> remove(String key) async {
    final preferences = await SharedPreferences.getInstance();
    await _removeStored(preferences, '$prefix$key');
  }

  /// Removes every value of this space and nothing else.
  ///
  /// Reads the stored keys again first, because a refused removal still drops
  /// the key from the in-memory copy. Throws a [StateError] when the platform
  /// refuses a removal, after which some values may be left; calling it again
  /// removes the rest.
  Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.reload();
    for (final storedKey in preferences.getKeys().toList()) {
      if (storedKey.startsWith(prefix)) {
        await _removeStored(preferences, storedKey);
      }
    }
  }

  Future<void> _removeStored(
    SharedPreferences preferences,
    String storedKey,
  ) async {
    if (!await preferences.remove(storedKey)) {
      throw StateError('Could not remove $storedKey');
    }
  }
}
