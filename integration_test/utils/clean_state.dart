import 'package:construculator/libraries/auth/interfaces/auth_manager.dart';
import 'package:construculator/libraries/powersync/interfaces/powersync_manager.dart';

/// Clears the app-side state that would otherwise leak into the next E2E
/// run: the persisted Supabase session and the local PowerSync database.
///
/// Delegates to the same [AuthManager.logout] the app calls on a real
/// sign-out, rather than reaching into secure storage or SQLite files
/// directly. [AuthManager.logout] only clears the session locally and fires
/// the `signedOut` Supabase event; the app's [PowerSyncManager] reacts to
/// that event by queuing its own clear internally (fire-and-forget). The
/// explicit [PowerSyncManager.disconnectAndClear] call below is what makes
/// the clear deterministic here: [PowerSyncManager] serializes its
/// operations, so awaiting this call waits for that queued clear to finish
/// first before running — now a no-op — itself.
///
/// Android already gets a full container wipe between test runs via
/// `clearPackageData` on the instrumentation runner (see
/// `android/app/build.gradle`). iOS has no OS-level equivalent — the
/// simulator keeps the app container between runs — so this in-test
/// teardown stands in for it there, and runs identically on both
/// platforms.
Future<void> resetE2EState({
  required AuthManager authManager,
  required PowerSyncManager powerSyncManager,
}) async {
  await authManager.logout();
  await powerSyncManager.disconnectAndClear();
}
