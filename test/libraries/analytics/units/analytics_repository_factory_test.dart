import 'package:construculator/libraries/analytics/analytics_repository_factory.dart';
import 'package:construculator/libraries/analytics/data/repositories/analytics_repository_impl.dart';
import 'package:construculator/libraries/analytics/data/repositories/no_op_analytics_repository.dart';
import 'package:construculator/libraries/analytics/testing/fake_posthog_wrapper.dart';
import 'package:construculator/libraries/config/env_constants.dart';
import 'package:construculator/libraries/config/testing/fake_env_loader.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('createAnalyticsRepository', () {
    late FakeEnvLoader fakeEnvLoader;
    late FakePosthogWrapper fakePosthogWrapper;
    late int buildPosthogWrapperCallCount;

    setUp(() {
      fakeEnvLoader = FakeEnvLoader();
      fakePosthogWrapper = FakePosthogWrapper();
      buildPosthogWrapperCallCount = 0;
    });

    tearDown(() {
      fakeEnvLoader.clearEnvVars();
      fakePosthogWrapper.resetFake();
    });

    Future<Object> create() {
      return createAnalyticsRepository(
        envLoader: fakeEnvLoader,
        buildPosthogWrapper: () {
          buildPosthogWrapperCallCount++;
          return fakePosthogWrapper;
        },
      );
    }

    test(
      'returns AnalyticsRepositoryImpl when ANALYTICS_ENABLED is true',
      () async {
        fakeEnvLoader.setEnvVar(analyticsEnabledKey, 'true');

        final repository = await create();

        expect(repository, isA<AnalyticsRepositoryImpl>());
      },
    );

    test(
      'initializes the repository with the PostHog config from env',
      () async {
        fakeEnvLoader.setEnvVar(analyticsEnabledKey, 'true');
        fakeEnvLoader.setEnvVar(posthogApiKeyKey, 'phc_test_key');
        fakeEnvLoader.setEnvVar(posthogHostKey, 'https://us.i.posthog.com');
        fakeEnvLoader.setEnvVar(posthogDebugKey, 'true');

        await create();

        expect(fakePosthogWrapper.initializeCalls, [
          const InitializeCall(
            apiKey: 'phc_test_key',
            host: 'https://us.i.posthog.com',
            debug: true,
          ),
        ]);
      },
    );

    test(
      'returns NoOpAnalyticsRepository when ANALYTICS_ENABLED is unset',
      () async {
        final repository = await create();

        expect(repository, isA<NoOpAnalyticsRepository>());
      },
    );

    test(
      'returns NoOpAnalyticsRepository when ANALYTICS_ENABLED is false',
      () async {
        fakeEnvLoader.setEnvVar(analyticsEnabledKey, 'false');

        final repository = await create();

        expect(repository, isA<NoOpAnalyticsRepository>());
      },
    );

    test(
      'treats any value other than the exact string true as disabled',
      () async {
        for (final value in ['True', 'TRUE', '1', 'yes', '']) {
          fakeEnvLoader.setEnvVar(analyticsEnabledKey, value);

          expect(
            await create(),
            isA<NoOpAnalyticsRepository>(),
            reason: 'ANALYTICS_ENABLED="$value" should disable analytics',
          );
        }
      },
    );

    test(
      'never builds the PostHog wrapper when analytics is disabled',
      () async {
        fakeEnvLoader.setEnvVar(analyticsEnabledKey, 'false');

        await create();

        expect(buildPosthogWrapperCallCount, 0);
      },
    );
  });
}
