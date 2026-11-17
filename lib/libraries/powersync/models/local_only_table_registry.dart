import 'package:construculator/libraries/powersync/interfaces/powersync_database_wrapper.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';

/// What happens to the rows of a local-only table when the user of the phone
/// changes.
enum LocalOnlyTablePolicy {
  /// The rows belong to one user, so the next user must not find them.
  clearWhenUserChanges,

  /// The rows are a setting of the phone and hold no user's data.
  keepAsDeviceSetting,
}

/// The policy chosen for one local-only table.
class LocalOnlyTableRegistration {
  /// Name of the `Table.localOnly` in the PowerSync schema.
  final String tableName;

  /// What happens to the rows of the table when the user changes.
  final LocalOnlyTablePolicy policy;

  /// Creates the registration of the table called [tableName].
  const LocalOnlyTableRegistration({
    required this.tableName,
    required this.policy,
  });

  /// Deletes every row of the table when its policy is
  /// [LocalOnlyTablePolicy.clearWhenUserChanges] and does nothing when it is
  /// [LocalOnlyTablePolicy.keepAsDeviceSetting].
  ///
  /// Throws an exception if the delete fails.
  Future<void> clearForUserChange(PowerSyncDatabaseWrapper database) async {
    if (policy == LocalOnlyTablePolicy.keepAsDeviceSetting) return;
    await database.execute('DELETE FROM $tableName');
  }
}

/// Every `Table.localOnly` of the PowerSync schema with what happens to its
/// rows when the user changes.
///
/// The app clears PowerSync with `clearLocal: false`, which leaves local-only
/// tables alone, so a table that is not listed here may keep one user's rows
/// for the next user. A test fails when a local-only table of the schema is
/// missing from [registrations]. A new local-only table adds its entry here in
/// the same change.
abstract final class LocalOnlyTableRegistry {
  /// The registered local-only tables.
  static const registrations = <LocalOnlyTableRegistration>[
    LocalOnlyTableRegistration(
      tableName: DatabaseConstants.currentCompanyTable,
      policy: LocalOnlyTablePolicy.clearWhenUserChanges,
    ),
    LocalOnlyTableRegistration(
      tableName: DatabaseConstants.yourRateRefusalsTable,
      policy: LocalOnlyTablePolicy.clearWhenUserChanges,
    ),
  ];
}
