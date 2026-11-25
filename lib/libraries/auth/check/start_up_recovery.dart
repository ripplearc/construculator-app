import 'package:construculator/libraries/auth/queue/auth_event_queue.dart';
import 'package:construculator/libraries/storage/interfaces/owner_record_storage_service.dart';
import 'package:construculator/libraries/storage/local_data_delete_service.dart';
import 'package:construculator/libraries/storage/models/owner_record.dart';
import 'package:construculator/libraries/supabase/data/saved_session_read.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';

/// Thrown when the saved session cannot be read, so recovery neither deletes
/// nor saves a sign-out date.
class SavedSessionUnreadableException implements Exception {
  /// An error for a read that returned [SavedSessionUnknown].
  const SavedSessionUnreadableException();

  @override
  String toString() =>
      'SavedSessionUnreadableException: the saved session could not be read';
}

/// Finishes what a crash stopped, at every app start, before any feature reads
/// data.
///
/// After a logout there is no session, so no auth event arrives and the
/// sign-in check never runs. Recovery reads the saved session through the
/// storage object Supabase uses and acts on the owner record. It runs inside a
/// queue item, and it never sets a finished value when a session is saved:
/// Supabase's own first event does.
class StartUpRecovery {
  final OwnerRecordStorageService _ownerRecords;
  final LocalDataDeleteService _deleteService;
  final SupabaseWrapper _wrapper;

  /// Recovery that reads [wrapper] and finishes deletes with [deleteService].
  StartUpRecovery({
    required this._ownerRecords,
    required this._deleteService,
    required this._wrapper,
  });

  /// Runs recovery during [run].
  ///
  /// Throws when the owner record or the saved session cannot be read, or when
  /// a step fails or times out; the flag then stays set for the next attempt.
  Future<void> run(QueueRun run) async {
    final pendingDelete = (await _readOwnerRecord(run))?.pendingDelete;
    if (pendingDelete == null) return;
    final saved = await _readSavedSession(run);
    if (_isLogoutWithSavedSession(pendingDelete, saved)) return;
    await run.step(
      () => _deleteService.deleteLocalData(
        arrivingUserId: _arrivingUserWithSavedSession(pendingDelete, saved),
      ),
    );
  }

  Future<OwnerRecord?> _readOwnerRecord(QueueRun run) async =>
      switch (await run.step(_ownerRecords.read)) {
        OwnerRecordFound(:final record) => record,
        OwnerRecordAbsent() => null,
        OwnerRecordUnknown() => throw const OwnerRecordUnreadableException(),
      };

  Future<SavedSessionRead> _readSavedSession(QueueRun run) async {
    final saved = await run.step(_wrapper.readSavedSession);
    if (saved is SavedSessionUnknown) {
      throw const SavedSessionUnreadableException();
    }
    return saved;
  }

  bool _isLogoutWithSavedSession(PendingDelete flag, SavedSessionRead saved) =>
      flag.kind == PendingDeleteKind.logoutOrNoOwnerRecord &&
      saved is SavedSessionFound;

  String? _arrivingUserWithSavedSession(
    PendingDelete flag,
    SavedSessionRead saved,
  ) {
    final arrivingUserId = flag.arrivingUserId;
    if (arrivingUserId == null || saved is! SavedSessionFound) return null;
    return saved.userId == arrivingUserId ? arrivingUserId : null;
  }
}
