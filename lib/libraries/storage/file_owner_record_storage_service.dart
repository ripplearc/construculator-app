import 'dart:convert';
import 'dart:io';

import 'package:construculator/libraries/logging/app_logger.dart';
import 'package:construculator/libraries/storage/interfaces/owner_record_storage_service.dart';
import 'package:construculator/libraries/storage/models/owner_record.dart';
import 'package:path/path.dart' as p;

/// [OwnerRecordStorageService] that keeps the record in one small file in the
/// app's own storage, not in secure storage, so deleting the app deletes it
/// with the data.
///
/// A write goes to a temporary file that is flushed to disk and then renamed
/// over the record, so an app crash leaves the old record or the new one. A
/// power cut can still lose the rename, which reads as no record when there
/// was no earlier one. A leftover temporary file is harmless: the next write
/// replaces it and a read ignores it.
///
/// Writes and removals run one after another, because they share one
/// temporary file.
///
/// A missing file reads as absent. Any other failure to read it, including the
/// app folder being unavailable, reads as unknown and never as absent, because
/// nothing is deleted on an unknown read.
class FileOwnerRecordStorageService implements OwnerRecordStorageService {
  static final _logger = AppLogger().tag('FileOwnerRecordStorageService');

  static const _recordFileName = 'owner_record.json';
  static const _temporaryFileName = 'owner_record.json.tmp';

  final Future<Directory> Function() _directory;

  Future<void> _lastChange = Future<void>.value();

  /// [directory] returns the folder in the app's own storage that holds the
  /// record.
  FileOwnerRecordStorageService({required this._directory});

  @override
  Future<OwnerRecordRead> read() async {
    try {
      final directory = await _directory();
      final file = File(p.join(directory.path, _recordFileName));
      final String contents;
      try {
        contents = await file.readAsString();
      } on PathNotFoundException {
        return const OwnerRecordAbsent();
      }
      final json = jsonDecode(contents);
      if (json is! Map<String, Object?>) {
        throw const FormatException('The owner record is not an object');
      }
      return OwnerRecordFound(OwnerRecord.fromJson(json));
    } on Exception catch (error, stackTrace) {
      _logger.error('Could not read the owner record', error, stackTrace);
      return const OwnerRecordUnknown();
    }
  }

  @override
  Future<void> write(OwnerRecord record) => _afterEarlierChanges(() async {
    final directory = await _directory();
    await directory.create(recursive: true);
    final temporary = File(p.join(directory.path, _temporaryFileName));
    final handle = await temporary.open(mode: FileMode.write);
    try {
      await handle.writeString(jsonEncode(record.toJson()));
      await handle.flush();
    } finally {
      await handle.close();
    }
    await temporary.rename(p.join(directory.path, _recordFileName));
  });

  @override
  Future<void> remove() => _afterEarlierChanges(() async {
    final directory = await _directory();
    for (final name in [_recordFileName, _temporaryFileName]) {
      try {
        await File(p.join(directory.path, name)).delete();
      } on PathNotFoundException {
        continue;
      }
    }
  });

  Future<void> _afterEarlierChanges(Future<void> Function() change) {
    final result = _lastChange.then((_) => change());
    _lastChange = result.then<void>((_) {}, onError: (_) {});
    return result;
  }
}
