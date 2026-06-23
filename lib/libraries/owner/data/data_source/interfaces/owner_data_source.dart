import 'package:construculator/libraries/auth/data/models/user_profile_dto.dart';

/// Interface that abstracts remote project-owner data operations.
///
/// Implementations must rethrow all exceptions — error mapping is the
/// repository's responsibility.
abstract class OwnerDataSource {
  /// Returns the project owners the caller can filter project search by.
  ///
  /// Owners are users who created projects the authenticated caller can
  /// access; the backend scopes the result to those owners.
  Future<List<UserProfileDto>> fetchOwners();
}
