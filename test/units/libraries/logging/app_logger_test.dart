import 'package:construculator/libraries/logging/app_logger.dart';
import 'package:construculator/libraries/logging/testing/fake_logger_wrapper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';

void main() {
  group('AppLogger', () {
    late AppLogger logger;
    late FakeLoggerWrapper internalTestLogger; // The logger instance we inject

    setUp(() {
      internalTestLogger = FakeLoggerWrapper();
      logger = AppLogger(internalLogger: internalTestLogger);
      Logger.level = Level.all; // Ensure all levels are processed by the logger system
    });

    tearDown(() {
      internalTestLogger.clear();
    });

    test('logger uses default tag and emoji when none provided', () {
      logger = AppLogger(internalLogger: internalTestLogger);
      logger.info('Test message');
      expect(internalTestLogger.iMessages.length, 1);
      final event = internalTestLogger.iMessages.first;
      expect(event['message'], '[Construculator] Test message');
    });
    test('tag() returns a new logger with the updated tag', () {
      final taggedLogger = logger.tag('NewTag');
      taggedLogger.info('Tagged message');

      expect(internalTestLogger.iMessages.length, 1);
      final event = internalTestLogger.iMessages.first;
      expect(event['message'], '[NewTag] Tagged message');

      // Original logger should still use its original tag
      internalTestLogger.clear();
      logger.info('Original logger message');
      expect(internalTestLogger.iMessages.length, 1);
      final originalEvent = internalTestLogger.iMessages.first;
      expect(
        originalEvent['message'],
        '[Construculator] Original logger message',
      );
    });

    test('emoji() returns a new logger with the updated emoji', () {
      final emojiLogger = logger.emoji('🚀');
      emojiLogger.info('Emoji message');

      expect(internalTestLogger.iMessages.length, 1);
      final event = internalTestLogger.iMessages.first;
      expect(event['message'], '🚀 [Construculator] Emoji message');

      // Original logger should still use its original emoji
      internalTestLogger.clear();
      logger.info('Original logger message');
      expect(internalTestLogger.iMessages.length, 1);
      final originalEvent = internalTestLogger.iMessages.first;
      expect(
        originalEvent['message'],
        '[Construculator] Original logger message',
      );
    });

    test('tag() and emoji() can be chained', () {
      final customLogger = logger.tag('ChainedTag').emoji('🔗');
      customLogger.info('Chained message');

      expect(internalTestLogger.iMessages.length, 1);
      final event = internalTestLogger.iMessages.first;
      expect(event['message'], '🔗 [ChainedTag] Chained message');
    });

    group('Logging methods', () {
      test('info() logs with info level and correct format', () {
        logger.info('Info test');
        expect(internalTestLogger.iMessages.length, 1);
        final event = internalTestLogger.iMessages.first;
        expect(event['message'], '[Construculator] Info test');
      });

      test('warning() logs with warning level and correct format', () {
        logger.warning('Warning test');
        expect(internalTestLogger.wMessages.length, 1);
        final event = internalTestLogger.wMessages.first;
        expect(event['message'], '[Construculator] Warning test');
      });

      test('error() logs with error level and correct format', () {
        logger.error('Error test');
        expect(internalTestLogger.eMessages.length, 1);
        final event = internalTestLogger.eMessages.first;
        expect(event['message'], '[Construculator] Error test');
      });

      test('error() logs with error object and stackTrace', () {
        final e = Exception('Test Exception');
        final s = StackTrace.current;
        logger.error('Error with details', e, s);
        expect(internalTestLogger.eMessages.length, 1);
        final event = internalTestLogger.eMessages.first;
        expect(event['message'], '[Construculator] Error with details');
        expect(event['error'], e);
        expect(event['stackTrace'], s);
        // Checking for a specific part of the stack trace might be brittle,
        // but we can check that stack trace output exists.
        expect(event['stackTrace'].toString(), contains('app_logger_test.dart'));
      });

      test('debug() logs with debug level and correct format', () {
        logger.debug('Debug test');
        expect(internalTestLogger.dMessages.length, 1);
        final event = internalTestLogger.dMessages.first;
        expect(event['message'], '[Construculator] Debug test');
      });

      test('omg() logs with fatal level and correct format', () {
        logger.omg('OMG test');
        expect(internalTestLogger.fMessages.length, 1);
        final event = internalTestLogger.fMessages.first;
        expect(event['message'], '[Construculator] OMG test');
      });

      test('omg() logs with error object and stackTrace', () {
        final e = Exception('OMG Exception');
        final s = StackTrace.current;
        logger.omg('OMG with details', e, s);
        expect(internalTestLogger.fMessages.length, 1);
        final event = internalTestLogger.fMessages.first;
        expect(event['message'], '[Construculator] OMG with details');
        expect(event['error'], e);
        expect(event['stackTrace'], s);
        expect(event['stackTrace'].toString(), contains('app_logger_test.dart'));
      });

      test('wtf() logs with fatal level and correct format', () {
        logger.wtf('WTF test');
        expect(internalTestLogger.fMessages.length, 1);
        final event = internalTestLogger.fMessages.first;
        expect(event['message'], '[Construculator] WTF test');
      });

      test('wtf() logs with error object and stackTrace', () {
        final e = Exception('WTF Exception');
        final s = StackTrace.current;
        logger.wtf('WTF with details', e, s);
        expect(internalTestLogger.fMessages.length, 1);
        final event = internalTestLogger.fMessages.first;
        expect(event['message'], '[Construculator] WTF with details');
        expect(event['error'], e);
        expect(event['stackTrace'], s);
        expect(event['stackTrace'].toString(), contains('app_logger_test.dart'));
      });
    });
  });
}
