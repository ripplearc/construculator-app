import 'package:construculator/libraries/auth/domain/entities/user_profile_entity.dart';
import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/owner/domain/repositories/owner_repository.dart';

/// Fake implementation of [OwnerRepository] for testing.
class FakeOwnerRepository implements OwnerRepository {
  // Tracks method calls for assertions.
  final List<Map<String, dynamic>> _methodCalls = [];

  // Owners returned by getOwners.
  final List<UserProfile> _owners = [];

  /// Controls whether [getOwners] returns a [Failure].
  bool shouldFailOnGetOwners = false;

  /// The failure returned when [shouldFailOnGetOwners] is true.
  Failure getOwnersFailure = UnexpectedFailure();

  /// Appends [owners] to the list returned by [getOwners].
  void addOwners(List<UserProfile> owners) {
    _owners.addAll(owners);
  }

  /// Restores the fake to its initial state: removes all seeded owners and
  /// recorded method calls, and resets the failure configuration.
  void reset() {
    _owners.clear();
    _methodCalls.clear();
    shouldFailOnGetOwners = false;
    getOwnersFailure = UnexpectedFailure();
  }

  /// Returns recorded calls for [methodName].
  List<Map<String, dynamic>> getMethodCallsFor(String methodName) {
    return _methodCalls
        .where((call) => call['method'] == methodName)
        .toList();
  }

  @override
  Future<Either<Failure, List<UserProfile>>> getOwners() async {
    _methodCalls.add({'method': 'getOwners'});
    if (shouldFailOnGetOwners) {
      return Left(getOwnersFailure);
    }
    return Right(List.unmodifiable(_owners));
  }
}
