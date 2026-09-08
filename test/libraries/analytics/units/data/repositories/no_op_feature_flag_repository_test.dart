// ignore_for_file: no_direct_instantiation

import 'package:construculator/libraries/analytics/data/repositories/no_op_feature_flag_repository.dart';
import 'package:construculator/libraries/either/either.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

void _expectRight<L, R>(Either<L, R> result, void Function(R value) assertions) {
  result.fold((_) => fail('Expected Right but got Left'), assertions);
}

void main() {
  group('NoOpFeatureFlagRepository', () {
    const repository = NoOpFeatureFlagRepository();

    test('isFeatureEnabled returns Right(null)', () async {
      final result = await repository.isFeatureEnabled('calculator-enabled');

      _expectRight(result, (value) => expect(value, isNull));
    });

    test('reloadFeatureFlags returns Right(null)', () async {
      final result = await repository.reloadFeatureFlags();

      _expectRight(result, (_) {});
    });
  });
}
