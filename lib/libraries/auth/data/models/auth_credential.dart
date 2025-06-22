import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_credential.freezed.dart';
part 'auth_credential.g.dart';

/// Represents a user credential in the application
@freezed
sealed class UserCredential with _$UserCredential {
  /// Allows the definition of custom methods like [empty]
  const UserCredential._();

  /// Creates a new [UserCredential] instance
  ///
  /// - [id]: The unique identifier for the credential
  /// - [email]: The email of the user
  /// - [metadata]: The metadata for the credential
  /// - [createdAt]: The date and time the credential was created
  const factory UserCredential({
    required String id,
    required String email,
    required Map<String, dynamic> metadata,
    required DateTime createdAt,
  }) = _UserCredential;

  /// Creates a [UserCredential] from a JSON object
  factory UserCredential.fromJson(Map<String, dynamic> json) =>
      _$UserCredentialFromJson(json);

  /// Used to create an empty credential
  static UserCredential empty() => UserCredential(
    id: '',
    email: '',
    metadata: {},
    createdAt: DateTime.now(),
  );
}
