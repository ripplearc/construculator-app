/// Compile-time feature composition, resolved by the AOT compiler.
///
/// Every flag here must stay a top-level/static `const bool` fed by
/// `bool.fromEnvironment`. That is what lets the compiler fold the condition
/// and tree-shake the dead branch, the same mechanism `kDebugMode` relies on
/// (`flutter/lib/src/foundation/constants.dart`).
///
/// The folding is not limited to a literal in place. The AOT compiler does
/// interprocedural constant propagation, so a const value still folds after
/// being passed as a function argument, read from a const object field, or
/// returned from a `switch` on a const enum. What stops the fold is a value
/// the compiler cannot prove constant at that point, such as one read through
/// a mutable hook that a test can reassign.
///
/// Because of that, any site whose job is to keep a feature's code out of the
/// build must test the bare `BuildFeatures.<feature>` constant here, ANDed in
/// front of any other condition. Do not gate such a site on
/// `FeatureAvailability.isEnabled`: that call carries a test override hook, so
/// its result is never constant and the branch always stays in the output.
/// `FeatureAvailability` is for runtime decisions and for the exclusion tests,
/// not for code removal.
///
/// Values are supplied per flavor via `--dart-define-from-file=config/flavors/<flavor>.json`
/// (see `codemagic.yaml` and `scripts/run_check.sh`). `defaultValue: true`
/// is deliberate: a bare `flutter run` or `flutter test`, with no manifest
/// passed, compiles the complete module graph.
///
/// This is unrelated to the runtime, PostHog-backed flag system
/// (`FeatureFlagRepository` / `FeatureFlagModule` in
/// `lib/libraries/analytics/`). That system decides behavior at runtime
/// per user or cohort. This one decides what gets compiled in at all.
abstract final class BuildFeatures {
  /// True unless a flavor manifest sets `ENABLE_CALCULATOR: false`.
  static const bool calculator = bool.fromEnvironment(
    'ENABLE_CALCULATOR',
    defaultValue: true,
  );
}
