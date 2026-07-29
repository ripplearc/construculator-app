import 'package:construculator/libraries/project/data/data_source/interfaces/permission_data_source.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';

/// JWT-backed implementation of [ProjectPermissionDataSource].
///
/// Reads project permissions from the claims embedded in the current
/// Supabase auth session's JWT — no network calls, no on-device persistence.
class LocalJwtProjectPermissionDataSource
    implements ProjectPermissionDataSource {
  final SupabaseWrapper _supabaseWrapper;

  LocalJwtProjectPermissionDataSource({
    required SupabaseWrapper supabaseWrapper,
  }) : _supabaseWrapper = supabaseWrapper;

  @override
  List<String> getProjectPermissions(String projectId) {
    return _supabaseWrapper.getProjectPermissions(projectId);
  }

  @override
  bool hasProjectPermission(String projectId, String permissionKey) {
    return _supabaseWrapper.hasProjectPermission(projectId, permissionKey);
  }
}
