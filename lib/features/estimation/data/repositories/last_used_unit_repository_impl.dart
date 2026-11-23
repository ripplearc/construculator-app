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
/// save skips when the stored units cannot be read, so the other materials
/// are not overwritten, and starts over when they are damaged. A stored name
/// that is no longer a known unit is left out of the read.
class LastUsedUnitRepositoryImpl implements LastUsedUnitRepository {
  LastUsedUnitRepositoryImpl({
    required this._storage,
    required this._authRepository,
  });

  final StorageService _storage;
  final AuthRepository _authRepository;
  static final _logger = AppLogger().tag('LastUsedUnitRepositoryImpl');
  static const _perMaterialKeyPrefix = 'last_used_units';

  @override
  Future<RememberedUnits> getLastUnits(CostItemType category) async {
    final key = _keyFor(category);
    if (key == null) return RememberedUnits.none;
    try {
      return _decodeUnits(await _storage.getData<String>(key));
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
    final String? stored;
    try {
      stored = await _storage.getData<String>(key);
    } catch (e) {
      _logger.warning('Could not read the last used units, so none saved: $e');
      return;
    }
    final units = _decodeUnits(stored).withUnit(itemName, unit);
    try {
      await _storage.saveData<String>(
        key,
        jsonEncode({
          for (final entry in units.unitsByKey.entries)
            entry.key: entry.value.toJson(),
        }),
      );
      // The single unit kept per category before units were kept per
      // material is never read again.
      await _storage.removeData(_retiredPerCategoryKeyFor(key));
    } catch (e) {
      _logger.warning('Could not save the last used unit: $e');
    }
  }

  RememberedUnits _decodeUnits(String? stored) {
    if (stored == null) return RememberedUnits.none;
    try {
      final decoded = jsonDecode(stored) as Map<String, dynamic>;
      return RememberedUnits({
        for (final MapEntry(:key, :value) in decoded.entries)
          key: ?Unit.values.where((unit) => unit.name == value).firstOrNull,
      });
    } catch (e) {
      // Damaged units start over, so one bad entry does not block every
      // later save.
      _logger.warning('The last used units are damaged: $e');
      return RememberedUnits.none;
    }
  }

  String? _keyFor(CostItemType category) {
    final accountId = _authRepository.getCurrentCredentials()?.id;
    if (accountId == null) return null;
    return '$_perMaterialKeyPrefix.$accountId.${category.name}';
  }

  String _retiredPerCategoryKeyFor(String key) =>
      key.replaceFirst(_perMaterialKeyPrefix, 'last_used_unit');
}
