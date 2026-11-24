// coverage:ignore-file
import 'dart:async';

import 'package:construculator/libraries/powersync/interfaces/powersync_manager.dart';
import 'package:powersync/powersync.dart';

/// [PowerSyncManager] for tests that counts connects and can fail or wait.
class FakePowerSyncManager implements PowerSyncManager {
  /// How many times [connect] was called.
  int connectCallCount = 0;

  /// How many times [disconnectAndClear] was called.
  int clearCallCount = 0;

  /// When true, [connect] throws.
  bool shouldThrowOnConnect = false;

  /// When set, [connect] waits for it before it returns.
  Completer<void>? connectGate;

  /// Called when [connect] starts, before it waits or fails.
  void Function()? onConnect;

  @override
  PowerSyncDatabase get database =>
      throw UnsupportedError('FakePowerSyncManager has no database');

  @override
  Future<void> connect() async {
    connectCallCount++;
    onConnect?.call();
    await connectGate?.future;
    if (shouldThrowOnConnect) throw StateError('connect failed');
  }

  /// How many times [disconnectKeepingData] was called.
  int disconnectKeepingDataCallCount = 0;

  /// When true, [disconnectKeepingData] throws.
  bool shouldThrowOnDisconnect = false;

  @override
  Future<void> disconnectKeepingData() async {
    disconnectKeepingDataCallCount++;
    if (shouldThrowOnDisconnect) throw StateError('disconnect failed');
  }

  @override
  Future<void> disconnectAndClear() async => clearCallCount++;

  @override
  Future<void> disconnectAndClearOrThrow() async {}
}
