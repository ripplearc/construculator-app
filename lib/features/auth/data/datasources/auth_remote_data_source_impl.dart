import 'package:construculator/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:construculator/features/auth/data/models/professional_role_model.dart';
import 'package:construculator/libraries/errors/exceptions.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:stack_trace/stack_trace.dart';

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final SupabaseWrapper supabaseWrapper;

  AuthRemoteDataSourceImpl({required this.supabaseWrapper});
  @override
  Future<List<ProfessionalRoleModel>> getProfessionalRoles() async {
    try {
      final rolesData = await supabaseWrapper.selectAll(
        'professional_roles',
        columns: 'id, name',
      );
      return rolesData
          .map((roleMap) => ProfessionalRoleModel.fromJson(roleMap))
          .toList();
    } catch (e, stackTrace) {
      throw ServerException(Trace.from(stackTrace), e);
    }
  }
}
