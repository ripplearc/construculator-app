import 'package:construculator/features/global_search/domain/entities/search_scope_entity.dart';
import 'package:construculator/features/global_search/domain/repositories/global_search_repository.dart';
import 'package:construculator/libraries/either/interfaces/either.dart';
import 'package:construculator/libraries/errors/failures.dart';

/// Use case for retrieving the authenticated user's recent search terms.
///
/// Delegates to [GlobalSearchRepository.getRecentSearches] and returns
/// the [Either] result for the given [SearchScope].
class GetRecentSearchesUseCase {
  final GlobalSearchRepository _repository;

  GetRecentSearchesUseCase(this._repository);

  /// Fetches recent search terms for the given [scope].
  ///
  /// Returns [Either] wrapping a [Failure] on error or a [List<String>]
  /// ordered by most recent first.
  Future<Either<Failure, List<String>>> call(SearchScope scope) {
    return _repository.getRecentSearches(scope);
  }
}
