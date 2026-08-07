// ignore_for_file: no_direct_instantiation

import 'package:construculator/libraries/analytics/analytics_navigator_observer.dart';
import 'package:construculator/libraries/analytics/data/repositories/analytics_repository_impl.dart';
import 'package:construculator/libraries/analytics/data/repositories/no_op_analytics_repository.dart';
import 'package:construculator/libraries/analytics/testing/fake_posthog_wrapper.dart';
import 'package:construculator/libraries/config/testing/fake_env_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

MaterialPageRoute<void> _routeNamed(String? name) {
  return MaterialPageRoute<void>(
    settings: RouteSettings(name: name),
    builder: (_) => const SizedBox(),
  );
}

void main() {
  group('AnalyticsNavigatorObserver', () {
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

    test('captures screen_viewed with the route name for a static route', () {
      final observer = AnalyticsNavigatorObserver(
        analyticsRepository: repository,
        argsProvider: () => ModularArguments(uri: Uri.parse('/dashboard')),
      );

      observer.didPush(_routeNamed('/dashboard'), null);

      expect(fakePosthogWrapper.capturedEvents, [
        const CaptureCall(
          eventName: 'screen_viewed',
          properties: {'screen_name': '/dashboard'},
        ),
      ]);
    });

    test('strips resolved param values from the route name', () {
      final observer = AnalyticsNavigatorObserver(
        analyticsRepository: repository,
        argsProvider: () => ModularArguments(
          uri: Uri.parse('/details/abc123'),
          params: {'estimationId': 'abc123'},
        ),
      );

      observer.didPush(_routeNamed('/details/abc123'), null);

      expect(fakePosthogWrapper.capturedEvents, [
        const CaptureCall(
          eventName: 'screen_viewed',
          properties: {'screen_name': '/details/:estimationId'},
        ),
      ]);
    });

    test('never sends raw route arguments as properties', () {
      final observer = AnalyticsNavigatorObserver(
        analyticsRepository: repository,
        argsProvider: () => ModularArguments(uri: Uri.parse('/dashboard')),
      );

      final route = MaterialPageRoute<void>(
        settings: const RouteSettings(
          name: '/dashboard',
          arguments: {'raw': 'free text with an id 12345'},
        ),
        builder: (_) => const SizedBox(),
      );

      observer.didPush(route, null);

      expect(fakePosthogWrapper.capturedEvents, [
        const CaptureCall(
          eventName: 'screen_viewed',
          properties: {'screen_name': '/dashboard'},
        ),
      ]);
    });

    test('captures nothing when the route has no name', () {
      final observer = AnalyticsNavigatorObserver(
        analyticsRepository: repository,
        argsProvider: () => ModularArguments(uri: Uri.parse('/')),
      );

      observer.didPush(_routeNamed(null), null);

      expect(fakePosthogWrapper.capturedEvents, isEmpty);
    });

    test('captures nothing when analytics is disabled (NoOpAnalyticsRepository)', () {
      final observer = AnalyticsNavigatorObserver(
        analyticsRepository: const NoOpAnalyticsRepository(),
        argsProvider: () => ModularArguments(uri: Uri.parse('/dashboard')),
      );

      observer.didPush(_routeNamed('/dashboard'), null);

      expect(fakePosthogWrapper.capturedEvents, isEmpty);
    });
  });
}
