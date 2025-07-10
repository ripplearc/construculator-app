import 'package:construculator/features/auth/data/models/professional_role_model.dart';

/// Defines the contract for authentication operations with a remote source (e.g., API, Supabase).
abstract class AuthRemoteDataSource {
  /// Gets a list of all professional roles.
  /// 
  /// Returns:
  ///   A list of [ProfessionalRoleModel] objects representing the professional roles.
  /// 
  /// Throws:
  ///   [ServerException] if an error occurs while fetching the professional roles.
  Future<List<ProfessionalRoleModel>> getProfessionalRoles();
}