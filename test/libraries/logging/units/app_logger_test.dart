import 'package:construculator/libraries/config/env_constants.dart';
import 'package:construculator/libraries/config/interfaces/config.dart';
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

    test(
      'sends error() to a default wrapper set after the logger was built',
      () {
        final earlyLogger = AppLogger().tag('Early');
        final lateWrapper = FakeSentryWrapper();

        AppLogger.setSentryWrapper(lateWrapper);
        earlyLogger.error('Late failure', Exception('boom'));

        expect(lateWrapper.exceptions, hasLength(1));
        expect(lateWrapper.exceptions.single.tags, {'logger_tag': 'Early'});
      },
    );

    test('sends omg() to a default wrapper set after the logger was built', () {
      final earlyLogger = AppLogger().tag('Early');
      final lateWrapper = FakeSentryWrapper();

      AppLogger.setSentryWrapper(lateWrapper);
      earlyLogger.omg('Late fatal', Exception('boom'));

      expect(lateWrapper.exceptions, hasLength(1));
      expect(lateWrapper.exceptions.single.tags, {
        'logger_tag': 'Early',
        'severity': 'fatal',
      });
    });

    test('injected wrapper wins over the default set later', () {
      final defaultWrapper = FakeSentryWrapper();
      AppLogger.setSentryWrapper(defaultWrapper);

      logger.error('Injected failure', Exception('boom'));

      expect(fakeSentry.exceptions, hasLength(1));
      expect(defaultWrapper.exceptions, isEmpty);
    });

    test(
      'tag(), emoji() and fresh() follow a default replaced after they ran',
      () {
        final firstWrapper = FakeSentryWrapper();
        final secondWrapper = FakeSentryWrapper();
        AppLogger.setSentryWrapper(firstWrapper);
        final chained = AppLogger().tag('Chained').emoji('🔗').fresh();

        AppLogger.setSentryWrapper(secondWrapper);
        chained.error('Chained failure', Exception('boom'));

        expect(secondWrapper.exceptions, hasLength(1));
        expect(firstWrapper.exceptions, isEmpty);
      },
    );

    test('stops sending when the default wrapper is cleared', () {
      final defaultWrapper = FakeSentryWrapper();
      AppLogger.setSentryWrapper(defaultWrapper);
      final earlyLogger = AppLogger().tag('Early');

      AppLogger.setSentryWrapper(null);
      earlyLogger.error('After clearing', Exception('boom'));

      expect(defaultWrapper.exceptions, isEmpty);
    });

    List<Level> recordConsoleLevels() {
      final consoleLevels = <Level>[];
      void recordLevel(OutputEvent event) => consoleLevels.add(event.level);
      Logger.addOutputListener(recordLevel);
      addTearDown(() => Logger.removeOutputListener(recordLevel));
      return consoleLevels;
    }

    test(
      'console filter follows a default config set after the logger was built',
      () {
        final consoleLevels = recordConsoleLevels();
        final earlyLogger = AppLogger(debugMode: false);
        final prodConfig = FakeAppConfig()..setEnvironment(Environment.prod);

        earlyLogger.debug('Before the config is set');
        AppLogger.setConfig(prodConfig);
        earlyLogger.debug('After the config is set');
        earlyLogger.warning('Warning in prod');

        expect(consoleLevels, [Level.debug, Level.warning]);
      },
    );

    test(
      'console filter follows a default config replaced after the logger was built',
      () {
        final consoleLevels = recordConsoleLevels();
        AppLogger.setConfig(FakeAppConfig()..setEnvironment(Environment.prod));
        final earlyLogger = AppLogger(debugMode: false);

        earlyLogger.debug('Filtered in prod');
        AppLogger.setConfig(FakeAppConfig()..setEnvironment(Environment.dev));
        earlyLogger.debug('Shown in dev');

        expect(consoleLevels, [Level.debug]);
      },
    );

    test(
      'console filter stops filtering when the default config is cleared',
      () {
        final consoleLevels = recordConsoleLevels();
        AppLogger.setConfig(FakeAppConfig()..setEnvironment(Environment.prod));
        final earlyLogger = AppLogger(debugMode: false);

        earlyLogger.debug('Filtered in prod');
        AppLogger.setConfig(null);
        earlyLogger.debug('Shown without a config');

        expect(consoleLevels, [Level.debug]);
      },
    );

    test('injected Config wins over a default config set later', () {
      final consoleLevels = recordConsoleLevels();
      final devConfig = FakeAppConfig()..setEnvironment(Environment.dev);
      final devLogger = AppLogger(config: devConfig, debugMode: false);

      AppLogger.setConfig(FakeAppConfig()..setEnvironment(Environment.prod));
      devLogger.debug('Debug in dev');

      expect(consoleLevels, [Level.debug]);
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
    test(
      'uses the default config read at filter time when none is injected',
      () {
        Config? currentDefault;
        final filter = AppLogFilter(
          defaultConfig: () => currentDefault,
          debugMode: false,
        );
        final debugEvent = LogEvent(Level.debug, 'test');

        expect(filter.shouldLog(debugEvent), isTrue);

        currentDefault = FakeAppConfig()..setEnvironment(Environment.prod);
        expect(filter.shouldLog(debugEvent), isFalse);
      },
    );

    test('injected config wins over the default config', () {
      final filter = AppLogFilter(
        config: FakeAppConfig()..setEnvironment(Environment.dev),
        defaultConfig: () => FakeAppConfig()..setEnvironment(Environment.prod),
        debugMode: false,
      );

      expect(filter.shouldLog(LogEvent(Level.debug, 'test')), isTrue);
    });

    test('prod mode suppresses debug and info in console', () {
      final prodConfig = FakeAppConfig();
      prodConfig.setEnvironment(Environment.prod);
      final filter = AppLogFilter(config: prodConfig, debugMode: false);

      expect(
        filter.shouldLog(
          LogEvent(Level.debug, 'test', error: null, stackTrace: null),
        ),
        isFalse,
      );
      expect(
        filter.shouldLog(
          LogEvent(Level.info, 'test', error: null, stackTrace: null),
        ),
        isFalse,
      );
      expect(
        filter.shouldLog(
          LogEvent(Level.warning, 'test', error: null, stackTrace: null),
        ),
        isTrue,
      );
      expect(
        filter.shouldLog(
          LogEvent(Level.error, 'test', error: null, stackTrace: null),
        ),
        isTrue,
      );
      expect(
        filter.shouldLog(
          LogEvent(Level.fatal, 'test', error: null, stackTrace: null),
        ),
        isTrue,
      );
    });

    test('qa mode suppresses debug in console', () {
      final qaConfig = FakeAppConfig();
      qaConfig.setEnvironment(Environment.qa);
      final filter = AppLogFilter(config: qaConfig, debugMode: false);

      expect(
        filter.shouldLog(
          LogEvent(Level.debug, 'test', error: null, stackTrace: null),
        ),
        isFalse,
      );
      expect(
        filter.shouldLog(
          LogEvent(Level.info, 'test', error: null, stackTrace: null),
        ),
        isTrue,
      );
      expect(
        filter.shouldLog(
          LogEvent(Level.warning, 'test', error: null, stackTrace: null),
        ),
        isTrue,
      );
      expect(
        filter.shouldLog(
          LogEvent(Level.error, 'test', error: null, stackTrace: null),
        ),
        isTrue,
      );
    });

    test('dev mode logs all levels', () {
      final devConfig = FakeAppConfig();
      devConfig.setEnvironment(Environment.dev);
      final filter = AppLogFilter(config: devConfig, debugMode: false);

      expect(
        filter.shouldLog(
          LogEvent(Level.debug, 'test', error: null, stackTrace: null),
        ),
        isTrue,
      );
      expect(
        filter.shouldLog(
          LogEvent(Level.info, 'test', error: null, stackTrace: null),
        ),
        isTrue,
      );
      expect(
        filter.shouldLog(
          LogEvent(Level.warning, 'test', error: null, stackTrace: null),
        ),
        isTrue,
      );
    });

    test('debug mode overrides environment filtering', () {
      final prodConfig = FakeAppConfig();
      prodConfig.setEnvironment(Environment.prod);
      final filter = AppLogFilter(config: prodConfig, debugMode: true);

      expect(
        filter.shouldLog(
          LogEvent(Level.debug, 'test', error: null, stackTrace: null),
        ),
        isTrue,
      );
      expect(
        filter.shouldLog(
          LogEvent(Level.info, 'test', error: null, stackTrace: null),
        ),
        isTrue,
      );
    });

    test('null config allows all logs', () {
      final filter = AppLogFilter(config: null);

      expect(
        filter.shouldLog(
          LogEvent(Level.debug, 'test', error: null, stackTrace: null),
        ),
        isTrue,
      );
      expect(
        filter.shouldLog(
          LogEvent(Level.info, 'test', error: null, stackTrace: null),
        ),
        isTrue,
      );
    });
  });
}
