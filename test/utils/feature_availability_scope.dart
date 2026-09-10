import 'package:construculator/libraries/config/feature_availability.dart';
import 'package:flutter_test/flutter_test.dart';

/// Applies the team rule for feature-exclusion tests to the enclosing group.
///
/// Call once near the top of a test file's `main`. Each test then starts with
/// every optional feature enabled, so the default is the full app. A test that
/// checks one feature's absence calls [FeatureAvailability.overrideWith] itself
/// with a resolver that returns `false` for that single feature. The override
/// is a process-global, so this registers a per-test `setUp` that reinstalls
/// the all-enabled resolver and a `tearDown` that clears it. A test that
/// forgets to reset cannot leak its override into the next test.
void enableAllFeaturesPerTest() {
  setUp(() => FeatureAvailability.overrideWith((_) => true));
  tearDown(FeatureAvailability.clearOverrides);
}
