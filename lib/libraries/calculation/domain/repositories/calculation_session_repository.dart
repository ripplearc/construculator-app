// coverage:ignore-file
import 'package:construculator/libraries/calculation/domain/entities/calculation_session.dart';
import 'package:construculator/libraries/calculator_engine/models/calculator_preferences.dart';
import 'package:construculator/libraries/calculator_engine/tape.dart';
import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/failures.dart';

/// The calculator's history on this phone: banking a tape as a session,
/// listing, renaming, deleting and searching the signed-in user's
/// sessions, and bringing a banked tape back (UX Design Doc Section 1.7,
/// term 2.19; Design Appendices B).
///
/// A session belongs to the phone: it is never uploaded and survives
/// sign-out. Every write answers `Either<Failure, T>`; a `CalculatorFailure`
/// says whether nobody is signed in, the session is gone, or the store
/// refused.
abstract class CalculationSessionRepository {
  /// The signed-in user's sessions, newest first, now and after every
  /// change; empty while nobody is signed in.
  Stream<List<CalculationSession>> watchSessions();

  /// Banks [tape] as a new session of the signed-in user, the whole chip
  /// list as typed, with [title] when the user gave one.
  Future<Either<Failure, CalculationSession>> bankSession(
    Tape tape, {
    String? title,
  });

  /// The session called [id].
  Future<Either<Failure, CalculationSession>> getSession(String id);

  /// The tape banked as the session called [id], under [preferences], the
  /// settings in force now (rule 4.14: a setting re-renders a stored
  /// value and never changes it).
  Future<Either<Failure, Tape>> restoreTape(
    String id, {
    required CalculatorPreferences preferences,
  });

  /// Gives the session called [id] the [title].
  Future<Either<Failure, void>> renameSession(String id, String title);

  /// Removes the session called [id] and its tape.
  Future<Either<Failure, void>> deleteSession(String id);

  /// The signed-in user's sessions whose title or result text contains
  /// [query], newest first.
  Future<Either<Failure, List<CalculationSession>>> search(String query);

  /// Ends every watch handed out.
  void dispose();
}
