import 'package:construculator/libraries/auth/queue/auth_event_queue.dart';
import 'package:construculator/libraries/powersync/interfaces/powersync_manager.dart';
import 'package:construculator/libraries/session/interfaces/session_service.dart';
import 'package:construculator/libraries/storage/interfaces/owner_record_storage_service.dart';
import 'package:construculator/libraries/storage/local_data_delete_service.dart';
import 'package:construculator/libraries/storage/models/owner_record.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';

class _SessionSuperseded implements Exception {
  const _SessionSuperseded();
}

/// Decides whether the data on the phone belongs to the user who just signed
/// in, then adds the session module and connects PowerSync.
///
/// It runs inside a queue item, on every event that carries a session, and
/// compares the session's user with the owner record. Before each step that
/// changes something it confirms the run is still current and the event's user
/// is still the signed-in user.
class SignInCheck {
  final OwnerRecordStorageService _ownerRecords;
  final LocalDataDeleteService _deleteService;
  final SessionService _sessionService;
  final PowerSyncManager _powerSync;
  final SupabaseWrapper _wrapper;
  final Future<void> Function() _resetIdentity;

  String? _moduleUserId;
  bool _isConnected = false;

  /// [resetIdentity] clears the Sentry and analytics identity when another
  /// user was active.
  SignInCheck({
    required this._ownerRecords,
    required this._deleteService,
    required this._sessionService,
    required this._powerSync,
    required this._wrapper,
    required this._resetIdentity,
  });

  /// The user whose session module is added and connected, or null. It is null
  /// once the session ended or PowerSync was disconnected.
  String? get activeModuleUserId =>
      _sessionService.isActive && _isConnected ? _moduleUserId : null;

  /// Stops syncing and clears the synced data after a sign-out. The module stays.
  Future<void> clearAfterSignOut(QueueRun run) async {
    _isConnected = false;
    await run.step(_powerSync.disconnectAndClear);
  }

  /// Stops syncing at once, keeping the rows, for an event of another user.
  Future<void> stopSyncing() {
    _isConnected = false;
    return _powerSync.disconnectKeepingData();
  }

  /// Checks the session of [userId] during [run].
  ///
  /// [isFreshSignIn] is true when the user just signed in and false when the
  /// session was restored; it only matters when no owner record exists. Throws
  /// when a step fails or times out, with the module it added removed.
  Future<void> run(
    QueueRun run, {
    required String userId,
    required bool isFreshSignIn,
  }) async {
    try {
      await _check(run, userId, isFreshSignIn);
    } on _SessionSuperseded {
      return;
    }
  }

  Future<void> _check(QueueRun run, String userId, bool isFreshSignIn) async {
    if (!isFreshSignIn && activeModuleUserId == userId) return;
    var read = await run.step(_ownerRecords.read);
    if (activeModuleUserId == userId &&
        read is OwnerRecordFound &&
        read.record.userId == userId) {
      return;
    }
    final leftoverFlag = read is OwnerRecordFound
        ? read.record.pendingDelete
        : null;
    if (leftoverFlag != null) {
      await _finishLeftoverDelete(run, userId, leftoverFlag);
      read = await run.step(_ownerRecords.read);
    }
    switch (read) {
      case OwnerRecordUnknown():
        throw const OwnerRecordUnreadableException();
      case OwnerRecordFound(:final record) when record.userId == userId:
        await _continueSameUser(run, userId, record);
      case OwnerRecordAbsent() when !isFreshSignIn:
        await _signOutRestoredSession(run, userId);
      case _:
        await _takeOver(run, userId);
    }
  }

  bool _isOtherUserActive(String id) =>
      _moduleUserId != null && _moduleUserId != id;

  void _ensureCurrent(QueueRun run, String userId) {
    final isSameSession = _wrapper.currentSession?.user.id == userId;
    if (!run.isCurrent || !isSameSession) throw const _SessionSuperseded();
  }

  Future<void> _finishLeftoverDelete(
    QueueRun run,
    String userId,
    PendingDelete flag,
  ) async {
    _ensureCurrent(run, userId);
    final arrivalOfThisUser =
        flag.kind == PendingDeleteKind.arrivalOfNewUser &&
        flag.arrivingUserId == userId;
    await run.step(
      () => _deleteService.deleteLocalData(
        arrivingUserId: arrivalOfThisUser ? userId : null,
      ),
    );
  }

  Future<void> _continueSameUser(
    QueueRun run,
    String userId,
    OwnerRecord record,
  ) async {
    _ensureCurrent(run, userId);
    if (record.signOutDate != null) {
      await run.step(() => _ownerRecords.write(OwnerRecord(userId: userId)));
    }
    await _addModuleAndConnect(run, userId);
  }

  Future<void> _takeOver(QueueRun run, String userId) async {
    _ensureCurrent(run, userId);
    await run.step(
      () => _deleteService.deleteLocalData(arrivingUserId: userId),
    );
    _ensureCurrent(run, userId);
    if (_isOtherUserActive(userId)) await run.step(_resetIdentity);
    await _addModuleAndConnect(run, userId);
  }

  Future<void> _signOutRestoredSession(QueueRun run, String userId) async {
    _ensureCurrent(run, userId);
    await run.step(
      () => _ownerRecords.write(
        OwnerRecord(pendingDelete: const PendingDelete.logoutOrNoOwnerRecord()),
      ),
    );
    _ensureCurrent(run, userId);
    await run.step(_wrapper.signOut);
  }

  Future<void> _addModuleAndConnect(QueueRun run, String userId) async {
    _ensureCurrent(run, userId);
    if (_isOtherUserActive(userId)) _sessionService.endSession();
    _sessionService.startSession();
    _moduleUserId = userId;
    _isConnected = false;
    try {
      await run.step(_powerSync.connect);
      _isConnected = true;
    } catch (_) {
      _sessionService.endSession();
      _moduleUserId = null;
      rethrow;
    }
  }
}
