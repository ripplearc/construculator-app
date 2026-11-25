import 'dart:async';

import 'package:construculator/libraries/calculation/domain/entities/calculation_session.dart';
import 'package:construculator/libraries/calculation/domain/repositories/calculation_session_repository.dart';
import 'package:construculator/libraries/calculator_engine/models/calculator_preferences.dart';
import 'package:construculator/libraries/calculator_engine/models/chip.dart';
import 'package:construculator/libraries/calculator_engine/tape.dart';
import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/calculator_error_type.dart';
import 'package:construculator/libraries/errors/failures.dart';

/// An in-memory [CalculationSessionRepository] for BLoC and widget tests:
/// the signed-in user's sessions in a list, every banked tape kept so it
/// can be restored, ids minted in order, and a watch that emits now and
/// after every write.
///
/// Set [signedIn] false to refuse a bank or a search as `notSignedIn`, or
/// [writeFailure] to refuse every write with it; [now] stamps the writes.
class FakeCalculationSessionRepository implements CalculationSessionRepository {
  /// The sessions as banked, newest first.
  final List<CalculationSession> sessions = [];

  /// The tape of each session, by session id.
  final Map<String, Tape> tapes = {};

  /// The failure every write answers when set.
  Failure? writeFailure;

  /// Whether a user is signed in; a bank or a search is refused otherwise.
  bool signedIn = true;

  /// The user the fake names on a banked session.
  String creatorUserId = 'user-1';

  /// What a write is stamped with.
  DateTime now = DateTime.utc(2026, 1, 1);

  /// How many times [bankSession] was called.
  int bankCallCount = 0;

  final _changes = StreamController<void>.broadcast();
  var _nextId = 0;

  /// Forgets every session and tape and every counter; keeps the flags.
  void reset() {
    sessions.clear();
    tapes.clear();
    bankCallCount = 0;
    _nextId = 0;
  }

  @override
  Stream<List<CalculationSession>> watchSessions() =>
      Stream<List<CalculationSession>>.multi((controller) {
        List<CalculationSession> current() =>
            signedIn ? List.unmodifiable(sessions) : const [];
        controller.add(current());
        final subscription = _changes.stream.listen(
          (_) => controller.add(current()),
          onDone: controller.close,
        );
        controller.onCancel = subscription.cancel;
      });

  @override
  Future<Either<Failure, CalculationSession>> bankSession(
    Tape tape, {
    String? title,
  }) async {
    bankCallCount++;
    if (!signedIn) return _notSignedIn();
    if (writeFailure case final failure?) return Left(failure);
    final result = switch (tape.chips.lastOrNull) {
      ResultChip(:final value) => value,
      _ => null,
    };
    final session = CalculationSession(
      id: 'session-${++_nextId}',
      creatorUserId: creatorUserId,
      title: title,
      resultText: result == null ? null : tape.formatter.format(result),
      result: result,
      createdAt: now,
      updatedAt: now,
      lastCalculationAt: now,
    );
    sessions.insert(0, session);
    tapes[session.id] = tape;
    _changes.add(null);
    return Right(session);
  }

  @override
  Future<Either<Failure, CalculationSession>> getSession(String id) async {
    final session = _find(id);
    return session == null ? _notFound() : Right(session);
  }

  @override
  Future<Either<Failure, Tape>> restoreTape(
    String id, {
    required CalculatorPreferences preferences,
  }) async {
    final tape = tapes[id];
    if (tape == null) return _notFound();
    return Right(Tape(chips: tape.chips, preferences: preferences));
  }

  @override
  Future<Either<Failure, void>> renameSession(String id, String title) async {
    if (writeFailure case final failure?) return Left(failure);
    final session = _find(id);
    if (session == null) return _notFound();
    sessions[sessions.indexOf(session)] = session.copyWith(
      title: () => title,
      updatedAt: now,
    );
    _changes.add(null);
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> deleteSession(String id) async {
    if (writeFailure case final failure?) return Left(failure);
    final session = _find(id);
    if (session == null) return _notFound();
    sessions.remove(session);
    tapes.remove(id);
    _changes.add(null);
    return const Right(null);
  }

  @override
  Future<Either<Failure, List<CalculationSession>>> search(String query) async {
    if (!signedIn) return _notSignedIn();
    final needle = query.toLowerCase();
    return Right([
      for (final session in sessions)
        if ((session.title?.toLowerCase().contains(needle) ?? false) ||
            (session.resultText?.toLowerCase().contains(needle) ?? false))
          session,
    ]);
  }

  @override
  void dispose() => unawaited(_changes.close());

  CalculationSession? _find(String id) =>
      sessions.where((session) => session.id == id).firstOrNull;

  static Left<Failure, T> _notFound<T>() =>
      const Left(CalculatorFailure(errorType: CalculatorErrorType.notFound));

  static Left<Failure, T> _notSignedIn<T>() =>
      const Left(CalculatorFailure(errorType: CalculatorErrorType.notSignedIn));
}
