// ignore_for_file: no_direct_instantiation

import 'package:construculator/libraries/analytics/posthog_wrapper_impl.dart';
import 'package:construculator/libraries/analytics/testing/fake_posthog_sdk.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

void main() {
  group('PosthogWrapperImpl', () {
    const testApiKey = 'phc_test_key';
    const testHost = 'https://us.i.posthog.com';

    late FakePosthogSdk fakePosthogSdk;
    late PosthogWrapperImpl posthogWrapper;

    setUp(() {
      fakePosthogSdk = FakePosthogSdk();
      posthogWrapper = PosthogWrapperImpl(posthogSdk: fakePosthogSdk);
    });

    tearDown(() {
      fakePosthogSdk.resetFake();
    });

    group('initialize', () {
      test('skips SDK setup when apiKey is empty', () async {
        await posthogWrapper.initialize(apiKey: '', host: testHost);

        expect(fakePosthogSdk.setupCallCount, 0);
      });

      test('skips SDK setup when host is empty', () async {
        await posthogWrapper.initialize(apiKey: testApiKey, host: '');

        expect(fakePosthogSdk.setupCallCount, 0);
      });

      test('sets up the SDK with the given apiKey, host, and debug flag',
          () async {
        await posthogWrapper.initialize(
          apiKey: testApiKey,
          host: testHost,
          debug: true,
        );

        expect(fakePosthogSdk.setupCallCount, 1);
        final config = fakePosthogSdk.lastConfig!;
        expect(config.projectToken, testApiKey);
        expect(config.host, testHost);
        expect(config.debug, isTrue);
        expect(config.personProfiles, PostHogPersonProfiles.identifiedOnly);
      });
    });

    group('when not initialized', () {
      test('capture is a no-op', () async {
        await posthogWrapper.capture(eventName: 'estimation_created');

        expect(fakePosthogSdk.capturedEvents, isEmpty);
      });

      test('identify is a no-op', () async {
        await posthogWrapper.identify(userId: 'user-1');

        expect(fakePosthogSdk.identifyCalls, isEmpty);
      });

      test('reset is a no-op', () async {
        await posthogWrapper.reset();

        expect(fakePosthogSdk.resetCallCount, 0);
      });

      test('setPersonProperties is a no-op', () async {
        await posthogWrapper.setPersonProperties(
          userProperties: {'role': 'engineer'},
        );

        expect(fakePosthogSdk.setPersonPropertiesCalls, isEmpty);
      });

      test('group is a no-op', () async {
        await posthogWrapper.group(groupType: 'project', groupKey: 'proj-1');

        expect(fakePosthogSdk.groupCalls, isEmpty);
      });

      test('isFeatureEnabled returns null without querying the SDK',
          () async {
        final result = await posthogWrapper.isFeatureEnabled(
          'calculator-enabled',
        );

        expect(result, isNull);
        expect(fakePosthogSdk.isFeatureEnabledCalls, isEmpty);
      });

      test('reloadFeatureFlags is a no-op', () async {
        await posthogWrapper.reloadFeatureFlags();

        expect(fakePosthogSdk.reloadFeatureFlagsCallCount, 0);
      });
    });

    group('when initialized', () {
      setUp(() async {
        await posthogWrapper.initialize(apiKey: testApiKey, host: testHost);
      });

      test('capture delegates to the SDK', () async {
        await posthogWrapper.capture(
          eventName: 'estimation_created',
          properties: {'estimation_id': 'est-1'},
        );

        expect(fakePosthogSdk.capturedEvents, [
          const CaptureCall(
            eventName: 'estimation_created',
            properties: {'estimation_id': 'est-1'},
          ),
        ]);
      });

      test('identify delegates to the SDK', () async {
        await posthogWrapper.identify(
          userId: 'user-1',
          userProperties: {'role': 'engineer'},
        );

        expect(fakePosthogSdk.identifyCalls, [
          const IdentifyCall(
            userId: 'user-1',
            userProperties: {'role': 'engineer'},
          ),
        ]);
      });

      test('reset delegates to the SDK', () async {
        await posthogWrapper.reset();

        expect(fakePosthogSdk.resetCallCount, 1);
      });

      test('setPersonProperties delegates to the SDK', () async {
        await posthogWrapper.setPersonProperties(
          userProperties: {'role': 'engineer'},
        );

        expect(fakePosthogSdk.setPersonPropertiesCalls, [
          const SetPersonPropertiesCall(
            userPropertiesToSet: {'role': 'engineer'},
          ),
        ]);
      });

      test('group delegates to the SDK', () async {
        await posthogWrapper.group(
          groupType: 'project',
          groupKey: 'proj-1',
          groupProperties: {'project_name': 'Test Project'},
        );

        expect(fakePosthogSdk.groupCalls, [
          const GroupCall(
            groupType: 'project',
            groupKey: 'proj-1',
            groupProperties: {'project_name': 'Test Project'},
          ),
        ]);
      });

      test('isFeatureEnabled delegates to the SDK', () async {
        fakePosthogSdk.isFeatureEnabledResult = true;

        final result = await posthogWrapper.isFeatureEnabled(
          'calculator-enabled',
        );

        expect(result, isTrue);
        expect(fakePosthogSdk.isFeatureEnabledCalls, ['calculator-enabled']);
      });

      test('reloadFeatureFlags delegates to the SDK', () async {
        await posthogWrapper.reloadFeatureFlags();

        expect(fakePosthogSdk.reloadFeatureFlagsCallCount, 1);
      });
    });
  });
}
