import 'package:construculator/libraries/sentry/fake_sentry_wrapper.dart';
import 'package:construculator/libraries/sentry/interfaces/sentry_wrapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeSentryWrapper sentry;

  setUp(() => sentry = FakeSentryWrapper());

  tearDown(() => sentry.reset());

  group('FakeSentryWrapper', () {
    group('initialize', () {
      test('executes the appRunner immediately', () {
        var ran = false;
        sentry.initialize(() => ran = true);
        expect(ran, isTrue);
      });
    });

    group('addBreadcrumb', () {
      test('records breadcrumb with required fields', () async {
        await sentry.addBreadcrumb(
          message: 'user tapped button',
          level: SentryEventLevel.info,
        );

        expect(sentry.breadcrumbs, hasLength(1));
        expect(sentry.breadcrumbs.first.message, 'user tapped button');
        expect(sentry.breadcrumbs.first.level, SentryEventLevel.info);
        expect(sentry.breadcrumbs.first.category, isNull);
        expect(sentry.breadcrumbs.first.data, isNull);
      });

      test('records breadcrumb with optional category and data', () async {
        await sentry.addBreadcrumb(
          message: 'api call',
          level: SentryEventLevel.debug,
          category: 'network',
          data: {'url': '/api/v1/projects'},
        );

        final crumb = sentry.breadcrumbs.first;
        expect(crumb.category, 'network');
        expect(crumb.data, {'url': '/api/v1/projects'});
      });
    });

    group('captureException', () {
      test('records exception with required field', () async {
        final error = Exception('something broke');
        await sentry.captureException(error);

        expect(sentry.exceptions, hasLength(1));
        expect(sentry.exceptions.first.exception, error);
        expect(sentry.exceptions.first.stackTrace, isNull);
        expect(sentry.exceptions.first.tags, isNull);
        expect(sentry.exceptions.first.contexts, isNull);
      });

      test('records exception with optional stackTrace, tags, and contexts', () async {
        final error = Exception('fatal');
        final trace = StackTrace.current;
        await sentry.captureException(
          error,
          stackTrace: trace,
          tags: {'env': 'prod'},
          contexts: {'request': '/home'},
        );

        final recorded = sentry.exceptions.first;
        expect(recorded.stackTrace, trace);
        expect(recorded.tags, {'env': 'prod'});
        expect(recorded.contexts, {'request': '/home'});
      });
    });

    group('captureMessage', () {
      test('records message with required fields', () async {
        await sentry.captureMessage('app started', level: SentryEventLevel.info);

        expect(sentry.messages, hasLength(1));
        expect(sentry.messages.first.message, 'app started');
        expect(sentry.messages.first.level, SentryEventLevel.info);
        expect(sentry.messages.first.tags, isNull);
      });

      test('records message with optional tags', () async {
        await sentry.captureMessage(
          'login failed',
          level: SentryEventLevel.warning,
          tags: {'reason': 'bad_password'},
        );

        expect(sentry.messages.first.tags, {'reason': 'bad_password'});
      });
    });

    group('setUser', () {
      test('sets the userId', () async {
        await sentry.setUser('user-123');
        expect(sentry.userId, 'user-123');
      });

      test('clears the userId when null is passed', () async {
        await sentry.setUser('user-123');
        await sentry.setUser(null);
        expect(sentry.userId, isNull);
      });
    });

    group('reset', () {
      test('clears all recorded data', () async {
        await sentry.addBreadcrumb(message: 'b', level: SentryEventLevel.info);
        await sentry.captureException(Exception('e'));
        await sentry.captureMessage('m', level: SentryEventLevel.error);
        await sentry.setUser('user-1');

        sentry.reset();

        expect(sentry.breadcrumbs, isEmpty);
        expect(sentry.exceptions, isEmpty);
        expect(sentry.messages, isEmpty);
        expect(sentry.userId, isNull);
      });
    });

    group('BreadcrumbCall equality', () {
      test('two calls with same values are equal', () {
        const a = BreadcrumbCall(message: 'x', level: SentryEventLevel.info);
        const b = BreadcrumbCall(message: 'x', level: SentryEventLevel.info);
        expect(a, equals(b));
      });
    });

    group('ExceptionCall equality', () {
      test('two calls with same exception are equal', () {
        final error = Exception('e');
        final a = ExceptionCall(exception: error);
        final b = ExceptionCall(exception: error);
        expect(a, equals(b));
      });
    });

    group('MessageCall equality', () {
      test('two calls with same values are equal', () {
        const a = MessageCall(message: 'hi', level: SentryEventLevel.info);
        const b = MessageCall(message: 'hi', level: SentryEventLevel.info);
        expect(a, equals(b));
      });
    });
  });
}
