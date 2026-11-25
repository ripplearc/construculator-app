// coverage:ignore-file
import 'package:construculator/libraries/calculation/data/models/calculation_session_dto.dart';
import 'package:construculator/libraries/calculation/data/models/calculation_tape_dto.dart';

/// The calculator's history on this phone: the rows of the local-only
/// `calculator_sessions` and `calculator_tapes` tables (Design Appendices
/// B and E). Every method throws what the store throws; the repository
/// turns that into a failure.
abstract class LocalCalculationSessionDataSource {
  /// The sessions [creatorUserId] banked, newest first, now and after
  /// every change.
  Stream<List<CalculationSessionDto>> watchSessions(String creatorUserId);

  /// The session called [id], or `null` when there is none.
  Future<CalculationSessionDto?> fetchSessionById(String id);

  /// The tape of the session called [sessionId], or `null` when there is
  /// none.
  Future<CalculationTapeDto?> fetchTapeBySessionId(String sessionId);

  /// Writes [session] and its [tape] in one transaction, then prunes the
  /// user's oldest sessions past the number kept.
  Future<void> insertSession(
    CalculationSessionDto session,
    CalculationTapeDto tape,
  );

  /// Gives the session called [id] the [title], stamped [updatedAt];
  /// `false` when there is no such session.
  Future<bool> renameSession(String id, String title, DateTime updatedAt);

  /// Removes the session called [id] and its tape; `false` when there is
  /// no such session.
  Future<bool> deleteSession(String id);

  /// The sessions of [creatorUserId] whose title or result text contains
  /// [query], newest first, at most [limit].
  Future<List<CalculationSessionDto>> searchSessions(
    String creatorUserId,
    String query, {
    int limit,
  });

  /// Ends every watch handed out.
  Future<void> dispose();
}
