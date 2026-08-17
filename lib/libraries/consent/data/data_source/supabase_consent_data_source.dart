import 'package:construculator/libraries/consent/data/data_source/interfaces/remote_consent_data_source.dart';
import 'package:construculator/libraries/consent/data/models/consent_version_dto.dart';
import 'package:construculator/libraries/logging/app_logger.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';

/// Reads published consent versions directly from Supabase.
///
/// Deliberately bypasses any local replication. Verification exists to catch
/// the case where a version has been published but the device has not yet
/// received it, so reading through a cache would defeat the purpose.
class SupabaseConsentDataSource implements RemoteConsentDataSource {
  final SupabaseWrapper _supabaseWrapper;
  static final _logger = AppLogger().tag('SupabaseConsentDataSource');

  const SupabaseConsentDataSource({required this._supabaseWrapper});

  @override
  Future<List<ConsentVersionDto>> fetchPublishedVersions() async {
    try {
      // The view, not the versions table. The table keeps every version ever
      // published, so reading it would hand back several rows per consent type
      // and leave this class picking one — a decision that depends on
      // effective_from and belongs in the database, which owns it.
      final rows = await _supabaseWrapper.selectMatch(
        table: DatabaseConstants.currentConsentVersionsView,
        filters: const {},
      );

      // Unreadable rows are dropped, not fatal. A consent type this build does
      // not recognise means a newer server, and failing the whole batch over
      // it would block users on a row about a document that does not concern
      // them. Each drop is still a real data bug, so it goes to Sentry rather
      // than vanishing silently.
      final versions = <ConsentVersionDto>[];
      for (final row in rows) {
        try {
          versions.add(ConsentVersionDto.fromJson(row));
        } on FormatException catch (error, stackTrace) {
          _logger.error(
            'Dropping unreadable consent version row',
            error,
            stackTrace,
          );
        }
      }
      return versions;
    } catch (error, stackTrace) {
      _logger.error(
        'Error while fetching published consent versions',
        error,
        stackTrace,
      );
      rethrow;
    }
  }
}
