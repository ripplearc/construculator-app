// coverage:ignore-file
import 'dart:async';

import 'package:construculator/libraries/powersync/interfaces/powersync_manager.dart';
import 'package:powersync/powersync.dart';

/// [PowerSyncManager] for tests that counts connects and can fail or wait.
class FakePowerSyncManager implements PowerSyncManager {
  /// How many times [connect] was called.
  int connectCallCount = 0;

  /// When true, [connect] throws.
  bool shouldThrowOnConnect = false;

  /// When set, [connect] waits for it before it returns.
  Completer<void>? connectGate;

  @override
  PowerSyncDatabase get database =>
      throw UnsupportedError('FakePowerSyncManager has no database');

  @override
  Future<void> connect() async {
    connectCallCount++;
    await connectGate?.future;
    if (shouldThrowOnConnect) throw StateError('connect failed');
  }

  @override
  Future<void> disconnectAndClear() async {}

  @override
  Future<void> disconnectAndClearOrThrow() async {}
}
