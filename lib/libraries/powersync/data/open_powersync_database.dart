// coverage:ignore-file

import 'package:construculator/libraries/powersync/models/schema.dart';
import 'package:construculator/libraries/storage/database_file_path.dart';
import 'package:powersync/powersync.dart';

/// Opens (and migrates) the local PowerSync database.
///
/// This only sets up the on-device SQLite store — it does **not** start
/// syncing. The database is fully usable offline immediately; syncing with the
/// backend begins later when [PowerSyncDatabase.connect] is called with an
/// authenticated connector (see `PowerSyncManager`).
///
/// Opening is asynchronous because resolving the application support directory
/// touches the platform, so this must run during app bootstrap (before the
/// module graph is built) rather than inside a Modular `binds` callback.
Future<PowerSyncDatabase> openPowerSyncDatabase() async {
  final database = PowerSyncDatabase(
    schema: schema,
    path: await resolveDatabaseFilePath(),
  );
  await database.initialize();

  return database;
}
