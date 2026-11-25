import 'package:construculator/libraries/auth/queue/auth_event_queue.dart';
import 'package:construculator/libraries/errors/expected_exception.dart';
import 'package:construculator/libraries/logging/app_logger.dart';
import 'package:construculator/libraries/storage/interfaces/owner_record_storage_service.dart';
import 'package:construculator/libraries/storage/local_data_delete_service.dart';
import 'package:construculator/libraries/storage/models/owner_record.dart';
import 'package:construculator/libraries/supabase/data/saved_session_read.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:construculator/libraries/time/interfaces/clock.dart';

/// Thrown when the saved session cannot be read, so recovery neither deletes
/// nor saves a sign-out date.
class SavedSessionUnreadableException implements ExpectedException {
  /// An error for a read that returned [SavedSessionUnknown].
  const SavedSessionUnreadableException();

  @override
  String toString() =>
      'SavedSessionUnreadableException: the saved session could not be read';
}

/// Thrown when the saved session reads fine but Supabase sent a first event
/// with no session. That is a temporary failure: nobody is signed out.
class SavedSessionNotLoadedException implements ExpectedException {
  /// An error for a readable saved session that Supabase did not load.
  const SavedSessionNotLoadedException();

  @override
  String toString() =>
      'SavedSessionNotLoadedException: a readable saved session was not loaded';
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
  final Clock _clock;
  final Duration _removalPollInterval;
  final _logger = AppLogger().tag('StartUpRecovery');
  bool _didSignOut = false;

  /// Recovery that reads [wrapper] and finishes deletes with [deleteService].
  /// [clock] gives the sign-out date it saves.
  ///
  /// After its own sign-out it asks [wrapper] at a fixed interval (50 ms by
  /// default) whether Supabase has removed the saved session yet.
  StartUpRecovery({
    required this._ownerRecords,
    required this._deleteService,
    required this._wrapper,
    required this._clock,
    this._removalPollInterval = const Duration(milliseconds: 50),
  });

  /// Runs recovery during [run].
  ///
  /// A logout flag with a saved session that is the current session is signed
  /// out only when [isFirstAttempt] is true. A retry never signs out, because
  /// the saved session may belong to someone who signed in since: it only
  /// finishes the delete, and finishes it after this object's own sign-out
  /// when that sign-out left the saved session behind. A saved value that is
  /// not a session counts as no session for the flag.
  ///
  /// Supabase ends the session in memory before its sign-out call reaches the
  /// server. So a sign-out error with no session left is an offline sign-out
  /// that still ended the session: recovery logs a warning and finishes the
  /// delete, and rethrows any error while a session is still current.
  ///
  /// Throws when the owner record or the saved session cannot be read, or when
  /// a step fails or times out; the flag then stays set for the next attempt.
  Future<void> run(QueueRun run, {bool isFirstAttempt = true}) async {
    final record = await _readOwnerRecord(run);
    if (record == null) return;
    final saved = await _readSavedSession(run);
    final pendingDelete = record.pendingDelete;
    if (pendingDelete == null) {
      await _saveMissingSignOutDate(run, record, saved);
      return;
    }
    if (_isLogoutWithSavedSession(pendingDelete, saved)) {
      await _signOutThenDelete(
        run,
        saved as SavedSessionFound,
        isFirstAttempt: isFirstAttempt,
      );
      return;
    }
    await run.step(
      () => _deleteService.deleteLocalData(
        arrivingUserId: _arrivingUserWithSavedSession(pendingDelete, saved),
      ),
    );
  }

  /// Handles Supabase's first event when it carries no session.
  ///
  /// A saved value that cannot be read as a session is removed, and the
  /// sign-out date is saved so the kept-data limit can start. Nothing is
  /// signed out and no auth event follows, because no session exists in
  /// memory. Returns whether it removed such a value; it removes nothing when a
  /// session has been current since the read, because a fresh sign-in may have
  /// saved over the value. Throws
  /// [SavedSessionNotLoadedException] when the value reads fine, and
  /// [SavedSessionUnreadableException] when the read fails: both are temporary
  /// failures that remove and save nothing.
  Future<bool> removeUnreadableSavedSession(QueueRun run) async {
    switch (await _readSavedSession(run)) {
      case SavedSessionFound(isReadableSession: true):
        throw const SavedSessionNotLoadedException();
      case SavedSessionFound():
        if (_wrapper.currentSession != null) return false;
        // TODO: [CA-1462] Replace this direct removal with a sign-out tagged
        // "keep" once the sign-out handler exists.
        // https://ripplearc.youtrack.cloud/issue/CA-1462
        await run.step(_wrapper.removeSavedSession);
        final record = await _readOwnerRecord(run);
        if (record != null) {
          await _saveMissingSignOutDate(
            run,
            record,
            const SavedSessionAbsent(),
          );
        }
        return true;
      case _:
        return false;
    }
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

  Future<void> _saveMissingSignOutDate(
    QueueRun run,
    OwnerRecord record,
    SavedSessionRead saved,
  ) async {
    if (saved is! SavedSessionAbsent ||
        record.pendingDelete != null ||
        record.signOutDate != null) {
      return;
    }
    await run.step(
      () => _ownerRecords.write(
        OwnerRecord(userId: record.userId, signOutDate: _clock.now()),
      ),
    );
  }

  Future<void> _signOutThenDelete(
    QueueRun run,
    SavedSessionFound saved, {
    required bool isFirstAttempt,
  }) async {
    final currentToken = _wrapper.currentSession?.accessToken;
    final isLeftoverOfOwnSignOut = _didSignOut && currentToken == null;
    if (isFirstAttempt && currentToken != null) {
      // TODO: [CA-1496] Skip the sign-out once a link attempt has started,
      // because a sign-out deletes the code verifier the link needs.
      // https://ripplearc.youtrack.cloud/issue/CA-1496
      if (currentToken != saved.accessToken) return;
      await _signOut(run);
    } else if (!isLeftoverOfOwnSignOut) {
      return;
    }
    await run.step(() => _untilSavedSessionRemoved(run));
    // TODO: [CA-1462] Let the sign-out handler run this delete inside the same
    // queue item, so the delete runs once and the counts are added once.
    // https://ripplearc.youtrack.cloud/issue/CA-1462
    await run.step(_deleteService.deleteLocalData);
  }

  Future<void> _signOut(QueueRun run) async {
    _didSignOut = true;
    try {
      await run.step(_wrapper.signOut);
    } on QueueTimeoutException {
      rethrow;
    } on Object catch (error) {
      if (_wrapper.currentSession != null) rethrow;
      _logger.warning(
        'Sign-out call failed after the session ended',
        error.runtimeType,
      );
    }
  }

  Future<void> _untilSavedSessionRemoved(QueueRun run) async {
    while (run.isCurrent) {
      final saved = await _wrapper.readSavedSession();
      if (saved is SavedSessionUnknown) {
        throw const SavedSessionUnreadableException();
      }
      if (saved is SavedSessionAbsent) return;
      await Future<void>.delayed(_removalPollInterval);
    }
  }

  bool _isLogoutWithSavedSession(PendingDelete flag, SavedSessionRead saved) =>
      flag.kind == PendingDeleteKind.logoutOrNoOwnerRecord &&
      saved is SavedSessionFound &&
      saved.isReadableSession;

  String? _arrivingUserWithSavedSession(
    PendingDelete flag,
    SavedSessionRead saved,
  ) {
    final arrivingUserId = flag.arrivingUserId;
    if (arrivingUserId == null || saved is! SavedSessionFound) return null;
    return saved.userId == arrivingUserId ? arrivingUserId : null;
  }
}
