
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