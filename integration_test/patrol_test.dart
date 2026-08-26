import 'features/auth/cuj_1_login_test.dart' as cuj1;
import 'features/auth/cuj_2_registration_test.dart' as cuj2;

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
  cuj1.main();
  cuj2.main();
}
