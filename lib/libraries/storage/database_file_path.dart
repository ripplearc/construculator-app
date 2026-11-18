import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

const _databaseFileName = 'construculator.db';

/// The path of the on-device database file, in the app's own storage.
///
/// [directory] returns the folder that holds the file; production uses the
/// application support folder.
Future<String> resolveDatabaseFilePath({
  Future<Directory> Function() directory = getApplicationSupportDirectory,
}) async => p.join((await directory()).path, _databaseFileName);
