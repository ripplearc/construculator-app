/// Represents a user credential in the application
class UserCredential {
  /// The unique identifier for the credential
  final String id;

  /// The email of the user
  final String email;

  /// The metadata for the credential
  final Map<String, dynamic> metadata;

  /// The date and time the credential was created
  final DateTime createdAt;
  
  UserCredential({
    required this.id,
    required this.email,
    required this.metadata,
    required this.createdAt,
  });
  /// Used to create an empty credential
  factory UserCredential.empty() {
    return UserCredential(
      id: '',
      email: '',
      metadata: {},
      createdAt: DateTime.now(),
    );
  }
}