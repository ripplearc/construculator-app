import 'package:construculator/libraries/auth/interfaces/auth_manager.dart';
import 'package:construculator/libraries/powersync/interfaces/powersync_manager.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:patrol/patrol.dart';

import 'features/auth/cuj_1_login_test.dart' as cuj1;
import 'features/auth/cuj_2_registration_test.dart' as cuj2;
import 'utils/clean_state.dart';

/// The single entry point `.github/workflows/e2e_cuj.yml` invokes via
/// `patrol test --target integration_test/patrol_test.dart`.
///
/// To add a new CUJ: write it under `integration_test/features/<domain>/`
/// following the selector convention in `docs/Testing/E2E-CUJ-Strategy.md`,
/// then import and call it here — nothing else changes for it to run weekly
/// and under `#RunE2E`. See `docs/Testing/E2E-CI.md` for the full pattern.
///
/// To quarantine a flaky or known-broken CUJ without deleting it, comment out
/// its line here with `// QUARANTINED: <reason> — <ticket>` (see
/// `docs/Testing/E2E-CI.md#quarantine`).
void main() {
  // Runs after every CUJ test registered below, clearing session and
  // PowerSync state so neither the next test in this run nor the next full
  // suite invocation inherits it. A new CUJ file needs nothing beyond
  // importing and calling its `main()` here to get this for free.
  patrolTearDown(
    () => resetE2EState(
      authManager: Modular.get<AuthManager>(),
      powerSyncManager: Modular.get<PowerSyncManager>(),
    ),
  );

  cuj1.main();
  cuj2.main();
}
