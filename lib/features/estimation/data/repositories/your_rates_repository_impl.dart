import 'dart:async';

import 'package:construculator/features/estimation/data/data_source/interfaces/your_rate_refusal_data_source.dart';
import 'package:construculator/features/estimation/data/data_source/interfaces/your_rates_data_source.dart';
import 'package:construculator/features/estimation/data/models/your_rate_entry_dto.dart';
import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/domain/entities/refused_your_rate_entity.dart';
import 'package:construculator/features/estimation/domain/repositories/your_rates_repository.dart';
import 'package:construculator/libraries/auth/interfaces/auth_repository.dart';
import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/estimation/domain/estimation_error_type.dart';
import 'package:construculator/libraries/logging/app_logger.dart';
import 'package:construculator/libraries/powersync/models/your_rate_id.dart';
import 'package:construculator/libraries/powersync/models/your_rate_refusal_key.dart';

/// Implementation of [YourRatesRepository] over the phone's own database.
class YourRatesRepositoryImpl implements YourRatesRepository {
  YourRatesRepositoryImpl({
    required this.dataSource,
    required this.refusalDataSource,
    required this.authRepository,
    this.saveTimeLimit = yourRatesSaveTimeLimit,
  });

  final YourRatesDataSource dataSource;

  /// The record of defaults the server refused, so a refused price is not
  /// shown as the saved one.
  final YourRateRefusalDataSource refusalDataSource;

  /// Tells whose refusals to read and forget: a user never sees another
  /// user's refusal, even in the same company.
  final AuthRepository authRepository;

  /// How long [save] waits for the phone before it reports a
  /// [EstimationErrorType.timeoutError]. A save that finishes after that is
  /// undone, so the failure the user was shown stays true: a new row is
  /// deleted and a replaced row gets its old price back.
  final Duration saveTimeLimit;

  Future<void>? _pendingUndo;
  static final _logger = AppLogger().tag('YourRatesRepositoryImpl');
  static const _blankCompanyFailure = EstimationFailure(
    errorType: EstimationErrorType.permissionDenied,
  );

  @override
  Future<Either<Failure, List<YourRateEntry>>> search(
    String query, {
    CostItemType? category,
    required String companyId,
    int? limit,
  }) async {
    if (companyId.trim().isEmpty) return const Left(_blankCompanyFailure);
    try {
      final dtos = await _loadRatesAsLastAccepted(
        category: category?.toJson(),
        companyId: companyId,
      );
      final entries = dtos.map(_toEntry).toList()..sort(_mostRecentlyUsedFirst);

      final words = query
          .toLowerCase()
          .split(RegExp(r'\s+'))
          .where((word) => word.isNotEmpty)
          .toList();
      if (words.isEmpty) {
        return Right(limit == null ? entries : entries.take(limit).toList());
      }

      return Right(
        entries.where((entry) {
          final name = entry.itemName.toLowerCase();
          return words.any(name.contains);
        }).toList(),
      );
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  static int _mostRecentlyUsedFirst(YourRateEntry a, YourRateEntry b) {
    final byRecency = b.recencyAt.compareTo(a.recencyAt);
    return byRecency != 0 ? byRecency : b.savedAt.compareTo(a.savedAt);
  }

  @override
  Future<Either<Failure, YourRateEntry?>> getByItemName(
    String itemName,
    CostItemType category, {
    required String companyId,
  }) async {
    if (companyId.trim().isEmpty) return const Left(_blankCompanyFailure);
    try {
      final matches = await _entriesNamed(
        category,
        itemName,
        companyId: companyId,
      );
      if (matches.length != 1) {
        return const Right(null);
      }
      return Right(matches.single);
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  @override
  Future<Either<Failure, YourRateEntry?>> getByItemNameAndLabel(
    String itemName,
    CostItemType category, {
    required EquipmentPricingMethod? method,
    required String label,
    required String companyId,
  }) async {
    if (companyId.trim().isEmpty) return const Left(_blankCompanyFailure);
    try {
      final labelKey = _matchKey(label);
      final matches =
          (await _entriesNamed(category, itemName, companyId: companyId)).where(
            (entry) {
              final savedLabel = entry.entryLabel;
              return entry.equipmentMethod == method &&
                  savedLabel != null &&
                  _matchKey(savedLabel) == labelKey;
            },
          );
      return Right(matches.firstOrNull);
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  @override
  Future<Either<Failure, void>> save(
    YourRateEntry entry, {
    Duration? within,
    String? replacesRateId,
  }) async {
    final saving = _saveAfterPendingUndo(entry, replacesRateId);
    final result = await saving.timeout(
      within ?? saveTimeLimit,
      onTimeout: () {
        _pendingUndo = _undoWhenSaved(saving);
        return const Left(
          EstimationFailure(errorType: EstimationErrorType.timeoutError),
        );
      },
    );
    final saved = result.getRightOrNull();
    if (saved != null) await _forgetRefusalOf(saved.entry);
    return result.fold(Left.new, (_) => const Right(null));
  }

  Future<Either<Failure, _SavedOnPhone>> _saveAfterPendingUndo(
    YourRateEntry entry,
    String? replacesRateId,
  ) async {
    final pendingUndo = _pendingUndo;
    if (pendingUndo != null) await pendingUndo;
    return _saveOnPhone(entry, replacesRateId);
  }

  Future<void> _undoWhenSaved(
    Future<Either<Failure, _SavedOnPhone>> saving,
  ) async {
    final saved = (await saving).getRightOrNull();
    if (saved == null) return;
    try {
      await saved.undo();
    } catch (_) {
      // The data source already logged this failure. The user was told the
      // rate was not saved and nothing more can be done here.
    }
  }

  Future<Either<Failure, _SavedOnPhone>> _saveOnPhone(
    YourRateEntry entry,
    String? replacesRateId,
  ) async {
    if (entry.companyId.trim().isEmpty) return const Left(_blankCompanyFailure);
    try {
      final normalizedEntry = entry.copyWith(
        itemName: entry.itemName.trim(),
        entryLabel: _normalizeLabel(entry.entryLabel) ?? clearField,
      );

      final existing =
          (await _entriesNamed(
                normalizedEntry.category,
                normalizedEntry.itemName,
                companyId: normalizedEntry.companyId,
                asLastAccepted: false,
              ))
              .where(
                (candidate) =>
                    candidate.equipmentMethod ==
                    normalizedEntry.equipmentMethod,
              )
              .toList();

      final lastAccepted = await _entriesNamed(
        normalizedEntry.category,
        normalizedEntry.itemName,
        companyId: normalizedEntry.companyId,
      );
      final acceptedIds = lastAccepted.map((candidate) => candidate.id).toSet();
      final neverAccepted = existing
          .where((candidate) => !acceptedIds.contains(candidate.id))
          .toList();
      final accepted = existing
          .where((candidate) => acceptedIds.contains(candidate.id))
          .toList();

      if (accepted.isNotEmpty) {
        final failure = replacesRateId == null
            ? _collisionFailure(accepted, normalizedEntry.entryLabel)
            : _missingRowFailure(accepted, replacesRateId);
        if (failure != null) return Left(failure);
      }

      final newDto = YourRateEntryDto.fromEntity(normalizedEntry);
      final newId = YourRateId.of(
        companyId: newDto.companyId,
        category: newDto.category,
        itemName: newDto.itemName,
        equipmentMethod: newDto.equipmentMethod,
        entryLabel: newDto.entryLabel,
      );
      final refusedUnderNewId = neverAccepted
          .where((candidate) => candidate.id == newId)
          .firstOrNull;
      await _deleteRows(
        neverAccepted.where((candidate) => candidate.id != newId).toList(),
      );

      if (accepted.isEmpty || replacesRateId == null) {
        if (refusedUnderNewId != null) {
          final retried = _toEntry(await dataSource.updateRate(newId, newDto));
          return Right((
            entry: retried,
            undo: () => dataSource.updateRate(
              newId,
              YourRateEntryDto.fromEntity(refusedUnderNewId),
            ),
          ));
        }
        final inserted = _toEntry(await dataSource.insertRate(newDto));
        return Right((
          entry: inserted,
          undo: () => _deleteRowIfStillWrittenBy(normalizedEntry, inserted.id),
        ));
      }

      final replaced = accepted.firstWhere(
        (candidate) => candidate.id == replacesRateId,
      );
      final priceTheServerHolds = lastAccepted
          .firstWhere((candidate) => candidate.id == replaced.id)
          .rate;
      if (replaced.rate == normalizedEntry.rate &&
          priceTheServerHolds != normalizedEntry.rate) {
        // An update that changes no price sends no price. Writing the price the
        // server holds first makes the new price a change the server receives.
        await dataSource.updateRate(
          replaced.id,
          YourRateEntryDto.fromEntity(
            replaced.copyWith(rate: priceTheServerHolds),
          ),
        );
      }
      final updated = _toEntry(
        await dataSource.updateRate(
          replaced.id,
          YourRateEntryDto.fromEntity(
            replaced.copyWith(
              rate: normalizedEntry.rate,
              unit: normalizedEntry.unit ?? clearField,
              savedAt: normalizedEntry.savedAt,
            ),
          ),
        ),
      );
      return Right((
        entry: updated,
        undo: () => dataSource.updateRate(
          replaced.id,
          YourRateEntryDto.fromEntity(replaced),
        ),
      ));
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  @override
  Future<Either<Failure, void>> recordRateUse(String rateId) async {
    try {
      await dataSource.stampLastUsedAtById(rateId);
      return const Right(null);
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  @override
  Stream<Either<Failure, RefusedYourRate?>> watchRefusal({
    required String companyId,
    required CostItemType category,
    required String itemName,
    EquipmentPricingMethod? equipmentMethod,
  }) {
    final userId = authRepository.getCurrentCredentials()?.id;
    if (userId == null) return Stream.value(const Right(null));
    return refusalDataSource
        .watchRefusalByItem(
          userId: userId,
          companyId: companyId,
          category: category.toJson(),
          itemName: itemName,
          equipmentMethod: equipmentMethod?.toJson(),
        )
        .map<Either<Failure, RefusedYourRate?>>(
          (refusal) => Right(refusal?.toEntity()),
        )
        .transform(
          StreamTransformer.fromHandlers(
            handleError: (error, stack, sink) =>
                sink.add(Left(_handleError(error))),
          ),
        );
  }

  @override
  Future<Either<Failure, void>> markRefusalShown({
    required String companyId,
    required CostItemType category,
    required String itemName,
    EquipmentPricingMethod? equipmentMethod,
  }) async {
    final userId = authRepository.getCurrentCredentials()?.id;
    if (userId == null) return const Right(null);
    try {
      await refusalDataSource.markRefusalShownByItem(
        userId: userId,
        companyId: companyId,
        category: category.toJson(),
        itemName: itemName,
        equipmentMethod: equipmentMethod?.toJson(),
      );
      return const Right(null);
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  Future<void> _deleteRowIfStillWrittenBy(
    YourRateEntry written,
    String rowId,
  ) async {
    final rows = await _entriesNamed(
      written.category,
      written.itemName,
      companyId: written.companyId,
      asLastAccepted: false,
    );
    final current = rows.where((row) => row.id == rowId).firstOrNull;
    if (current == null || !_holdsWhatWasWritten(current, written)) return;
    await dataSource.deleteRateById(rowId);
  }

  static bool _holdsWhatWasWritten(YourRateEntry row, YourRateEntry written) =>
      row.rate == written.rate &&
      row.unit == written.unit &&
      row.savedAt == written.savedAt &&
      row.entryLabel == written.entryLabel;

  Future<void> _deleteRows(List<YourRateEntry> rows) async {
    for (final row in rows) {
      await dataSource.deleteRateById(row.id);
    }
  }

  Future<void> _forgetRefusalOf(YourRateEntry entry) async {
    try {
      final userId = authRepository.getCurrentCredentials()?.id;
      if (userId == null) return;
      await refusalDataSource.deleteRefusalByItem(
        userId: userId,
        companyId: entry.companyId,
        category: entry.category.toJson(),
        itemName: entry.itemName,
        equipmentMethod: entry.equipmentMethod?.toJson(),
      );
    } catch (e, stack) {
      _logger.warning(
        'Could not forget the refusal of a saved rate; the save itself worked',
        e,
        stack,
      );
    }
  }

  Future<List<YourRateEntryDto>> _loadRatesAsLastAccepted({
    String? category,
    String? companyId,
  }) async {
    final dtos = await dataSource.loadRates(
      category: category,
      companyId: companyId,
    );
    final userId = authRepository.getCurrentCredentials()?.id;
    final refusals = {
      for (final refusal in await refusalDataSource.loadAllRefusals())
        if (refusal.userId == userId) refusal.refusedRowId: refusal,
    };
    final lastAccepted = <YourRateEntryDto>[];
    for (final dto in dtos) {
      final refusal = refusals[dto.id];
      if (refusal == null || refusal.refusedAmount != dto.rateAmount) {
        lastAccepted.add(dto);
        continue;
      }
      final acceptedAmount = refusal.acceptedAmount;
      if (acceptedAmount != null) {
        lastAccepted.add(dto.withRateAmount(acceptedAmount));
      }
    }
    return lastAccepted;
  }

  Future<List<YourRateEntry>> _entriesNamed(
    CostItemType category,
    String itemName, {
    required String companyId,
    bool asLastAccepted = true,
  }) async {
    final nameKey = _matchKey(itemName);
    final dtos = asLastAccepted
        ? await _loadRatesAsLastAccepted(
            category: category.toJson(),
            companyId: companyId,
          )
        : await dataSource.loadRates(
            category: category.toJson(),
            companyId: companyId,
          );
    return dtos
        .map(_toEntry)
        .where((entry) => _matchKey(entry.itemName) == nameKey)
        .toList();
  }

  static String _matchKey(String text) =>
      YourRateRefusalKey.normalizeName(text);

  static String? _normalizeLabel(String? label) {
    final trimmed = label?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  static EstimationFailure? _collisionFailure(
    List<YourRateEntry> accepted,
    String? label,
  ) {
    if (label == null) {
      return const EstimationFailure(
        errorType: EstimationErrorType.duplicateEntry,
      );
    }
    final labelKey = _matchKey(label);
    final labelAlreadyUsed = accepted.any((candidate) {
      final savedLabel = candidate.entryLabel;
      return savedLabel != null && _matchKey(savedLabel) == labelKey;
    });
    return labelAlreadyUsed
        ? const EstimationFailure(errorType: EstimationErrorType.duplicateLabel)
        : null;
  }

  static EstimationFailure? _missingRowFailure(
    List<YourRateEntry> accepted,
    String replacesRateId,
  ) {
    final rowIsSaved = accepted.any(
      (candidate) => candidate.id == replacesRateId,
    );
    return rowIsSaved
        ? null
        : const EstimationFailure(errorType: EstimationErrorType.notFoundError);
  }

  static YourRateEntry _toEntry(YourRateEntryDto dto) {
    try {
      return dto.toEntity();
    } catch (e, stack) {
      _logger.error('Could not read a stored Your rates row', e, stack);
      rethrow;
    }
  }

  Failure _handleError(Object error) {
    if (error is FormatException || error is TypeError) {
      return const EstimationFailure(
        errorType: EstimationErrorType.parsingError,
      );
    }

    return const EstimationFailure(
      errorType: EstimationErrorType.unexpectedDatabaseError,
    );
  }
}

typedef _SavedOnPhone = ({YourRateEntry entry, Future<void> Function() undo});
