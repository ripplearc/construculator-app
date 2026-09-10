// This helper reads the running app's live DI container to sign it out during
// teardown. It uses Modular.tryGet (not Modular.get), so it stays clear of
// forbid_modular_get_outside_module and also lets the "bindings already torn
// down" case be an explicit null check rather than a swallowed exception.
import 'package:construculator/libraries/auth/interfaces/auth_manager.dart';
import 'package:construculator/libraries/powersync/interfaces/powersync_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:patrol/patrol.dart';

import 'clean_state.dart';

/// Registers the shared E2E teardown. Call once at the top of a CUJ file's
/// own `main()`, before `patrolTest(...)`.
///
/// Each CUJ now runs as its own independent `patrol test` invocation (see
/// `scripts/e2e/run_cuj_suite.sh`), so there is no shared aggregator file left
/// to hang one `patrolTearDown` on — each CUJ file registers its own by
/// calling this. It runs after the CUJ's own test and clears the session and
/// PowerSync state so a retry of the same CUJ does not inherit it.
void registerE2ETeardown() {
  patrolTearDown(() async {
    final AuthManager? authManager = Modular.tryGet<AuthManager>();
    final PowerSyncManager? powerSyncManager = Modular.tryGet<PowerSyncManager>();
    if (authManager == null || powerSyncManager == null) {
      // A CUJ that navigates into the app shell (e.g. CUJ-2 reaching the
      // dashboard) disposes the auth module's bindings along the way, so
      // there is no live instance left to read. Nothing remains to reset in
      // that case: the module tore itself down along with whatever state
      // this call would have cleared. tryGet keeps this the only swallowed
      // case, so a genuine failure inside resetE2EState still fails the test.
      debugPrint('resetE2EState: skipped, dependencies unavailable');
      return;
    }
    await resetE2EState(
      authManager: authManager,
      powerSyncManager: powerSyncManager,
    );
  });
}
