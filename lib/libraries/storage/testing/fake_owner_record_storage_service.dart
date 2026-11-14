// coverage:ignore-file
import 'package:construculator/libraries/storage/interfaces/owner_record_storage_service.dart';
import 'package:construculator/libraries/storage/models/owner_record.dart';

/// In-memory [OwnerRecordStorageService] for tests, with switches to make the
/// read unknown or the write and removal fail.
class FakeOwnerRecordStorageService implements OwnerRecordStorageService {
  OwnerRecordRead _current = const OwnerRecordAbsent();

  /// When true, [read] returns [OwnerRecordUnknown].
  bool shouldReadUnknown = false;

  /// When true, [write] throws.
  bool shouldThrowOnWrite = false;

  /// When true, [remove] throws.
  bool shouldThrowOnRemove = false;

  /// Every record passed to a successful [write], in order.
  final List<OwnerRecord> writes = [];

  /// The record held now, or null when there is none.
  OwnerRecord? get record => switch (_current) {
    OwnerRecordFound(:final record) => record,
    _ => null,
  };

  /// Puts [record] in place without going through [write].
  void seed(OwnerRecord record) => _current = OwnerRecordFound(record);

  /// Clears the record, the recorded writes and the failure switches.
  void reset() {
    _current = const OwnerRecordAbsent();
    shouldReadUnknown = false;
    shouldThrowOnWrite = false;
    shouldThrowOnRemove = false;
    writes.clear();
  }

  @override
  Future<OwnerRecordRead> read() async =>
      shouldReadUnknown ? const OwnerRecordUnknown() : _current;

  @override
  Future<void> write(OwnerRecord record) async {
    if (shouldThrowOnWrite) throw StateError('write failed');
    _current = OwnerRecordFound(record);
    writes.add(record);
  }

  @override
  Future<void> remove() async {
    if (shouldThrowOnRemove) throw StateError('remove failed');
    _current = const OwnerRecordAbsent();
  }
}
