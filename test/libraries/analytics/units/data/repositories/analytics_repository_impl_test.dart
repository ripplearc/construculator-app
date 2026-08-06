// ignore_for_file: no_direct_instantiation

import 'dart:async';
import 'dart:io';

import 'package:construculator/libraries/analytics/data/repositories/analytics_repository_impl.dart';
import 'package:construculator/libraries/analytics/domain/entities/analytics_event.dart';
import 'package:construculator/libraries/analytics/domain/entities/analytics_user_properties.dart';
import 'package:construculator/libraries/analytics/domain/types/analytics_error_type.dart';
import 'package:construculator/libraries/analytics/testing/fake_posthog_wrapper.dart';
import 'package:construculator/libraries/config/env_constants.dart';
import 'package:construculator/libraries/config/testing/fake_env_loader.dart';
import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

void _expectRight<L, R>(Either<L, R> result, void Function(R value) assertions) {
  result.fold((_) => fail('Expected Right but got Left'), assertions);
}

void _expectLeft<L, R>(Either<L, R> result, void Function(L error) assertions) {
  result.fold(assertions, (_) => fail('Expected Left but got Right'));
}

void main() {
  group('AnalyticsRepositoryImpl', () {
    late FakeEnvLoader fakeEnvLoader;
    late FakePosthogWrapper fakePosthogWrapper;
    late AnalyticsRepositoryImpl repository;

    setUp(() {
      fakeEnvLoader = FakeEnvLoader();
      fakePosthogWrapper = FakePosthogWrapper();
      repository = AnalyticsRepositoryImpl(
        envLoader: fakeEnvLoader,
        posthogWrapper: fakePosthogWrapper,
      );
    });

    tearDown(() {
      fakeEnvLoader.clearEnvVars();
      fakePosthogWrapper.resetFake();
    });

    group('initialize', () {
      test('reads apiKey, host, and debug from EnvLoader, never dotenv',
          () async {
        fakeEnvLoader.setEnvVar(posthogApiKeyKey, 'phc_test_key');
        fakeEnvLoader.setEnvVar(posthogHostKey, 'https://us.i.posthog.com');
        fakeEnvLoader.setEnvVar(posthogDebugKey, 'true');

        await repository.initialize();

        expect(fakePosthogWrapper.initializeCalls, [
          const InitializeCall(
            apiKey: 'phc_test_key',
            host: 'https://us.i.posthog.com',
            debug: true,
          ),
        ]);
      });

      test('defaults apiKey and host to empty string when unset', () async {
        await repository.initialize();

        expect(fakePosthogWrapper.initializeCalls, [
          const InitializeCall(apiKey: '', host: '', debug: false),
        ]);
      });
    });

    group('track', () {
      test('captures the event and returns Right on success', () async {
        const event = AnalyticsEvent(
          name: 'estimation_created',
          properties: {'estimation_id': 'est-1'},
        );

        final result = await repository.track(event);

        _expectRight(result, (_) {
          expect(fakePosthogWrapper.capturedEvents, [
            const CaptureCall(
              eventName: 'estimation_created',
              properties: {'estimation_id': 'est-1'},
            ),
          ]);
        });
      });

      test('maps TimeoutException to AnalyticsFailure(timeoutError)',
          () async {
        fakePosthogWrapper.errorToThrow = TimeoutException('timed out');

        final result = await repository.track(
          const AnalyticsEvent(name: 'estimation_created'),
        );

        _expectLeft(result, (failure) {
          expect(
            failure,
            const AnalyticsFailure(errorType: AnalyticsErrorType.timeoutError),
          );
        });
      });

      test('maps SocketException to AnalyticsFailure(connectionError)',
          () async {
        fakePosthogWrapper.errorToThrow = const SocketException(
          'no connection',
        );

        final result = await repository.track(
          const AnalyticsEvent(name: 'estimation_created'),
        );

        _expectLeft(result, (failure) {
          expect(
            failure,
            const AnalyticsFailure(
              errorType: AnalyticsErrorType.connectionError,
            ),
          );
        });
      });

      test('maps unexpected errors to UnexpectedFailure', () async {
        fakePosthogWrapper.errorToThrow = Exception('boom');

        final result = await repository.track(
          const AnalyticsEvent(name: 'estimation_created'),
        );

        _expectLeft(result, (failure) {
          expect(failure, isA<UnexpectedFailure>());
        });
      });
    });

    group('identify', () {
      test('identifies the user and returns Right on success', () async {
        const properties = AnalyticsUserProperties(email: 'a@example.com');

        final result = await repository.identify(
          userId: 'user-1',
          properties: properties,
        );

        _expectRight(result, (_) {
          expect(fakePosthogWrapper.identifyCalls, [
            const IdentifyCall(
              userId: 'user-1',
              userProperties: {'email': 'a@example.com'},
            ),
          ]);
        });
      });

      test('maps errors to a Failure', () async {
        fakePosthogWrapper.errorToThrow = Exception('boom');

        final result = await repository.identify(
          userId: 'user-1',
          properties: const AnalyticsUserProperties(),
        );

        _expectLeft(result, (failure) => expect(failure, isA<Failure>()));
      });
    });

    group('reset', () {
      test('resets identity and returns Right on success', () async {
        final result = await repository.reset();

        _expectRight(result, (_) {
          expect(fakePosthogWrapper.resetCallCount, 1);
        });
      });

      test('maps errors to a Failure', () async {
        fakePosthogWrapper.errorToThrow = Exception('boom');

        final result = await repository.reset();

        _expectLeft(result, (failure) => expect(failure, isA<Failure>()));
      });
    });

    group('setUserProperties', () {
      test('updates properties and returns Right on success', () async {
        const properties = AnalyticsUserProperties(role: 'engineer');

        final result = await repository.setUserProperties(properties);

        _expectRight(result, (_) {
          expect(fakePosthogWrapper.setPersonPropertiesCalls, [
            {'role': 'engineer'},
          ]);
        });
      });

      test('maps errors to a Failure', () async {
        fakePosthogWrapper.errorToThrow = Exception('boom');

        final result = await repository.setUserProperties(
          const AnalyticsUserProperties(),
        );

        _expectLeft(result, (failure) => expect(failure, isA<Failure>()));
      });
    });

    group('group', () {
      test('associates the group and returns Right on success', () async {
        final result = await repository.group(
          groupType: 'project',
          groupKey: 'proj-1',
          properties: {'project_name': 'Test Project'},
        );

        _expectRight(result, (_) {
          expect(fakePosthogWrapper.groupCalls, [
            const GroupCall(
              groupType: 'project',
              groupKey: 'proj-1',
              groupProperties: {'project_name': 'Test Project'},
            ),
          ]);
        });
      });

      test('maps errors to a Failure', () async {
        fakePosthogWrapper.errorToThrow = Exception('boom');

        final result = await repository.group(
          groupType: 'project',
          groupKey: 'proj-1',
        );

        _expectLeft(result, (failure) => expect(failure, isA<Failure>()));
      });
    });
  });
}
