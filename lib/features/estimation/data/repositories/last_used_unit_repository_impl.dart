import 'dart:convert';

import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/domain/repositories/last_used_unit_repository.dart';
import 'package:construculator/libraries/auth/interfaces/auth_repository.dart';
import 'package:construculator/libraries/logging/app_logger.dart';
import 'package:construculator/libraries/storage/interfaces/storage_service.dart';

/// Keeps the last used units on the device as one JSON map per category, under
/// the signed-in account's id so a second account on the same phone has its
/// own.
///
/// A failed read or write is a lost convenience, not an error the user can act
/// on, so both are swallowed and a read falls back to no remembered units. A
/// stored name that is no longer a known unit is left out of the read.
class LastUsedUnitRepositoryImpl implements LastUsedUnitRepository {
  LastUsedUnitRepositoryImpl({
    required this._storage,
    required this._authRepository,
  });

  final StorageService _storage;
  final AuthRepository _authRepository;
  static final _logger = AppLogger().tag('LastUsedUnitRepositoryImpl');

  @override
  Future<RememberedUnits> getLastUnits(CostItemType category) async {
    final key = _keyFor(category);
    if (key == null) return RememberedUnits.none;
    try {
      return await _readUnits(key);
    } catch (e) {
      _logger.warning('Could not read the last used units: $e');
      return RememberedUnits.none;
    }
  }

  @override
  Future<void> saveLastUnit(
    CostItemType category,
    String itemName,
    Unit unit,
  ) async {
    final key = _keyFor(category);
    if (key == null) return;
    // Starting from what can be read keeps a damaged entry from blocking
    // every later save.
    final units = (await getLastUnits(category)).withUnit(itemName, unit);
    try {
      await _storage.saveData<String>(
        key,
        jsonEncode({
          for (final entry in units.unitsByKey.entries)
            entry.key: entry.value.toJson(),
        }),
      );
    } catch (e) {
      _logger.warning('Could not save the last used unit: $e');
    }
  }

  Future<RememberedUnits> _readUnits(String key) async {
    final stored = await _storage.getData<String>(key);
    if (stored == null) return RememberedUnits.none;
    final decoded = jsonDecode(stored) as Map<String, dynamic>;
    return RememberedUnits({
      for (final MapEntry(:key, :value) in decoded.entries)
        key: ?Unit.values.where((unit) => unit.name == value).firstOrNull,
    });
  }

  String? _keyFor(CostItemType category) {
    final accountId = _authRepository.getCurrentCredentials()?.id;
    if (accountId == null) return null;
    return 'last_used_units.$accountId.${category.name}';
  }
}
