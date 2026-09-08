import 'package:construculator/libraries/either/interfaces/either.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/tag/domain/entities/tag_entity.dart';

/// Abstract repository interface for fetching tags.
///
/// Tags drive search and filter experiences (e.g. the Tags filter sheet in
/// global search). This contract decouples the domain layer from the
/// Supabase-backed data source implementation.
///
/// All methods return [Either] so that callers receive a typed [Failure] on
/// error rather than catching exceptions directly.
abstract class TagRepository {
  /// Fetches all available tags ordered alphabetically by name.
  ///
  /// Returns a [Future] that completes with an [Either] containing either
  /// a [Failure] or the full list of [Tag]s.
  Future<Either<Failure, List<Tag>>> getTags();
}
