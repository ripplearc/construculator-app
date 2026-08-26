import 'package:construculator/libraries/analytics/testing/fake_feature_flag_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FakeFeatureFlagRepository', () {
    late FakeFeatureFlagRepository repository;

    setUp(() {
      repository = FakeFeatureFlagRepository();
    });

    test('isFeatureEnabled returns the overridden value and records the call', () async {
      repository.flagOverrides['calculator-enabled'] = true;

      final result = await repository.isFeatureEnabled('calculator-enabled');

      result.fold(
        (_) => fail('Expected Right but got Left'),
        (isEnabled) => expect(isEnabled, isTrue),
      );
      expect(repository.isFeatureEnabledCalls, ['calculator-enabled']);
    });

    test('isFeatureEnabled returns null for a key with no override', () async {
      final result = await repository.isFeatureEnabled('unset-flag');

      result.fold(
        (_) => fail('Expected Right but got Left'),
        (isEnabled) => expect(isEnabled, isNull),
      );
    });

    test('reloadFeatureFlags counts calls and returns Right(null)', () async {
      final result = await repository.reloadFeatureFlags();

      expect(result.isRight(), isTrue);
      expect(repository.reloadFeatureFlagsCallCount, 1);

      await repository.reloadFeatureFlags();
      expect(repository.reloadFeatureFlagsCallCount, 2);
    });

    test('getFeatureFlagVariant returns the overridden variant and records the call', () async {
      repository.variantOverrides['pricing-experiment'] = 'variant-b';

      final result = await repository.getFeatureFlagVariant('pricing-experiment');

      result.fold(
        (_) => fail('Expected Right but got Left'),
        (variant) => expect(variant, 'variant-b'),
      );
      expect(repository.getFeatureFlagVariantCalls, ['pricing-experiment']);
    });

    test('getFeatureFlagVariant returns null for a key with no override', () async {
      final result = await repository.getFeatureFlagVariant('unset-flag');

      result.fold(
        (_) => fail('Expected Right but got Left'),
        (variant) => expect(variant, isNull),
      );
    });

    test('getFeatureFlagPayload returns the overridden payload and records the call', () async {
      repository.payloadOverrides['calculator-enabled'] = {'rollout': 'gradual'};

      final result = await repository.getFeatureFlagPayload('calculator-enabled');

      result.fold(
        (_) => fail('Expected Right but got Left'),
        (payload) => expect(payload, {'rollout': 'gradual'}),
      );
      expect(repository.getFeatureFlagPayloadCalls, ['calculator-enabled']);
    });

    test('getFeatureFlagPayload returns null for a key with no override', () async {
      final result = await repository.getFeatureFlagPayload('unset-flag');

      result.fold(
        (_) => fail('Expected Right but got Left'),
        (payload) => expect(payload, isNull),
      );
    });

    test('resetFake clears all recorded calls and overrides', () async {
      repository.flagOverrides['calculator-enabled'] = true;
      repository.variantOverrides['pricing-experiment'] = 'variant-b';
      repository.payloadOverrides['calculator-enabled'] = {'rollout': 'gradual'};
      await repository.isFeatureEnabled('calculator-enabled');
      await repository.getFeatureFlagVariant('pricing-experiment');
      await repository.getFeatureFlagPayload('calculator-enabled');
      await repository.reloadFeatureFlags();

      repository.resetFake();

      expect(repository.isFeatureEnabledCalls, isEmpty);
      expect(repository.flagOverrides, isEmpty);
      expect(repository.getFeatureFlagVariantCalls, isEmpty);
      expect(repository.variantOverrides, isEmpty);
      expect(repository.getFeatureFlagPayloadCalls, isEmpty);
      expect(repository.payloadOverrides, isEmpty);
      expect(repository.reloadFeatureFlagsCallCount, 0);
    });
  });
}
