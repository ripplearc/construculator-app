// ignore_for_file: no_direct_instantiation

import 'package:construculator/libraries/analytics/analytics_navigator_observer.dart';
import 'package:construculator/libraries/analytics/current_screen_tracker.dart';
import 'package:construculator/libraries/analytics/data/repositories/analytics_repository_impl.dart';
import 'package:construculator/libraries/analytics/data/repositories/no_op_analytics_repository.dart';
import 'package:construculator/libraries/analytics/testing/fake_posthog_wrapper.dart';
import 'package:construculator/libraries/config/testing/fake_env_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_modular/src/presenter/navigation/modular_page.dart';
import 'package:flutter_test/flutter_test.dart';

MaterialPageRoute<void> _routeNamed(String? name) {
  return MaterialPageRoute<void>(
    settings: RouteSettings(name: name),
    builder: (_) => const SizedBox(),
  );
}

/// Builds a route whose `settings` is a real [ModularPage], as Modular's own
/// routing pipeline produces, with [templateName] as the originally-declared
/// route name and [resolvedUri] as the value Modular resolved it to.
MaterialPageRoute<void> _modularRouteNamed(
  String templateName, {
  String? resolvedUri,
}) {
  final page = ModularPage<void>(
    route: ParallelRoute<void>(
      name: templateName,
      uri: Uri.parse(resolvedUri ?? templateName),
      child: (_) => const SizedBox(),
    ),
    args: ModularArguments(uri: Uri.parse(resolvedUri ?? templateName)),
    flags: ModularFlags(),
  );
  return MaterialPageRoute<void>(settings: page, builder: (_) => const SizedBox());
}

void main() {
  group('AnalyticsNavigatorObserver', () {
    const testAppVersion = '1.2.3';

    late FakeEnvLoader fakeEnvLoader;
    late FakePosthogWrapper fakePosthogWrapper;
    late CurrentScreenTracker currentScreenTracker;
    late AnalyticsRepositoryImpl repository;
    late AnalyticsNavigatorObserver observer;

    Map<String, dynamic> standardProperties({String? screenName}) => {
      'app_version': testAppVersion,
      'platform': 'android',
      'screen_name': screenName,
    };

    setUp(() {
      fakeEnvLoader = FakeEnvLoader();
      fakePosthogWrapper = FakePosthogWrapper();
      currentScreenTracker = CurrentScreenTracker();
      repository = AnalyticsRepositoryImpl(
        envLoader: fakeEnvLoader,
        posthogWrapper: fakePosthogWrapper,
        currentScreenTracker: currentScreenTracker,
        appVersion: testAppVersion,
      );
      observer = AnalyticsNavigatorObserver(
        analyticsRepository: repository,
        currentScreenTracker: currentScreenTracker,
      );
    });

    tearDown(() {
      fakeEnvLoader.clearEnvVars();
      fakePosthogWrapper.resetFake();
    });

    test('captures screen_viewed with the route name for a static route', () {
      observer.didPush(_routeNamed('/dashboard'), null);

      expect(fakePosthogWrapper.capturedEvents, [
        CaptureCall(
          eventName: 'screen_viewed',
          properties: standardProperties(screenName: '/dashboard'),
        ),
      ]);
    });

    test(
      'reads the template name from ModularPage.route.name, never the '
      'resolved uri',
      () {
        observer.didPush(
          _modularRouteNamed(
            '/details/:estimationId',
            resolvedUri: '/details/abc123',
          ),
          null,
        );

        expect(fakePosthogWrapper.capturedEvents, [
          CaptureCall(
            eventName: 'screen_viewed',
            properties: standardProperties(screenName: '/details/:estimationId'),
          ),
        ]);
      },
    );

    test('never sends raw route arguments as properties', () {
      final route = MaterialPageRoute<void>(
        settings: const RouteSettings(
          name: '/dashboard',
          arguments: {'raw': 'free text with an id 12345'},
        ),
        builder: (_) => const SizedBox(),
      );

      observer.didPush(route, null);

      expect(fakePosthogWrapper.capturedEvents, [
        CaptureCall(
          eventName: 'screen_viewed',
          properties: standardProperties(screenName: '/dashboard'),
        ),
      ]);
    });

    test('captures nothing when the route has no name', () {
      observer.didPush(_routeNamed(null), null);

      expect(fakePosthogWrapper.capturedEvents, isEmpty);
    });

    test('captures nothing when analytics is disabled (NoOpAnalyticsRepository)', () {
      final noOpObserver = AnalyticsNavigatorObserver(
        analyticsRepository: const NoOpAnalyticsRepository(),
        currentScreenTracker: currentScreenTracker,
      );

      noOpObserver.didPush(_routeNamed('/dashboard'), null);

      expect(fakePosthogWrapper.capturedEvents, isEmpty);
    });
  });
}
