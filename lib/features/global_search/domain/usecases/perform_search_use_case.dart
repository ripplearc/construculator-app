import 'package:construculator/features/global_search/domain/entities/search_params_entity.dart';
import 'package:construculator/features/global_search/domain/entities/search_results.dart';
import 'package:construculator/features/global_search/domain/repositories/global_search_repository.dart';
import 'package:construculator/libraries/either/interfaces/either.dart';
import 'package:construculator/libraries/errors/failures.dart';

/// Use case for executing a global search across projects, estimations, and members.
///
/// Delegates directly to [GlobalSearchRepository.search] and returns the
/// [Either] result without additional transformation, keeping business
/// orchestration at the repository boundary.
class PerformSearchUseCase {
  final GlobalSearchRepository _repository;

  PerformSearchUseCase(this._repository);

  /// Performs a global search using the supplied [params].
  ///
  /// Returns [Either] wrapping a [Failure] on error or [SearchResults] on success.
  Future<Either<Failure, SearchResults>> call(SearchParams params) {
    return _repository.search(params);
  }
}
