import 'dart:async';
import 'dart:io';

import 'package:construculator/features/estimation/data/data_source/interfaces/your_rates_data_source.dart';
import 'package:construculator/features/estimation/data/models/your_rate_entry_dto.dart';
import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/domain/repositories/your_rates_repository.dart';
import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/estimation/domain/estimation_error_type.dart';
import 'package:construculator/libraries/logging/app_logger.dart';
import 'package:construculator/libraries/supabase/data/supabase_types.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// Supabase-backed implementation of [YourRatesRepository].
class YourRatesRepositoryImpl implements YourRatesRepository {
  YourRatesRepositoryImpl({required this.dataSource});

  final YourRatesDataSource dataSource;
  static final _logger = AppLogger().tag('YourRatesRepositoryImpl');

  @override
  Future<Either<Failure, List<YourRateEntry>>> search(
    String query, {
    CostItemType? category,
  }) async {
    try {
      final dtos = await dataSource.fetchRates(category: category?.toJson());
      final entries = dtos.map((dto) => dto.toEntity()).toList();

      if (query.isEmpty) {
        return Right(entries);
      }

      final lowerQuery = query.toLowerCase();
      return Right(
        entries
            .where((entry) => entry.itemName.toLowerCase().contains(lowerQuery))
            .toList(),
      );
    } catch (e) {
      return Left(_handleError(e, 'searching your rates'));
    }
  }

  @override
  Future<Either<Failure, YourRateEntry?>> getByItemName(
    String itemName,
    CostItemType category,
  ) async {
    try {
      final dtos = await dataSource.fetchGrouping(
        category: category.toJson(),
        itemName: itemName,
      );

      // Multiple entries can legally share a grouping (Decision 55); a
      // single-entry return would be a guess in that case, so only an exact
      // one-row match resolves. See YourRatesRepository.getByItemName's doc
      // comment for the full reasoning.
      if (dtos.length != 1) {
        return const Right(null);
      }
      return Right(dtos.single.toEntity());
    } catch (e) {
      return Left(_handleError(e, 'getting your rate by item name'));
    }
  }

  @override
  Future<Either<Failure, void>> save(YourRateEntry entry) async {
    try {
      // A blank label ('' or whitespace-only) means the same thing as no
      // label at all. Normalizing here — rather than trusting entry.entryLabel
      // == null directly — matters because a UI text field naturally hands
      // back '' for an empty input, not null; without this, such a save
      // would silently skip the rejection rule below instead of triggering
      // it.
      final effectiveLabel = _normalizeLabel(entry.entryLabel);
      final normalizedEntry = entry.copyWith(
        entryLabel: effectiveLabel ?? clearField,
      );

      final existingDtos = await dataSource.fetchGrouping(
        category: normalizedEntry.category.toJson(),
        itemName: normalizedEntry.itemName,
      );

      if (existingDtos.isEmpty) {
        await dataSource.insertRate(YourRateEntryDto.fromEntity(normalizedEntry));
        return const Right(null);
      }

      final existing = existingDtos.map((dto) => dto.toEntity()).toList();

      // Matches when both this entry's and the existing row's labels are
      // null: Dart's `==` on null does the right thing here without any
      // special-casing.
      final sameLabel = existing
          .where(
            (candidate) => _normalizeLabel(candidate.entryLabel) == effectiveLabel,
          )
          .firstOrNull;

      if (sameLabel != null) {
        await dataSource.updateRate(
          sameLabel.id,
          YourRateEntryDto.fromEntity(normalizedEntry),
        );
        return const Right(null);
      }

      // The grouping is already populated, nothing in it shares this
      // entry's label, and this entry itself has no label: rejecting here
      // is what stops a second unlabeled save from either silently
      // overwriting an unrelated labeled entry or landing as an ambiguous
      // extra row. The DB's unique index (on the grouping columns plus
      // COALESCE(entry_label, '')) still catches an exact concurrent
      // double-unlabeled race as a defense-in-depth backstop, but it can't
      // catch THIS case on its own — a NULL-labeled row and a labeled one
      // don't collide at the index level at all.
      if (effectiveLabel == null) {
        return const Left(
          EstimationFailure(errorType: EstimationErrorType.duplicateEntry),
        );
      }

      await dataSource.insertRate(YourRateEntryDto.fromEntity(normalizedEntry));
      return const Right(null);
    } catch (e) {
      return Left(_handleError(e, 'saving your rate'));
    }
  }

  // Treats a blank label ('' or whitespace-only) the same as no label.
  static String? _normalizeLabel(String? label) {
    final trimmed = label?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  Failure _handleError(Object error, String operation) {
    if (error is TimeoutException) {
      _logger.error(
        'Timeout error $operation: message=${error.message}, duration=${error.duration}',
      );
      return const EstimationFailure(
        errorType: EstimationErrorType.timeoutError,
      );
    }

    if (error is SocketException) {
      _logger.warning('Connection error $operation: message=${error.message}');
      return const EstimationFailure(
        errorType: EstimationErrorType.connectionError,
      );
    }

    if (error is FormatException) {
      _logger.error('Parsing error $operation: message=${error.message}');
      return const EstimationFailure(
        errorType: EstimationErrorType.parsingError,
      );
    }

    if (error is TypeError) {
      _logger.error('Parsing error $operation: ${error.toString()}');
      return const EstimationFailure(
        errorType: EstimationErrorType.parsingError,
      );
    }

    if (error is supabase.PostgrestException) {
      final code = PostgresErrorCode.fromCode(error.code);
      _logger.error(
        'PostgreSQL error $operation: code=${error.code}, '
        'message=${error.message}',
      );
      switch (code) {
        case PostgresErrorCode.rlsViolation:
          return const EstimationFailure(
            errorType: EstimationErrorType.permissionDenied,
          );
        case PostgresErrorCode.uniqueViolation:
          // Defense-in-depth only: save()'s read-then-decide checks above
          // reject every rejectable case before it ever reaches the
          // database. This branch exists solely to still return a sensible
          // failure if the unique index catches a genuine concurrent-write
          // race that slips past those checks.
          return const EstimationFailure(
            errorType: EstimationErrorType.duplicateEntry,
          );
        case PostgresErrorCode.noDataFound:
          return const EstimationFailure(
            errorType: EstimationErrorType.notFoundError,
          );
        case PostgresErrorCode.connectionFailure:
        case PostgresErrorCode.unableToConnect:
        case PostgresErrorCode.connectionDoesNotExist:
          return const EstimationFailure(
            errorType: EstimationErrorType.connectionError,
          );
        case PostgresErrorCode.unknownError:
          return const EstimationFailure(
            errorType: EstimationErrorType.unexpectedDatabaseError,
          );
      }
    }

    _logger.error('Unexpected error $operation: $error');
    return const EstimationFailure(
      errorType: EstimationErrorType.unexpectedError,
    );
  }
}
