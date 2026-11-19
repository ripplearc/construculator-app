import 'dart:convert';

import 'package:construculator/features/estimation/domain/entities/unfinished_cost_line.dart';
import 'package:construculator/features/estimation/domain/repositories/unfinished_cost_line_repository.dart';
import 'package:construculator/libraries/auth/interfaces/auth_repository.dart';
import 'package:construculator/libraries/logging/app_logger.dart';
import 'package:construculator/libraries/storage/interfaces/storage_service.dart';
import 'package:construculator/libraries/time/interfaces/clock.dart';

/// Keeps the unfinished cost line on the device as one JSON value, under the
/// signed-in account's id so a second account on the same phone has its own.
///
/// A failed read or write loses a convenience, not something the user can act
/// on, so both are swallowed, and a value that cannot be read counts as no
/// line. Writes run one after another, in the order they were asked for, so
/// an older line can never land after a newer one.
class UnfinishedCostLineRepositoryImpl implements UnfinishedCostLineRepository {
  UnfinishedCostLineRepositoryImpl({
    required this._storage,
    required this._authRepository,
    required this._clock,
  });

  static const _keepFor = Duration(days: 7);

  final StorageService _storage;
  final AuthRepository _authRepository;
  final Clock _clock;
  static final _logger = AppLogger().tag('UnfinishedCostLineRepositoryImpl');

  Future<void> _lastWrite = Future.value();

  @override
  Future<UnfinishedCostLine?> read() async {
    await _lastWrite;
    final key = _key();
    if (key == null) return null;
    final line = await _readLine(key);
    if (line == null) return null;
    if (_clock.now().difference(line.updatedAt) < _keepFor) return line;
    await remove();
    return null;
  }

  @override
  Future<void> save(UnfinishedCostLine line) => _queue(
    (key) => _storage.saveData<String>(key, jsonEncode(line.toJson())),
  );

  @override
  Future<void> remove() => _queue(_storage.removeData);

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

  Future<void> _queue(Future<void> Function(String key) write) {
    final key = _key();
    if (key == null) return _lastWrite;
    return _lastWrite = _lastWrite.then((_) async {
      try {
        await write(key);
      } catch (e) {
        _logger.warning('Could not change the unfinished cost line: $e');
      }
    });
  }

  String? _key() {
    final accountId = _authRepository.getCurrentCredentials()?.id;
    if (accountId == null) return null;
    return 'unfinished_cost_line.$accountId';
  }
}
