import 'package:construculator/libraries/auth/domain/entities/user_profile_entity.dart';
import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/failures.dart';

/// Contract for fetching the project owners a user can filter project search by.
abstract class OwnerRepository {
  /// Fetches the owners (project creators) the caller can filter by.
  ///
  /// Returns a [Right] with the owners as [UserProfile]s, or a [Left]
  /// [Failure] when the operation fails. Never throws.
  Future<Either<Failure, List<UserProfile>>> getOwners();
}
