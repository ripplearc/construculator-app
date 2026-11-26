import 'package:construculator/libraries/calculation/domain/repositories/calculation_session_repository.dart';
import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/failures.dart';

/// Takes a session out of the calculator's history again, which is what
/// Undo on the "Saved to history" card does behind the tape it brings back
/// (UX Design Doc walkthrough 13.2: "Undo rolls the history entry back as
/// well as restoring the tape").
class DeleteCalculationSessionUseCase {
  final CalculationSessionRepository _repository;

  /// Creates the use case over the repository that keeps the history.
  DeleteCalculationSessionUseCase({required this._repository});

  /// Removes the session called [sessionId] with its tape, answering the
  /// repository's [Failure] when it is gone already or the store refuses.
  Future<Either<Failure, void>> call(String sessionId) =>
      _repository.deleteSession(sessionId);
}
