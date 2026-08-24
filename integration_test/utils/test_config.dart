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
  /// The seeder creates the `public.users` row but not the matching
  /// Supabase Auth identity, so this password must currently be set by hand
  /// when linking the account. Tracked as a Phase 1 gap in the strategy doc.
  static const String loginPassword = String.fromEnvironment(
    'E2E_LOGIN_PASSWORD',
    defaultValue: 'Mypass@1',
  );
}
