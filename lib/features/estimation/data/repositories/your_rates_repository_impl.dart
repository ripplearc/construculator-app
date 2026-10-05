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
    int? limit,
  }) async {
    try {
      final dtos = await dataSource.fetchRates(
        category: category?.toJson(),
        limit: query.isEmpty ? limit : null,
      );
      final entries = dtos.map((dto) => dto.toEntity()).toList();

      final words = query
          .toLowerCase()
          .split(RegExp(r'\s+'))
          .where((word) => word.isNotEmpty)
          .toList();
      if (words.isEmpty) {
        return Right(entries);
      }

      return Right(
        entries.where((entry) {
          final name = entry.itemName.toLowerCase();
          return words.any(name.contains);
        }).toList(),
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
      final matches = await _entriesNamed(category, itemName);
      if (matches.length != 1) {
        return const Right(null);
      }
      return Right(matches.single);
    } catch (e) {
      return Left(_handleError(e, 'getting your rate by item name'));
    }
  }

  @override
  Future<Either<Failure, void>> save(YourRateEntry entry) async {
    try {
      final effectiveLabel = _normalizeLabel(entry.entryLabel);
      final normalizedEntry = entry.copyWith(
        itemName: entry.itemName.trim(),
        entryLabel: effectiveLabel ?? clearField,
      );

      final existing =
          (await _entriesNamed(
                normalizedEntry.category,
                normalizedEntry.itemName,
              ))
              .where(
                (candidate) =>
                    candidate.equipmentMethod ==
                    normalizedEntry.equipmentMethod,
              )
              .toList();

      if (existing.isEmpty) {
        await dataSource.insertRate(
          YourRateEntryDto.fromEntity(normalizedEntry),
        );
        return const Right(null);
      }

      final sameLabel = existing
          .where(
            (candidate) =>
                _normalizeLabel(candidate.entryLabel) == effectiveLabel,
          )
          .firstOrNull;

      if (sameLabel != null) {
        await dataSource.updateRate(
          sameLabel.id,
          YourRateEntryDto.fromEntity(normalizedEntry),
        );
        return const Right(null);
      }

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

  Future<List<YourRateEntry>> _entriesNamed(
    CostItemType category,
    String itemName,
  ) async {
    final nameKey = _nameKey(itemName);
    final dtos = await dataSource.fetchRates(category: category.toJson());
    return dtos
        .map((dto) => dto.toEntity())
        .where((entry) => _nameKey(entry.itemName) == nameKey)
        .toList();
  }

  static String _nameKey(String name) =>
      name.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

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
          // The unique constraint on (company, category, name, method, label)
          // in be#57 catches a concurrent save that slips past save()'s
          // read-then-decide checks.
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
