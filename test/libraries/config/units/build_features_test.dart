import 'package:construculator/libraries/config/build_features.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BuildFeatures', () {
    test('calculator defaults to true when no manifest is passed', () {
      // No --dart-define-from-file is passed to `flutter test`, so this
      // exercises the `defaultValue: true` fallback that keeps the full
      // module graph compiled for the existing test suite.
      expect(BuildFeatures.calculator, isTrue);
    });
  });
}
