import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/tag/domain/entities/tag_entity.dart';
import 'package:construculator/libraries/tag/domain/repositories/tag_repository.dart';

/// Fake implementation of [TagRepository] for testing.
class FakeTagRepository implements TagRepository {
  // Tracks method calls for assertions.
  final List<Map<String, dynamic>> _methodCalls = [];

  // Tags returned by getTags.
  final List<Tag> _tags = [];

  /// Controls whether [getTags] returns a [Failure].
  bool shouldFailOnGetTags = false;

  /// The failure returned when [shouldFailOnGetTags] is true.
  Failure getTagsFailure = UnexpectedFailure();

  /// Appends [tags] to the list returned by [getTags].
  void addTags(List<Tag> tags) {
    _tags.addAll(tags);
  }

  /// Restores the fake to its initial state: removes all seeded tags and
  /// recorded method calls, and resets the failure configuration.
  void reset() {
    _tags.clear();
    _methodCalls.clear();
    shouldFailOnGetTags = false;
    getTagsFailure = UnexpectedFailure();
  }

  /// Returns recorded calls for [methodName].
  List<Map<String, dynamic>> getMethodCallsFor(String methodName) {
    return _methodCalls
        .where((call) => call['method'] == methodName)
        .toList();
  }

  @override
  Future<Either<Failure, List<Tag>>> getTags() async {
    _methodCalls.add({'method': 'getTags'});
    if (shouldFailOnGetTags) {
      return Left(getTagsFailure);
    }
    return Right(List.unmodifiable(_tags));
  }
}
