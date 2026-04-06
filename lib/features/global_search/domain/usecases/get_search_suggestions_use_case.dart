import 'package:construculator/features/global_search/domain/repositories/global_search_repository.dart';
import 'package:construculator/libraries/either/interfaces/either.dart';
import 'package:construculator/libraries/errors/failures.dart';

/// Use case for loading personalized search suggestions for the current user.
///
/// Delegates to [GlobalSearchRepository.getSearchSuggestions].
class GetSearchSuggestionsUseCase {
  final GlobalSearchRepository _repository;

  GetSearchSuggestionsUseCase(this._repository);

  /// Returns teammate- and history-based suggestion strings.
  Future<Either<Failure, List<String>>> call() {
    return _repository.getSearchSuggestions();
  }
}
