import 'dart:async';

import 'package:construculator/libraries/calculation/data/data_source/interfaces/local_calculation_session_data_source.dart';
import 'package:construculator/libraries/calculation/data/models/calculation_session_dto.dart';
import 'package:construculator/libraries/calculation/data/models/calculation_tape_dto.dart';
import 'package:construculator/libraries/calculation/data/models/tape_chip_codec.dart';
import 'package:construculator/libraries/calculation/domain/entities/calculation_session.dart';
import 'package:construculator/libraries/calculation/domain/repositories/calculation_session_repository.dart';
import 'package:construculator/libraries/calculator_engine/models/calculator_preferences.dart';
import 'package:construculator/libraries/calculator_engine/models/chip.dart';
import 'package:construculator/libraries/calculator_engine/quantity_formatter.dart';
import 'package:construculator/libraries/calculator_engine/tape.dart';
import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/calculator_error_type.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/logging/app_logger.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:construculator/libraries/time/interfaces/clock.dart';
import 'package:powersync/powersync.dart';

/// [CalculationSessionRepository] over the local store: names the
/// signed-in user from [SupabaseWrapper], stamps writes from [Clock], writes
/// the tape through `TapeChipCodec`, and turns what the data source throws
/// into a [CalculatorFailure].
///
/// A banked session keeps what its history card shows: the last chip's
/// value and text when the tape ends on a result, nothing when it does not
/// ("Not finished", term 2.19), and beside every chip in the tape JSON its
/// text under the settings the tape was banked with. A tape whose JSON this
/// build cannot read — one written by a later build, or a damaged row — is
/// a `notFound` failure, logged as a warning and never half-read (Full
/// Design Doc, "Security": unknown versions render read-only). The watches
/// are the data source's own streams; [dispose] delegates to it, as the
/// recents repository does.
class CalculationSessionRepositoryImpl implements CalculationSessionRepository {
  static final _logger = AppLogger().tag('CalculationSessionRepositoryImpl');

  final LocalCalculationSessionDataSource _dataSource;
  final SupabaseWrapper _supabaseWrapper;
  final Clock _clock;

  /// Creates a repository over a local data source, naming the user from
  /// [SupabaseWrapper] and stamping writes from [Clock].
  CalculationSessionRepositoryImpl({
    required this._dataSource,
    required this._supabaseWrapper,
    required this._clock,
  });

  @override
  Stream<List<CalculationSession>> watchSessions() {
    final userId = _supabaseWrapper.getInternalUserId();
    if (userId == null) return Stream.value(const []);
    return _dataSource
        .watchSessions(userId)
        .map((rows) => [for (final row in rows) row.toEntity()]);
  }

  @override
  Future<Either<Failure, CalculationSession>> bankSession(
    Tape tape, {
    String? title,
  }) => _guard(() async {
    final userId = _signedInUserId();
    final now = _clock.now();
    final formatter = tape.formatter;
    final result = switch (tape.chips.lastOrNull) {
      ResultChip(:final value) => value,
      _ => null,
    };
    final session = CalculationSessionDto(
      id: uuid.v4(),
      creatorUserId: userId,
      title: title,
      resultText: result == null ? null : formatter.format(result),
      result: result,
      createdAt: now,
      updatedAt: now,
      lastCalculationAt: now,
    );
    await _dataSource.insertSession(
      session,
      CalculationTapeDto(
        id: uuid.v4(),
        sessionId: session.id,
        computation: TapeChipCodec.encode(
          tape.chips,
          text: (chip) => _textOf(chip, formatter),
        ),
        schemaVersion: TapeChipCodec.schemaVersion,
        createdAt: now,
      ),
    );
    return session.toEntity();
  }, 'banking a session');

  @override
  Future<Either<Failure, CalculationSession>> getSession(String id) =>
      _guard(() async {
        final session = await _dataSource.fetchSessionById(id);
        if (session == null) throw const _NotFound();
        return session.toEntity();
      }, 'reading a session');

  @override
  Future<Either<Failure, Tape>> restoreTape(
    String id, {
    required CalculatorPreferences preferences,
  }) => _guard(() async {
    final tape = await _dataSource.fetchTapeBySessionId(id);
    if (tape == null) throw const _NotFound();
    try {
      return Tape(
        chips: TapeChipCodec.decode(tape.computation),
        preferences: preferences,
      );
    } on FormatException catch (error) {
      _logger.warning(
        'The tape of session $id cannot be read by this build '
        '(schema_version ${tape.schemaVersion}): ${error.message}',
      );
      throw const _NotFound();
    }
  }, 'restoring a tape');

  @override
  Future<Either<Failure, void>> renameSession(String id, String title) =>
      _guard(() async {
        if (!await _dataSource.renameSession(id, title, _clock.now())) {
          throw const _NotFound();
        }
      }, 'renaming a session');

  @override
  Future<Either<Failure, void>> deleteSession(String id) => _guard(() async {
    if (!await _dataSource.deleteSession(id)) throw const _NotFound();
  }, 'deleting a session');

  @override
  Future<Either<Failure, List<CalculationSession>>> search(String query) =>
      _guard(() async {
        final rows = await _dataSource.searchSessions(_signedInUserId(), query);
        return [for (final row in rows) row.toEntity()];
      }, 'searching the sessions');

  @override
  void dispose() => unawaited(
    _dataSource.dispose().catchError((Object error, StackTrace stackTrace) {
      _logger.warning(
        'Failed to dispose the session data source',
        error,
        stackTrace,
      );
    }),
  );

  static String _textOf(TapeChip chip, QuantityFormatter formatter) =>
      switch (chip) {
        ValueChip(:final operator, :final entry) =>
          '${operator?.symbol ?? ''}${entry.text}',
        ResultChip(:final operator, :final value) =>
          '${operator?.symbol ?? ''}${formatter.format(value)}',
        BracketChip() => chip.expression,
        ErrorChip(:final error) => error.name,
      };

  String _signedInUserId() =>
      _supabaseWrapper.getInternalUserId() ?? (throw const _NotSignedIn());

  Future<Either<Failure, T>> _guard<T>(
    Future<T> Function() operation,
    String what,
  ) async {
    try {
      return Right(await operation());
    } on _NotSignedIn {
      _logger.warning('Refused $what: nobody is signed in');
      return const Left(
        CalculatorFailure(errorType: CalculatorErrorType.notSignedIn),
      );
    } on _NotFound {
      return const Left(
        CalculatorFailure(errorType: CalculatorErrorType.notFound),
      );
    } catch (error, stackTrace) {
      _logger.error('Error $what', error, stackTrace);
      return const Left(
        CalculatorFailure(errorType: CalculatorErrorType.storageError),
      );
    }
  }
}

class _NotFound implements Exception {
  const _NotFound();
}

class _NotSignedIn implements Exception {
  const _NotSignedIn();
}
