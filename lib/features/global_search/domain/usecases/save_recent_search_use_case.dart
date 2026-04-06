import 'package:construculator/features/global_search/domain/entities/search_scope_entity.dart';
import 'package:construculator/features/global_search/domain/repositories/global_search_repository.dart';
import 'package:construculator/libraries/either/interfaces/either.dart';
import 'package:construculator/libraries/errors/failures.dart';

/// Use case for persisting a search term to the user's search history
class SaveRecentSearchUseCase {
  final GlobalSearchRepository _repository;

  SaveRecentSearchUseCase(this._repository);

  /// Saves [searchTerm] to the user's history under [scope].
  ///
  /// [hasResults] should be `true` when the search returned at least one result.
  /// [projectId] scopes the record to a project when provided.
  Future<Either<Failure, void>> call(
    String searchTerm,
    SearchScope scope, {
    bool hasResults = false,
    String? projectId,
  }) {
    return _repository.saveRecentSearch(
      searchTerm,
      scope,
      hasResults: hasResults,
      projectId: projectId,
    );
  }
}
