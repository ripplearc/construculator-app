import 'package:construculator/libraries/config/env_constants.dart';
import 'package:construculator/libraries/config/testing/fake_app_config.dart';
import 'package:construculator/libraries/logging/app_logger.dart';
import 'package:construculator/libraries/sentry/fake_sentry_wrapper.dart';
import 'package:construculator/libraries/sentry/interfaces/sentry_wrapper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';

void main() {
  late AppLogger logger;
  late FakeSentryWrapper fakeSentry;
  late FakeAppConfig fakeConfig;

  setUp(() {
    fakeSentry = FakeSentryWrapper();
    fakeConfig = FakeAppConfig();
    logger = AppLogger(sentryWrapper: fakeSentry, config: fakeConfig);
  });

  tearDown(() {
    fakeSentry.reset();
    AppLogger.setSentryWrapper(null);
    AppLogger.setConfig(null);
  });

  group('Instance creation', () {
    test('creates instance with tag chaining', () {
      final customLogger = logger.tag('Auth').emoji('🔐');
      expect(customLogger, isNotNull);
    });

    test('fresh() resets to default tag and emoji', () {
      final customLogger = logger.tag('CustomTag').emoji('🚀');
      final freshLogger = customLogger.fresh();

      freshLogger.info('Fresh logger test');

      expect(
        fakeSentry.breadcrumbs,
        contains(
          const BreadcrumbCall(
            message: '[Construculator] Fresh logger test',
            level: SentryEventLevel.info,
            category: 'Construculator',
          ),
        ),
      );
    });
  });

  group('debug()', () {
    test('does not send any data to Sentry', () {
      logger.debug('Debug message');

      expect(fakeSentry.breadcrumbs, isEmpty);
      expect(fakeSentry.exceptions, isEmpty);
      expect(fakeSentry.messages, isEmpty);
    });
  });

  group('info()', () {
    test('adds breadcrumb with correct parameters', () {
      logger.tag('TestTag').info('Info message');

      expect(
        fakeSentry.breadcrumbs,
        contains(
          const BreadcrumbCall(
            message: '[TestTag] Info message',
            level: SentryEventLevel.info,
            category: 'TestTag',
          ),
        ),
      );
    });
  });

  group('warning()', () {
    test('adds breadcrumb with error data when provided', () {
      final error = Exception('Test error');
      logger.warning('Warning message', error);

      expect(fakeSentry.breadcrumbs.length, 1);
      expect(fakeSentry.breadcrumbs.first.level, SentryEventLevel.warning);
      expect(
        fakeSentry.breadcrumbs.first.data!['error'],
        contains('Test error'),
      );
    });

    test('adds breadcrumb without error data when not provided', () {
      logger.warning('Warning without error');

      expect(fakeSentry.breadcrumbs.length, 1);
      expect(fakeSentry.breadcrumbs.first.level, SentryEventLevel.warning);
      expect(fakeSentry.breadcrumbs.first.data, isNull);
    });
  });

  group('error()', () {
    test('captures exception when error object provided', () {
      final error = Exception('Test error');
      logger.tag('ErrorTag').error('Error occurred', error);

      expect(fakeSentry.exceptions.length, 1);
      expect(fakeSentry.exceptions.first.exception, error);
      expect(fakeSentry.exceptions.first.tags!['logger_tag'], 'ErrorTag');
      expect(
        fakeSentry.exceptions.first.contexts!['log']['message'],
        contains('Error occurred'),
      );
    });

    test('captures message when no error object provided', () {
      logger.tag('ErrorTag').error('Error message only');

      expect(
        fakeSentry.messages,
        contains(
          const MessageCall(
            message: '[ErrorTag] Error message only',
            level: SentryEventLevel.error,
            tags: {'logger_tag': 'ErrorTag'},
          ),
        ),
      );
    });
  });

  group('omg()', () {
    test('captures exception with fatal severity tag', () {
      final error = Exception('Fatal error');
      logger.tag('FatalTag').omg('Fatal occurred', error);

      expect(fakeSentry.exceptions.length, 1);
      expect(fakeSentry.exceptions.first.exception, error);
      expect(fakeSentry.exceptions.first.tags!['logger_tag'], 'FatalTag');
      expect(fakeSentry.exceptions.first.tags!['severity'], 'fatal');
    });

    test('creates exception from message when no error provided', () {
      logger.omg('Fatal message only');

      expect(fakeSentry.exceptions.length, 1);
      expect(fakeSentry.exceptions.first.exception, isA<Exception>());
    });
  });

  group('Dependency injection', () {
    test('uses injected SentryWrapper', () {
      final customLogger = AppLogger(sentryWrapper: fakeSentry);
      customLogger.info('Test');

      expect(fakeSentry.breadcrumbs, isNotEmpty);
    });

    test('uses static default SentryWrapper when none provided', () {
      final defaultWrapper = FakeSentryWrapper();
      AppLogger.setSentryWrapper(defaultWrapper);

      final customLogger = AppLogger();
      customLogger.info('Test');

      expect(defaultWrapper.breadcrumbs, isNotEmpty);
    });

    test('uses injected Config', () {
      final prodConfig = FakeAppConfig();
      prodConfig.setEnvironment(Environment.prod);
      final prodLogger = AppLogger(
        sentryWrapper: fakeSentry,
        config: prodConfig,
      );

      prodLogger.info('Info in prod');

      expect(fakeSentry.breadcrumbs, isNotEmpty);
    });
  });

  group('AppLogFilter', () {
    test('prod mode suppresses debug and info in console', () {
      final prodConfig = FakeAppConfig();
      prodConfig.setEnvironment(Environment.prod);
      final filter = AppLogFilter(config: prodConfig, debugMode: false);

      expect(
        filter.shouldLog(LogEvent(Level.debug, 'test', error: null, stackTrace: null)),
        isFalse,
      );
      expect(
        filter.shouldLog(LogEvent(Level.info, 'test', error: null, stackTrace: null)),
        isFalse,
      );
      expect(
        filter.shouldLog(LogEvent(Level.warning, 'test', error: null, stackTrace: null)),
        isTrue,
      );
      expect(
        filter.shouldLog(LogEvent(Level.error, 'test', error: null, stackTrace: null)),
        isTrue,
      );
      expect(
        filter.shouldLog(LogEvent(Level.fatal, 'test', error: null, stackTrace: null)),
        isTrue,
      );
    });

    test('qa mode suppresses debug in console', () {
      final qaConfig = FakeAppConfig();
      qaConfig.setEnvironment(Environment.qa);
      final filter = AppLogFilter(config: qaConfig, debugMode: false);

      expect(
        filter.shouldLog(LogEvent(Level.debug, 'test', error: null, stackTrace: null)),
        isFalse,
      );
      expect(
        filter.shouldLog(LogEvent(Level.info, 'test', error: null, stackTrace: null)),
        isTrue,
      );
      expect(
        filter.shouldLog(LogEvent(Level.warning, 'test', error: null, stackTrace: null)),
        isTrue,
      );
      expect(
        filter.shouldLog(LogEvent(Level.error, 'test', error: null, stackTrace: null)),
        isTrue,
      );
    });

    test('dev mode logs all levels', () {
      final devConfig = FakeAppConfig();
      devConfig.setEnvironment(Environment.dev);
      final filter = AppLogFilter(config: devConfig, debugMode: false);

      expect(
        filter.shouldLog(LogEvent(Level.debug, 'test', error: null, stackTrace: null)),
        isTrue,
      );
      expect(
        filter.shouldLog(LogEvent(Level.info, 'test', error: null, stackTrace: null)),
        isTrue,
      );
      expect(
        filter.shouldLog(LogEvent(Level.warning, 'test', error: null, stackTrace: null)),
        isTrue,
      );
    });

    test('debug mode overrides environment filtering', () {
      final prodConfig = FakeAppConfig();
      prodConfig.setEnvironment(Environment.prod);
      final filter = AppLogFilter(config: prodConfig, debugMode: true);

      expect(
        filter.shouldLog(LogEvent(Level.debug, 'test', error: null, stackTrace: null)),
        isTrue,
      );
      expect(
        filter.shouldLog(LogEvent(Level.info, 'test', error: null, stackTrace: null)),
        isTrue,
      );
    });

    test('null config allows all logs', () {
      final filter = AppLogFilter(config: null);

      expect(
        filter.shouldLog(LogEvent(Level.debug, 'test', error: null, stackTrace: null)),
        isTrue,
      );
      expect(
        filter.shouldLog(LogEvent(Level.info, 'test', error: null, stackTrace: null)),
        isTrue,
      );
    });
  });
}
