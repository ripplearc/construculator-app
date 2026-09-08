// ignore_for_file: no_direct_instantiation

import 'dart:async';
import 'dart:io';

import 'package:construculator/libraries/analytics/data/repositories/feature_flag_repository_impl.dart';
import 'package:construculator/libraries/analytics/testing/fake_posthog_wrapper.dart';
import 'package:construculator/libraries/either/either.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

void _expectRight<L, R>(Either<L, R> result, void Function(R value) assertions) {
  result.fold((_) => fail('Expected Right but got Left'), assertions);
}

void main() {
  group('FeatureFlagRepositoryImpl', () {
    late FakePosthogWrapper fakePosthogWrapper;
    late FeatureFlagRepositoryImpl repository;

    setUp(() {
      fakePosthogWrapper = FakePosthogWrapper();
      repository = FeatureFlagRepositoryImpl(
        posthogWrapper: fakePosthogWrapper,
      );
    });

    tearDown(() {
      fakePosthogWrapper.resetFake();
    });

    group('isFeatureEnabled', () {
      test('returns Right with the wrapper\'s result when enabled', () async {
        fakePosthogWrapper.flagOverrides['calculator-enabled'] = true;

        final result = await repository.isFeatureEnabled('calculator-enabled');

        _expectRight(result, (value) => expect(value, isTrue));
        expect(
          fakePosthogWrapper.isFeatureEnabledCalls,
          ['calculator-enabled'],
        );
      });

      test('returns Right(null) when the wrapper has no value for the key',
          () async {
        final result = await repository.isFeatureEnabled('calculator-enabled');

        _expectRight(result, (value) => expect(value, isNull));
      });

      test('maps TimeoutException to Right(null), never Left', () async {
        fakePosthogWrapper.errorToThrow = TimeoutException('timed out');

        final result = await repository.isFeatureEnabled('calculator-enabled');

        _expectRight(result, (value) => expect(value, isNull));
      });

      test('maps SocketException to Right(null), never Left', () async {
        fakePosthogWrapper.errorToThrow = const SocketException(
          'no connection',
        );

        final result = await repository.isFeatureEnabled('calculator-enabled');

        _expectRight(result, (value) => expect(value, isNull));
      });

      test('maps unexpected errors to Right(null), never Left', () async {
        fakePosthogWrapper.errorToThrow = Exception('boom');

        final result = await repository.isFeatureEnabled('calculator-enabled');

        _expectRight(result, (value) => expect(value, isNull));
      });
    });

    group('reloadFeatureFlags', () {
      test('reloads and returns Right(null) on success', () async {
        final result = await repository.reloadFeatureFlags();

        _expectRight(result, (_) {
          expect(fakePosthogWrapper.reloadFeatureFlagsCallCount, 1);
        });
      });

      test('maps errors to Right(null), never Left', () async {
        fakePosthogWrapper.errorToThrow = Exception('boom');

        final result = await repository.reloadFeatureFlags();

        _expectRight(result, (_) {});
      });
    });
  });
}
