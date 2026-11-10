import 'package:construculator/libraries/storage/models/owner_record.dart';

/// What a read of the owner record found.
sealed class OwnerRecordRead {
  const OwnerRecordRead();
}

/// The record was read.
final class OwnerRecordFound extends OwnerRecordRead {
  /// The record that was read.
  final OwnerRecord record;

  /// A read that found [record].
  const OwnerRecordFound(this.record);
}

/// No record exists, so nobody is known to own the data on the phone.
final class OwnerRecordAbsent extends OwnerRecordRead {
  /// A read that found no record.
  const OwnerRecordAbsent();
}

/// The read failed or the record is corrupt.
///
/// This is not the same as [OwnerRecordAbsent]: nothing may be deleted on an
/// unknown read.
final class OwnerRecordUnknown extends OwnerRecordRead {
  /// A read that could not tell.
  const OwnerRecordUnknown();
}

/// The reserved part of the storage library, which holds only the owner
/// record.
abstract class OwnerRecordStorageService {
  /// Reads the owner record.
  ///
  /// Never throws: a failed or corrupt read returns [OwnerRecordUnknown].
  Future<OwnerRecordRead> read();

  /// Replaces the owner record with [record] in one write, so a crash leaves
  /// either the old record or the new one.
  ///
  /// Throws an exception if the write fails.
  Future<void> write(OwnerRecord record);

  /// Removes the owner record, so the next [read] returns [OwnerRecordAbsent].
  ///
  /// Throws an exception if the removal fails.
  Future<void> remove();
}
