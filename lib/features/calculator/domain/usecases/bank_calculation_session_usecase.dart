import 'package:construculator/libraries/calculation/domain/entities/calculation_session.dart';
import 'package:construculator/libraries/calculation/domain/repositories/calculation_session_repository.dart';
import 'package:construculator/libraries/calculator_engine/tape.dart';
import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/failures.dart';

/// Banks a tape as a session in the calculator's history on this phone
/// (UX Design Doc rule 4.9, term 2.19: "Nothing is ever lost and nothing has
/// to be saved by hand"). The whole tape goes as typed, operators and
/// brackets included, so a session restored later is the tape that was
/// banked (rule 4.13).
class BankCalculationSessionUseCase {
  final CalculationSessionRepository _repository;

  /// Creates the use case over the repository that keeps the history.
  BankCalculationSessionUseCase({required this._repository});

  /// Banks [tape], answering the session it became or the repository's
  /// [Failure].
  Future<Either<Failure, CalculationSession>> call(Tape tape) =>
      _repository.bankSession(tape);
}
