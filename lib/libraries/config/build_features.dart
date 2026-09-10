/// Compile-time feature composition, resolved by the AOT compiler.
///
/// Every flag here must stay a top-level/static `const bool` fed by
/// `bool.fromEnvironment`. That is what lets the compiler const-fold the
/// condition and tree-shake the dead branch, the same mechanism `kDebugMode`
/// relies on (`flutter/lib/src/foundation/constants.dart`). An instance
/// getter or any other runtime-computed value keeps both branches in the
/// compiled output.
///
/// Values are supplied per flavor via `--dart-define-from-file=config/flavors/<flavor>.json`
/// (see `codemagic.yaml` and `scripts/run_check.sh`). `defaultValue: true`
/// is deliberate: a bare `flutter run` or `flutter test`, with no manifest
/// passed, compiles the complete module graph.
///
/// This is unrelated to the runtime, PostHog-backed flag system
/// (`FeatureFlagRepository` / `FeatureFlagModule` in
/// `lib/libraries/analytics/`) — that system decides behavior at runtime
/// per user/cohort; this one decides what gets compiled in at all.
abstract final class BuildFeatures {
  /// True unless a flavor manifest sets `ENABLE_CALCULATOR: false`.
  static const bool calculator = bool.fromEnvironment(
    'ENABLE_CALCULATOR',
    defaultValue: true,
  );
}
