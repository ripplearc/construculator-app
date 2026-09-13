import 'package:construculator/libraries/config/build_features.dart';
import 'package:construculator/libraries/config/feature_availability.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FeatureAvailability', () {
    tearDown(FeatureAvailability.clearOverrides);

    test('returns the BuildFeatures constant when no override is installed', () {
      expect(
        FeatureAvailability.isEnabled(Feature.calculator),
        BuildFeatures.calculator,
      );
    });

    test('returns the override result once one is installed', () {
      FeatureAvailability.overrideWith((_) => false);
      expect(FeatureAvailability.isEnabled(Feature.calculator), isFalse);

      FeatureAvailability.overrideWith((_) => true);
      expect(FeatureAvailability.isEnabled(Feature.calculator), isTrue);
    });

    test('passes the queried feature to the override resolver', () {
      final queried = <Feature>[];
      FeatureAvailability.overrideWith((feature) {
        queried.add(feature);
        return true;
      });

      FeatureAvailability.isEnabled(Feature.calculator);

      expect(queried, [Feature.calculator]);
    });

    test('clearOverrides restores the compile-time answer', () {
      FeatureAvailability.overrideWith((_) => false);
      FeatureAvailability.clearOverrides();

      expect(
        FeatureAvailability.isEnabled(Feature.calculator),
        BuildFeatures.calculator,
      );
    });
  });
}
