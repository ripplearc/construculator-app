import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/domain/repositories/last_used_unit_repository.dart';
import 'package:construculator/libraries/auth/interfaces/auth_repository.dart';
import 'package:construculator/libraries/logging/app_logger.dart';
import 'package:construculator/libraries/storage/interfaces/storage_service.dart';

/// Keeps the last used unit on the device, under the signed-in account's id so
/// a second account on the same phone has its own.
///
/// A failed read or write is a lost convenience, not an error the user can act
/// on, so both are swallowed and a read falls back to no remembered unit.
class LastUsedUnitRepositoryImpl implements LastUsedUnitRepository {
  LastUsedUnitRepositoryImpl({
    required this._storage,
    required this._authRepository,
  });

  final StorageService _storage;
  final AuthRepository _authRepository;
  static final _logger = AppLogger().tag('LastUsedUnitRepositoryImpl');

  @override
  Future<Unit?> getLastUnit(CostItemType category) async {
    final key = _keyFor(category);
    if (key == null) return null;
    try {
      final stored = await _storage.getData<String>(key);
      return stored == null ? null : Unit.fromJson(stored);
    } catch (e) {
      _logger.warning('Could not read the last used unit: $e');
      return null;
    }
  }

  @override
  Future<void> saveLastUnit(CostItemType category, Unit unit) async {
    final key = _keyFor(category);
    if (key == null) return;
    try {
      await _storage.saveData<String>(key, unit.toJson());
    } catch (e) {
      _logger.warning('Could not save the last used unit: $e');
    }
  }

  String? _keyFor(CostItemType category) {
    final accountId = _authRepository.getCurrentCredentials()?.id;
    if (accountId == null) return null;
    return 'last_used_unit.$accountId.${category.name}';
  }
}
