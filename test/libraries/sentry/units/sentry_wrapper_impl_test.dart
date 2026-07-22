// ignore_for_file: no_direct_instantiation

import 'package:construculator/libraries/config/env_constants.dart';
import 'package:construculator/libraries/config/testing/fake_app_config.dart';
import 'package:construculator/libraries/config/testing/fake_env_loader.dart';
import 'package:construculator/libraries/sentry/interfaces/sentry_wrapper.dart';
import 'package:construculator/libraries/sentry/sentry_wrapper_impl.dart';
import 'package:construculator/libraries/sentry/testing/fake_sentry_sdk.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

void main() {
  group('SentryWrapperImpl', () {
    const testDsn = 'https://key@sentry.example.com/1';

    late FakeEnvLoader fakeEnvLoader;
    late FakeAppConfig fakeConfig;
    late FakeSentrySdk fakeSentrySdk;
    late SentryWrapperImpl sentryWrapper;

    setUp(() {
      fakeEnvLoader = FakeEnvLoader();
      fakeConfig = FakeAppConfig();
      fakeSentrySdk = FakeSentrySdk();
      sentryWrapper = SentryWrapperImpl(
        envLoader: fakeEnvLoader,
        config: fakeConfig,
        sentrySdk: fakeSentrySdk,
      );
    });

    tearDown(() {
      fakeEnvLoader.clearEnvVars();
      fakeSentrySdk.reset();
    });

    Future<void> initializeWithDsn() async {
      fakeEnvLoader.setEnvVar(sentryDsnKey, testDsn);
      await sentryWrapper.initialize(() {});
    }

    group('initialize', () {
      test('skips SDK init and still runs the app when DSN is missing',
          () async {
        var appRunnerCalled = false;

        await sentryWrapper.initialize(() => appRunnerCalled = true);

        expect(appRunnerCalled, isTrue);
        expect(fakeSentrySdk.initCallCount, 0);
      });

      test('skips SDK init and still runs the app when DSN is empty',
          () async {
        fakeEnvLoader.setEnvVar(sentryDsnKey, '');
        var appRunnerCalled = false;

        await sentryWrapper.initialize(() => appRunnerCalled = true);

        expect(appRunnerCalled, isTrue);
        expect(fakeSentrySdk.initCallCount, 0);
      });

      test('initializes the SDK with the configured DSN and options',
          () async {
        fakeEnvLoader.setEnvVar(sentryDsnKey, testDsn);
        var appRunnerCalled = false;

        await sentryWrapper.initialize(() => appRunnerCalled = true);

        expect(appRunnerCalled, isTrue);
        expect(fakeSentrySdk.initCallCount, 1);
        final options = fakeSentrySdk.lastConfiguredOptions;
        expect(options, isNotNull);
        expect(options!.dsn, testDsn);
        expect(options.environment, devReadableName);
        expect(options.tracesSampleRate, 0.0);
        expect(options.attachScreenshot, isFalse);
        expect(options.enableAutoSessionTracking, isTrue);
        expect(options.captureFailedRequests, isTrue);
      });
    });

    group('before initialization', () {
      test('addBreadcrumb is a no-op before initialization', () async {
        await sentryWrapper.addBreadcrumb(
          message: 'test',
          level: SentryEventLevel.info,
        );

        expect(fakeSentrySdk.addedBreadcrumbs, isEmpty);
      });

      test('captureException is a no-op before initialization', () async {
        await sentryWrapper.captureException(Exception('boom'));

        expect(fakeSentrySdk.capturedExceptions, isEmpty);
      });

      test('captureMessage is a no-op before initialization', () async {
        await sentryWrapper.captureMessage(
          'test',
          level: SentryEventLevel.error,
        );

        expect(fakeSentrySdk.capturedMessages, isEmpty);
      });

      test('setUser is a no-op before initialization', () async {
        await sentryWrapper.setUser('user-1');

        expect(fakeSentrySdk.configureScopeCallbacks, isEmpty);
      });

      test('stays a no-op after initialize ran with an empty DSN', () async {
        // Empty DSN leaves the wrapper uninitialized, so calls stay no-ops.
        await sentryWrapper.initialize(() {});
        await sentryWrapper.captureMessage(
          'test',
          level: SentryEventLevel.error,
        );

        expect(fakeSentrySdk.capturedMessages, isEmpty);
      });
    });

    group('addBreadcrumb', () {
      test('forwards message, category, and data after initialization',
          () async {
        await initializeWithDsn();

        await sentryWrapper.addBreadcrumb(
          message: 'tapped button',
          level: SentryEventLevel.info,
          category: 'ui',
          data: {'key': 'value'},
        );

        expect(fakeSentrySdk.addedBreadcrumbs, hasLength(1));
        final breadcrumb = fakeSentrySdk.addedBreadcrumbs.single;
        expect(breadcrumb.message, 'tapped button');
        expect(breadcrumb.category, 'ui');
        expect(breadcrumb.data, {'key': 'value'});
        expect(breadcrumb.level, SentryLevel.info);
      });
    });

    group('severity level mapping', () {
      const expectedLevels = {
        SentryEventLevel.debug: SentryLevel.debug,
        SentryEventLevel.info: SentryLevel.info,
        SentryEventLevel.warning: SentryLevel.warning,
        SentryEventLevel.error: SentryLevel.error,
        SentryEventLevel.fatal: SentryLevel.fatal,
      };

      for (final entry in expectedLevels.entries) {
        test('maps SentryEventLevel.${entry.key.name} for captureMessage',
            () async {
          await initializeWithDsn();

          await sentryWrapper.captureMessage('test', level: entry.key);

          expect(fakeSentrySdk.capturedMessageLevels.single, entry.value);
        });

        test('maps SentryEventLevel.${entry.key.name} for addBreadcrumb',
            () async {
          await initializeWithDsn();

          await sentryWrapper.addBreadcrumb(
            message: 'test',
            level: entry.key,
          );

          expect(
            fakeSentrySdk.addedBreadcrumbs.single.level,
            entry.value,
          );
        });
      }
    });

    group('captureException', () {
      test('forwards the exception and stack trace, and applies tags and '
          'contexts to the event scope', () async {
        await initializeWithDsn();
        final exception = Exception('boom');
        final stackTrace = StackTrace.current;

        await sentryWrapper.captureException(
          exception,
          stackTrace: stackTrace,
          tags: {'feature': 'search'},
          contexts: {
            'request': {'id': 'r-1'},
          },
        );

        expect(fakeSentrySdk.capturedExceptions.single, exception);
        expect(fakeSentrySdk.capturedExceptionStackTraces.single, stackTrace);
        final scope = Scope(SentryFlutterOptions());
        await fakeSentrySdk.capturedExceptionScopeCallbacks.single!(scope);
        expect(scope.tags, {'feature': 'search'});
        expect(scope.contexts['request'], {'id': 'r-1'});
      });

      test('leaves the event scope untouched when tags and contexts are '
          'omitted', () async {
        await initializeWithDsn();

        await sentryWrapper.captureException(Exception('boom'));

        final scope = Scope(SentryFlutterOptions());
        await fakeSentrySdk.capturedExceptionScopeCallbacks.single!(scope);
        expect(scope.tags, isEmpty);
      });
    });

    group('captureMessage', () {
      test('forwards the message and applies tags to the event scope',
          () async {
        await initializeWithDsn();

        await sentryWrapper.captureMessage(
          'something happened',
          level: SentryEventLevel.warning,
          tags: {'feature': 'search'},
        );

        expect(fakeSentrySdk.capturedMessages.single, 'something happened');
        final scope = Scope(SentryFlutterOptions());
        await fakeSentrySdk.capturedMessageScopeCallbacks.single!(scope);
        expect(scope.tags, {'feature': 'search'});
      });

      test('leaves the event scope untouched when tags are omitted', () async {
        await initializeWithDsn();

        await sentryWrapper.captureMessage(
          'something happened',
          level: SentryEventLevel.warning,
        );

        final scope = Scope(SentryFlutterOptions());
        await fakeSentrySdk.capturedMessageScopeCallbacks.single!(scope);
        expect(scope.tags, isEmpty);
      });
    });

    group('setUser', () {
      test('sets the scope user after initialization', () async {
        await initializeWithDsn();

        await sentryWrapper.setUser('user-1');

        final scope = Scope(SentryFlutterOptions());
        await fakeSentrySdk.configureScopeCallbacks.single(scope);
        expect(
          scope.user,
          isA<SentryUser>().having((user) => user.id, 'id', 'user-1'),
        );
      });

      test('clears the scope user when passed null', () async {
        await initializeWithDsn();
        final scope = Scope(SentryFlutterOptions());
        await scope.setUser(SentryUser(id: 'stale-user'));

        await sentryWrapper.setUser(null);

        await fakeSentrySdk.configureScopeCallbacks.single(scope);
        expect(scope.user, isNull);
      });
    });
  });
}
