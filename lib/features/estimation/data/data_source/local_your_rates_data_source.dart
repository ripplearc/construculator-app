import 'package:construculator/features/estimation/data/data_source/interfaces/your_rates_data_source.dart';
import 'package:construculator/features/estimation/data/models/your_rate_entry_dto.dart';
import 'package:construculator/libraries/logging/app_logger.dart';
import 'package:construculator/libraries/powersync/interfaces/powersync_database_wrapper.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:construculator/libraries/time/interfaces/clock.dart';
import 'package:powersync/powersync.dart' show uuid;

/// Reads and writes "Your rates" in the phone's own PowerSync database.
///
/// Reads need no signal. A write lands in local SQLite at once and PowerSync
/// uploads it when a signal returns. The `user_rates` stream is on-demand, so
/// the first read or write of a session activates it; the rows it has already
/// delivered stay readable whether or not the phone is connected.
///
/// Rows are ordered and capped in Dart, not in SQL: a `saved_at` delivered by
/// sync and one written here need not share a text format, so ordering them
/// lexicographically would sort by which side wrote the row.
///
/// Failures are logged here, at the storage boundary, and rethrown for the
/// repository to translate.
class LocalYourRatesDataSource implements YourRatesDataSource {
  final PowerSyncDatabaseWrapper _database;
  final Clock _clock;
  static final _logger = AppLogger().tag('LocalYourRatesDataSource');

  static const _streamName = 'user_rates';

  static const _selectSql =
      'SELECT * FROM ${DatabaseConstants.yourRatesTable} '
      'WHERE (? IS NULL OR ${DatabaseConstants.companyIdColumn} = ?) '
      'AND (? IS NULL OR ${DatabaseConstants.categoryColumn} = ?)';

  static const _selectByIdSql =
      'SELECT * FROM ${DatabaseConstants.yourRatesTable} '
      'WHERE ${DatabaseConstants.idColumn} = ?';

  static const _insertSql =
      'INSERT INTO ${DatabaseConstants.yourRatesTable} '
      '(${DatabaseConstants.idColumn}, ${DatabaseConstants.companyIdColumn}, '
      '${DatabaseConstants.categoryColumn}, ${DatabaseConstants.itemNameColumn}, '
      '${DatabaseConstants.rateAmountColumn}, ${DatabaseConstants.rateCurrencyColumn}, '
      '${DatabaseConstants.unitColumn}, ${DatabaseConstants.equipmentMethodColumn}, '
      '${DatabaseConstants.entryLabelColumn}, ${DatabaseConstants.savedAtColumn}, '
      '${DatabaseConstants.createdAtColumn}, ${DatabaseConstants.updatedAtColumn}) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)';

  static const _updateSql =
      'UPDATE ${DatabaseConstants.yourRatesTable} SET '
      '${DatabaseConstants.companyIdColumn} = ?, '
      '${DatabaseConstants.categoryColumn} = ?, '
      '${DatabaseConstants.itemNameColumn} = ?, '
      '${DatabaseConstants.rateAmountColumn} = ?, '
      '${DatabaseConstants.rateCurrencyColumn} = ?, '
      '${DatabaseConstants.unitColumn} = ?, '
      '${DatabaseConstants.equipmentMethodColumn} = ?, '
      '${DatabaseConstants.entryLabelColumn} = ?, '
      '${DatabaseConstants.savedAtColumn} = ?, '
      '${DatabaseConstants.updatedAtColumn} = ? '
      'WHERE ${DatabaseConstants.idColumn} = ?';

  Future<SyncStreamHandle>? _streamHandle;

  /// Creates a data source over [_database], stamping writes from [_clock].
  LocalYourRatesDataSource({required this._database, required this._clock});

  @override
  Future<List<YourRateEntryDto>> fetchRates({
    String? category,
    String? companyId,
    int? limit,
  }) async {
    try {
      await _ensureSyncing();
      final rows = await _database.getAll(_selectSql, [
        companyId,
        companyId,
        category,
        category,
      ]);
      final dtos = rows.map(YourRateEntryDto.fromJson).toList()
        ..sort((a, b) => _savedAt(b).compareTo(_savedAt(a)));
      return limit == null ? dtos : dtos.take(limit).toList();
    } catch (e, stack) {
      _logger.error('Failed to read your rates from the phone', e, stack);
      rethrow;
    }
  }

  @override
  Future<YourRateEntryDto> insertRate(YourRateEntryDto dto) async {
    try {
      await _ensureSyncing();
      final id = uuid.v4();
      final now = _clock.now().toUtc().toIso8601String();
      await _database.execute(_insertSql, [
        id,
        dto.companyId,
        dto.category,
        dto.itemName,
        dto.rateAmount,
        dto.rateCurrency,
        dto.unit,
        dto.equipmentMethod,
        dto.entryLabel,
        dto.savedAt,
        now,
        now,
      ]);
      return _readById(id);
    } catch (e, stack) {
      _logger.error('Failed to save your rate on the phone', e, stack);
      rethrow;
    }
  }

  @override
  Future<YourRateEntryDto> updateRate(String id, YourRateEntryDto dto) async {
    try {
      await _ensureSyncing();
      await _database.execute(_updateSql, [
        dto.companyId,
        dto.category,
        dto.itemName,
        dto.rateAmount,
        dto.rateCurrency,
        dto.unit,
        dto.equipmentMethod,
        dto.entryLabel,
        dto.savedAt,
        _clock.now().toUtc().toIso8601String(),
        id,
      ]);
      return _readById(id);
    } catch (e, stack) {
      _logger.error('Failed to update your rate on the phone', e, stack);
      rethrow;
    }
  }

  /// Releases the `user_rates` subscription. The database itself belongs to
  /// `PowerSyncModule` and stays open.
  Future<void> dispose() async {
    final handle = _streamHandle;
    _streamHandle = null;
    (await handle)?.unsubscribe();
  }

  Future<SyncStreamHandle> _ensureSyncing() async {
    final pending = _streamHandle ??= _database.syncStream(_streamName);
    try {
      return await pending;
    } catch (_) {
      _streamHandle = null;
      rethrow;
    }
  }

  Future<YourRateEntryDto> _readById(String id) async {
    final rows = await _database.getAll(_selectByIdSql, [id]);
    if (rows.isEmpty) {
      throw StateError('No your_rates row with id $id on this phone');
    }
    return YourRateEntryDto.fromJson(rows.first);
  }

  DateTime _savedAt(YourRateEntryDto dto) => DateTime.parse(dto.savedAt);
}
