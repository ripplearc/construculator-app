import 'dart:convert';

import 'package:construculator/features/estimation/domain/entities/unfinished_cost_line.dart';
import 'package:construculator/features/estimation/domain/repositories/unfinished_cost_line_repository.dart';
import 'package:construculator/libraries/auth/interfaces/auth_repository.dart';
import 'package:construculator/libraries/logging/app_logger.dart';
import 'package:construculator/libraries/storage/interfaces/storage_service.dart';

/// Keeps the unfinished cost line on the device as one JSON value, under the
/// signed-in account's id so a second account on the same phone has its own.
///
/// A failed read or write loses a convenience, not something the user can act
/// on, so both are swallowed, and a value that cannot be read counts as no
/// line.
class UnfinishedCostLineRepositoryImpl implements UnfinishedCostLineRepository {
  UnfinishedCostLineRepositoryImpl({
    required this._storage,
    required this._authRepository,
  });

  final StorageService _storage;
  final AuthRepository _authRepository;
  static final _logger = AppLogger().tag('UnfinishedCostLineRepositoryImpl');

  @override
  Future<UnfinishedCostLine?> read() async {
    final key = _key();
    if (key == null) return null;
    return _readLine(key);
  }

  @override
  Future<void> save(UnfinishedCostLine line) => _change(
    (key) => _storage.saveData<String>(key, jsonEncode(line.toJson())),
  );

  @override
  Future<void> remove() => _change(_storage.removeData);

  Future<UnfinishedCostLine?> _readLine(String key) async {
    try {
      final stored = await _storage.getData<String>(key);
      if (stored == null) return null;
      final json = jsonDecode(stored);
      return json is Map<String, dynamic>
          ? UnfinishedCostLine.fromJson(json)
          : null;
    } catch (e) {
      _logger.warning('Could not read the unfinished cost line: $e');
      return null;
    }
  }

  Future<void> _change(Future<void> Function(String key) write) async {
    final key = _key();
    if (key == null) return;
    try {
      await write(key);
    } catch (e) {
      _logger.warning('Could not change the unfinished cost line: $e');
    }
  }

  String? _key() {
    final accountId = _authRepository.getCurrentCredentials()?.id;
    if (accountId == null) return null;
    return 'unfinished_cost_line.$accountId';
  }
}
