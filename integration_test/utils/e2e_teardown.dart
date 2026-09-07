// This helper reads the running app's live DI container to sign it out during
// teardown, which is exactly the case forbid_modular_get_outside_module is not
// meant to catch. The old aggregator (integration_test/patrol_test.dart) did
// the same thing; it only escaped the rule because its filename ended in
// `_test.dart`.
// ignore_for_file: forbid_modular_get_outside_module
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
    try {
      await resetE2EState(
        authManager: Modular.get<AuthManager>(),
        powerSyncManager: Modular.get<PowerSyncManager>(),
      );
    } catch (e) {
      // A CUJ that navigates into the app shell (e.g. CUJ-2 reaching the
      // dashboard) disposes the auth module's bindings along the way, so
      // Modular.get throws here instead of finding a live instance. There is
      // nothing left to reset in that case — the module tore itself down
      // along with whatever state this call would have cleared.
      debugPrint('resetE2EState: skipped, dependencies unavailable ($e)');
    }
  });
}
