import 'dart:async';

import 'package:construculator/features/estimation/data/data_source/interfaces/your_rate_refusal_data_source.dart';
import 'package:construculator/features/estimation/data/data_source/interfaces/your_rates_data_source.dart';
import 'package:construculator/features/estimation/data/models/your_rate_entry_dto.dart';
import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/domain/entities/refused_your_rate_entity.dart';
import 'package:construculator/features/estimation/domain/repositories/your_rates_repository.dart';
import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/estimation/domain/estimation_error_type.dart';
import 'package:construculator/libraries/logging/app_logger.dart';
import 'package:construculator/libraries/powersync/models/your_rate_refusal_key.dart';

/// Implementation of [YourRatesRepository] over the phone's own database.
class YourRatesRepositoryImpl implements YourRatesRepository {
  YourRatesRepositoryImpl({
    required this.dataSource,
    required this.refusalDataSource,
  });

  final YourRatesDataSource dataSource;
  final YourRateRefusalDataSource refusalDataSource;
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
      final entries = dtos.map(_toEntry).toList()
        ..sort(_mostRecentlyUsedFirst);

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
  Future<Either<Failure, void>> save(YourRateEntry entry) async {
    if (entry.companyId.trim().isEmpty) return const Left(_blankCompanyFailure);
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
                companyId: normalizedEntry.companyId,
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
        await _forgetRefusalOf(normalizedEntry);
        return const Right(null);
      }

      if (effectiveLabel == null) {
        return const Left(
          EstimationFailure(errorType: EstimationErrorType.duplicateEntry),
        );
      }

      final labelKey = _matchKey(effectiveLabel);
      final labelAlreadyUsed = existing.any((candidate) {
        final savedLabel = candidate.entryLabel;
        return savedLabel != null && _matchKey(savedLabel) == labelKey;
      });

      if (labelAlreadyUsed) {
        return const Left(
          EstimationFailure(errorType: EstimationErrorType.duplicateLabel),
        );
      }

      await dataSource.insertRate(YourRateEntryDto.fromEntity(normalizedEntry));
      await _forgetRefusalOf(normalizedEntry);
      return const Right(null);
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
  Stream<Either<Failure, RefusedYourRate?>> watchUnshownRefusal(
    String itemName,
    EquipmentPricingMethod? equipmentMethod,
  ) {
    return refusalDataSource
        .watchRefusalByItem(itemName, equipmentMethod?.toJson())
        .map<Either<Failure, RefusedYourRate?>>((refusal) {
          final unshown = refusal?.shownAt == null ? refusal : null;
          return Right(unshown?.toEntity());
        })
        .transform(
          StreamTransformer.fromHandlers(
            handleError: (error, stack, sink) =>
                sink.add(Left(_handleError(error))),
          ),
        );
  }

  @override
  Future<Either<Failure, void>> markRefusalShown(
    String itemName,
    EquipmentPricingMethod? equipmentMethod,
  ) async {
    try {
      await refusalDataSource.markRefusalShownByItem(
        itemName,
        equipmentMethod?.toJson(),
      );
      return const Right(null);
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  Future<void> _forgetRefusalOf(YourRateEntry entry) => refusalDataSource
      .deleteRefusalByItem(entry.itemName, entry.equipmentMethod?.toJson());

  Future<List<YourRateEntryDto>> _loadRatesAsLastAccepted({
    String? category,
    String? companyId,
  }) async {
    final dtos = await dataSource.loadRates(
      category: category,
      companyId: companyId,
    );
    final refusals = {
      for (final refusal in await refusalDataSource.loadAllRefusals())
        refusal.id: refusal,
    };
    final lastAccepted = <YourRateEntryDto>[];
    for (final dto in dtos) {
      final refusal =
          refusals[YourRateRefusalKey.of(dto.itemName, dto.equipmentMethod)];
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
  }) async {
    final nameKey = _matchKey(itemName);
    final dtos = await _loadRatesAsLastAccepted(
      category: category.toJson(),
      companyId: companyId,
    );
    return dtos
        .map(_toEntry)
        .where((entry) => _matchKey(entry.itemName) == nameKey)
        .toList();
  }

  static String _matchKey(String text) =>
      text.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

  static String? _normalizeLabel(String? label) {
    final trimmed = label?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
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
