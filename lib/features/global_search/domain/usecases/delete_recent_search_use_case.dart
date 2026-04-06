import 'package:construculator/features/global_search/domain/entities/search_scope_entity.dart';
import 'package:construculator/features/global_search/domain/repositories/global_search_repository.dart';
import 'package:construculator/libraries/either/interfaces/either.dart';
import 'package:construculator/libraries/errors/failures.dart';

/// Use case for removing a search term from the user's recent search history.
///
/// Delegates to [GlobalSearchRepository.deleteRecentSearch].
class DeleteRecentSearchUseCase {
  final GlobalSearchRepository _repository;

  DeleteRecentSearchUseCase(this._repository);

  /// Removes [searchTerm] from history for the given [scope].
  Future<Either<Failure, void>> call(
    String searchTerm,
    SearchScope scope,
  ) {
    return _repository.deleteRecentSearch(searchTerm, scope);
  }
}
