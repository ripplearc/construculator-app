/// Credentials and other fixtures shared by the E2E critical user journeys.
///
/// These are not secrets. They identify the account seeded into the local and
/// CI Supabase stacks by `construculator-backend`'s
/// `supabase/seeders/sample_data/103_users.sql`, which Supabase re-applies on
/// every `supabase db reset`. They must never be valid against a hosted
/// environment — see the E2E CUJ Strategy wiki page for the full invariant.
///
/// Each value can be overridden at build time with `--dart-define` so the same
/// suite can point at a differently seeded stack without a code change:
///
/// ```sh
/// patrol test --dart-define E2E_LOGIN_EMAIL=other@example.com
/// ```
class TestConfig {
  const TestConfig._();

  /// Email address of the seeded account used by CUJ-1 (login).
  static const String loginEmail = String.fromEnvironment(
    'E2E_LOGIN_EMAIL',
    defaultValue: 'seeder@example.com',
  );

  /// Password of the seeded account used by CUJ-1 (login).
  ///
  /// Must match the password `construculator-backend`'s
  /// `supabase/seeders/sample_data/100_auth_users.sql` sets on the GoTrue
  /// account backing `seeder@example.com` — **and** satisfy
  /// `AuthValidation.validatePassword` (8+ chars, upper, lower, number,
  /// special char from `!@#$&*~`), since the login form rejects the password
  /// client-side before ever calling the backend.
  ///
  /// The seeder currently sets `e2e-local-only-password`, which has no
  /// uppercase letter and no special character, so it fails validation and
  /// CUJ-1 can never reach the backend at all. This default (`Mypass@1`)
  /// satisfies the app's rules but does not match the seeded account until
  /// the seeder's password is changed to something that satisfies both.
  static const String loginPassword = String.fromEnvironment(
    'E2E_LOGIN_PASSWORD',
    defaultValue: 'Mypass@1',
  );

  /// Base URL of the Mailpit mail catcher started by `scripts/e2e/start_env.sh`
  /// (or the `e2e-env` GitHub Action in CI). `scripts/e2e/adb_reverse.sh`
  /// forwards this same port onto a connected Android device/emulator, so one
  /// URL works on host, device and iOS simulator alike.
  static const String mailpitUrl = String.fromEnvironment(
    'E2E_MAILPIT_URL',
    defaultValue: 'http://localhost:54324',
  );

  /// Password CUJ-2 (registration) sets on the account-details step. Not a
  /// secret — see [loginPassword].
  static const String registerPassword = String.fromEnvironment(
    'E2E_REGISTER_PASSWORD',
    defaultValue: 'Mypass@1',
  );

  /// Builds a new email for a single CUJ-2 (registration) run.
  ///
  /// Registration creates a real user against the backend, so the email must
  /// be unique per run: a fixed address would let a Mailpit search match a
  /// stale message from a previous run, and would collide with the account
  /// that run already registered.
  static String uniqueRegisterEmail() =>
      'cuj2-${DateTime.now().microsecondsSinceEpoch}@example.com';
}
