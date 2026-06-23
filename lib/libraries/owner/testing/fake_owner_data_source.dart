import 'package:construculator/libraries/auth/data/models/user_profile_dto.dart';
import 'package:construculator/libraries/owner/data/data_source/interfaces/owner_data_source.dart';

/// Fake implementation of [OwnerDataSource] for testing.
///
/// Mirrors the real data source contract: it rethrows configured exceptions
/// instead of mapping them, leaving error handling to the repository.
class FakeOwnerDataSource implements OwnerDataSource {
  final List<Map<String, dynamic>> _methodCalls = [];

  final List<UserProfileDto> _owners = [];

  /// Controls whether [fetchOwners] throws instead of returning owners.
  bool shouldThrowOnFetchOwners = false;

  /// The exception thrown when [shouldThrowOnFetchOwners] is true.
  Object fetchOwnersException = Exception('FakeOwnerDataSource error');

  /// Appends [owners] to the list returned by [fetchOwners].
  void addOwners(List<UserProfileDto> owners) {
    _owners.addAll(owners);
  }

  /// Restores the fake to its initial state: removes all seeded owners and
  /// recorded method calls, and resets the throw configuration.
  void reset() {
    _owners.clear();
    _methodCalls.clear();
    shouldThrowOnFetchOwners = false;
    fetchOwnersException = Exception('FakeOwnerDataSource error');
  }

  /// Returns recorded calls for [methodName].
  List<Map<String, dynamic>> getMethodCallsFor(String methodName) {
    return _methodCalls
        .where((call) => call['method'] == methodName)
        .toList();
  }

  @override
  Future<List<UserProfileDto>> fetchOwners() async {
    _methodCalls.add({'method': 'fetchOwners'});
    if (shouldThrowOnFetchOwners) {
      throw fetchOwnersException;
    }
    return List.unmodifiable(_owners);
  }
}
