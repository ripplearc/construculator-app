import 'package:construculator/libraries/consent/data/data_source/interfaces/remote_consent_data_source.dart';
import 'package:construculator/libraries/consent/data/models/consent_version_dto.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';

/// Reads published consent versions directly from Supabase.
///
/// Deliberately bypasses any local replication. Verification exists to catch
/// the case where a version has been published but the device has not yet
/// received it, so reading through a cache would defeat the purpose.
class RemoteConsentDataSourceImpl implements RemoteConsentDataSource {
  final SupabaseWrapper _supabaseWrapper;

  const RemoteConsentDataSourceImpl({required this._supabaseWrapper});

  @override
  Future<List<ConsentVersionDto>> fetchPublishedVersions() async {
    // The view, not the versions table. The table keeps every version ever
    // published, so reading it would hand back several rows per consent type
    // and leave this class picking one — a decision that depends on
    // effective_from and belongs in the database, which owns it.
    final rows = await _supabaseWrapper.selectMatch(
      table: DatabaseConstants.currentConsentVersionsView,
      filters: const {},
    );

    // Unreadable rows are dropped, not fatal. A consent type this build does
    // not recognise means a newer server, and failing the whole batch over it
    // would block users on a row about a document that does not concern them.
    return rows.map(ConsentVersionDto.tryFromJson).nonNulls.toList();
  }
}
