import 'package:construculator/libraries/consent/data/data_source/interfaces/remote_consent_data_source.dart';
import 'package:construculator/libraries/consent/data/models/consent_version_dto.dart';
import 'package:construculator/libraries/consent/data/models/consent_wire_values.dart';
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

      // An unrecognised type means a newer server, not a corrupt row: this
      // build cannot gate on a document it does not know about, so skipping
      // is safe. Anything else unreadable is a row we DO gate on — let it
      // throw so the repository resolves to a status that blocks, rather
      // than silently dropping a requirement the user never satisfied.
      final versions = <ConsentVersionDto>[];
      for (final row in rows) {
        final rawConsentType = row[DatabaseConstants.consentTypeColumn];
        // Only a value this build has no gate for is skipped. A missing,
        // null, empty or non-String column is a corrupt row rather than a
        // newer server, so it falls through to fromJson and throws like any
        // other unreadable gate field.
        if (ConsentTypeWireValue.isUnrecognisedWireValue(rawConsentType)) {
          // Named, because the log is the only way to tell a genuinely new
          // document from a gated type whose wire value the server renamed.
          _logger.warning('Skipping unrecognised consent type: $rawConsentType');
          continue;
        }
        versions.add(ConsentVersionDto.fromJson(row));
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
