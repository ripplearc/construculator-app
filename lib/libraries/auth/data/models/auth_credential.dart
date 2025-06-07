/// Represents a user credential in the application
///
/// [id] is the unique identifier for the credential
/// [email] is the email of the user
/// [metadata] is a map of metadata for the credential
/// [createdAt] is the date and time the credential was created
///
/// [empty] is a method to create an empty credential
class UserCredential {
  final String id;
  final String email;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  
  UserCredential({
    required this.id,
    required this.email,
    required this.metadata,
    required this.createdAt,
  });
  
  factory UserCredential.empty() {
    return UserCredential(
      id: '',
      email: '',
      metadata: {},
      createdAt: DateTime.now(),
    );
  }
}