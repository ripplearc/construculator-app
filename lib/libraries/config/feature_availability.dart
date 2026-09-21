import 'package:construculator/libraries/config/build_features.dart';
import 'package:flutter/foundation.dart' show kReleaseMode, visibleForTesting;

/// An optional feature that a flavor can leave out of its build.
///
/// Every value maps to one compile-time constant in [BuildFeatures].
enum Feature {
  /// The standalone calculator, reached from the app shell action button.
  calculator,
}

/// Runtime answer to "is this optional feature part of the running build".
///
/// Read this from the places that decide app behavior while the process runs:
/// route guards, the wildcard fallback route, the tab list, and feature
/// entry-point buttons. It returns the compile-time answer from [BuildFeatures]
/// unless a test has installed an override through [overrideWith].
///
/// Do not read this at a site whose job is to keep a feature's code out of the
/// compiled output. Such a site must test the bare `BuildFeatures.<feature>`
/// constant directly, ANDed in front of any other condition, so the AOT
/// compiler can fold it and drop the branch. [isEnabled] can never be dropped
/// because the override hook makes its result non-constant.
///
/// This is unrelated to `FeatureFlagRepository` / `FeatureFlagModule` in
/// `lib/libraries/analytics/`, the PostHog-backed system that ramps features
/// per user at runtime. That system decides behavior for a feature that is
/// compiled in; this one reports whether it is compiled in at all.
abstract final class FeatureAvailability {
  static bool Function(Feature feature)? _override;

  /// Installs a resolver that [isEnabled] consults instead of [BuildFeatures].
  ///
  /// Call this from a test file's `setUp` with a resolver that returns `true`
  /// for every feature, so each test starts with the full app. Inside the one
  /// test that checks a feature's absence, call it again with a resolver that
  /// returns `false` for that single feature. Pair every use with
  /// [clearOverrides] in `tearDown`.
  @visibleForTesting
  static void overrideWith(bool Function(Feature feature) resolver) {
    assert(
      !kReleaseMode,
      'FeatureAvailability.overrideWith must not run in a release build.',
    );
    _override = resolver;
  }

  /// Removes any resolver installed by [overrideWith].
  @visibleForTesting
  static void clearOverrides() {
    _override = null;
  }

  /// Whether [feature] is part of this build.
  ///
  /// Returns the test override when one is installed, otherwise the
  /// compile-time answer from [BuildFeatures].
  static bool isEnabled(Feature feature) =>
      _override?.call(feature) ?? _compileDefault(feature);

  static bool _compileDefault(Feature feature) {
    switch (feature) {
      case Feature.calculator:
        return BuildFeatures.calculator;
    }
  }
}
