import 'package:construculator/libraries/logging/testing/fake_logger_wrapper.dart';
import 'package:construculator/libraries/logging/testing/test_app_logger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TestAppLogger', () {
    late TestAppLogger logger;

    setUp(() {
      logger = TestAppLogger(internalLogger: FakeLoggerWrapper());
    });

    tearDown(() {
      logger.reset();
    });

    // Helper to format message as TestAppLogger would by default
    String defaultFormat(String message, {String tag = 'FakeLogger', String? emoji}) {
      String prefix = '';
      if (emoji != null && emoji.isNotEmpty) {
        prefix += '$emoji ';
      }
      prefix += '[$tag]';
      return '$prefix $message';
    }

    group('Logging Methods', () {
      test('should log info messages to infoMessages list', () {
        logger.info('Test info message');
        expect(logger.internalLogger.iMessages.first['message'], contains(defaultFormat('Test info message')));
      });

      test('should log to respective message lists (info, warning, error, debug, wtf, omg)', () {
        logger.info('Info');
        logger.warning('Warning');
        logger.error('Error');
        logger.debug('Debug');
        // WTF and OMG are logged to the same list due to limitations of the underlying logger package.
        // FakeLoggerWrapper implements an interface that is subjected to the same limitations.
        // So we need to check the first and last messages for WTF and OMG respectively.
        logger.wtf('WTF');
        logger.omg('OMG');

        expect(logger.internalLogger.iMessages.first['message'], contains(defaultFormat('Info')));
        expect(logger.internalLogger.wMessages.first['message'], contains(defaultFormat('Warning')));
        expect(logger.internalLogger.eMessages.first['message'], contains(defaultFormat('Error')));
        expect(logger.internalLogger.dMessages.first['message'], contains(defaultFormat('Debug')));
        expect(logger.internalLogger.fMessages.first['message'], contains(defaultFormat('WTF')));
        expect(logger.internalLogger.fMessages.last['message'], contains(defaultFormat('OMG')));
      });

      test('should log multiple info messages', () {
        logger.info('First message');
        logger.info('Second message');
        logger.info('Third message');

        expect(logger.internalLogger.iMessages.length, equals(3));
        expect(logger.internalLogger.iMessages[0]['message'], equals(defaultFormat('First message')));
        expect(logger.internalLogger.iMessages[1]['message'], equals(defaultFormat('Second message')));
        expect(logger.internalLogger.iMessages[2]['message'], equals(defaultFormat('Third message')));
      });

      test('should check if a specific formatted message was logged in infoMessages', () {
        logger.info('Important log message');
        expect(logger.internalLogger.iMessages.first['message'], contains(defaultFormat('Important log message')));
        expect(logger.internalLogger.iMessages.first['message'], isNot(contains(defaultFormat('Not logged'))));
      });

      test('clear() should clear all logged messages from all lists', () {
        logger.info('Message 1');
        logger.warning('Message 2');
        logger.wtf('Message 3');
        logger.omg('Message 4');
        expect(logger.internalLogger.iMessages.isNotEmpty, isTrue);
        expect(logger.internalLogger.wMessages.isNotEmpty, isTrue);
        expect(logger.internalLogger.fMessages.isNotEmpty, isTrue);
        expect(logger.internalLogger.fMessages.isNotEmpty, isTrue);

        logger.clear();

        expect(logger.internalLogger.iMessages.isEmpty, isTrue);
        expect(logger.internalLogger.wMessages.isEmpty, isTrue);
        expect(logger.internalLogger.eMessages.isEmpty, isTrue);
        expect(logger.internalLogger.dMessages.isEmpty, isTrue);
        expect(logger.internalLogger.fMessages.isEmpty, isTrue);
        expect(logger.internalLogger.fMessages.isEmpty, isTrue);
      });
    });

    group('Reset Functionality', () {
      test('reset() should clear all messages and reset tag/emoji', () {
        var customizedLogger = logger.tag('OldTag').emoji('✨') as TestAppLogger;
        customizedLogger.info('Message before reset');
        customizedLogger.wtf('Another message');
        
        expect(customizedLogger.internalLogger.iMessages.first['message'], contains(defaultFormat('Message before reset', tag: 'OldTag', emoji: '✨')));
        expect(customizedLogger.internalLogger.fMessages.first['message'], contains(defaultFormat('Another message', tag: 'OldTag', emoji: '✨')));

        customizedLogger.reset(); 

        expect(customizedLogger.internalLogger.iMessages.isEmpty, isTrue);
        expect(customizedLogger.internalLogger.fMessages.isEmpty, isTrue);
        expect(customizedLogger.currentTag, equals('FakeLogger')); 
        expect(customizedLogger.currentEmojiPrefix, isEmpty);
      });

      test('should allow normal operation after reset', () {
        var loggerInstance = logger.tag('OldTag') as TestAppLogger;
        loggerInstance.info('Before reset');
        loggerInstance.reset();
        loggerInstance.info('After reset'); // Logs with default tag 'FakeLogger' and null emoji

        expect(loggerInstance.internalLogger.iMessages.length, equals(1));
        expect(loggerInstance.internalLogger.iMessages.first['message'], equals(defaultFormat('After reset', tag: 'FakeLogger'))); 
      });
    });

    group('Tagging and Emoji functionality', () {
      test('tag() should return a new logger with the specified tag', () {
        final taggedLogger = logger.tag('MyFeature') as TestAppLogger;
        taggedLogger.info('Feature message');
        expect(taggedLogger.internalLogger.iMessages.first['message'], contains(defaultFormat('Feature message', tag: 'MyFeature')));
        expect(logger.internalLogger.iMessages.isNotEmpty, isTrue); 
      });

      test('emoji() should return a new logger with the specified emoji', () {
        final emojiLogger = logger.emoji('🎉') as TestAppLogger;
        emojiLogger.info('Party message');
        expect(emojiLogger.internalLogger.iMessages.first['message'], contains(defaultFormat('Party message', emoji: '🎉')));
        expect(logger.internalLogger.iMessages.isNotEmpty, isTrue);
      });

      test('tag() and emoji() can be chained', () {
        final specificLogger = logger.tag('Chain').emoji('🔗') as TestAppLogger;
        specificLogger.info('Chained log');
        expect(specificLogger.internalLogger.iMessages.first['message'], contains(defaultFormat('Chained log', tag: 'Chain', emoji: '🔗')));
        expect(logger.internalLogger.iMessages.isNotEmpty, isTrue);
      });

      test('fresh() logger instance is not affected by previous emoji', () {
        final emojiLogger = logger.emoji('✨') as TestAppLogger;
        final freshLogger = logger.fresh() as TestAppLogger;
        emojiLogger.info('Emoji Log');

        expect(emojiLogger.currentTag, equals('FakeLogger'));
        expect(emojiLogger.currentEmojiPrefix, '✨');

        expect(freshLogger.internalLogger.iMessages.first['message'], contains(defaultFormat('Emoji Log', emoji: '✨')));
        expect(freshLogger.currentTag, 'FakeLogger'); 
        expect(freshLogger.currentEmojiPrefix, isEmpty);
      });

       test('fresh() logger instance is not affected by previous tags', () {
        final taggedLogger = logger.tag('NewTag') as TestAppLogger;
        final emojiLogger = logger.fresh().emoji('✨') as TestAppLogger;
        taggedLogger.info('Tagged Log');
        emojiLogger.info('Emoji Log');

        expect(logger.currentTag, equals('FakeLogger'));
        expect(logger.currentEmojiPrefix, isEmpty);

        expect(taggedLogger.internalLogger.iMessages.first['message'], contains(defaultFormat('Tagged Log', tag: 'NewTag')));
        expect(taggedLogger.currentTag, 'NewTag');
        expect(taggedLogger.currentEmojiPrefix, isEmpty); 

        expect(emojiLogger.internalLogger.iMessages.last['message'], contains(defaultFormat('Emoji Log', emoji: '✨')));
        expect(emojiLogger.currentTag, 'FakeLogger'); 
        expect(emojiLogger.currentEmojiPrefix, '✨');
      });
    });

    group('Edge Cases for Logging Methods', () {
      test('should handle empty messages', () {
        logger.info('');
        logger.wtf('');
        expect(logger.internalLogger.iMessages.first['message'], contains(defaultFormat('')));
        expect(logger.internalLogger.fMessages.first['message'], contains(defaultFormat('')));
      });

      test('should handle very long messages', () {
        final longMessage = 'A' * 10000;
        logger.info(longMessage);
        logger.omg(longMessage);
        expect(logger.internalLogger.iMessages.first['message'], contains(defaultFormat(longMessage)));
        expect(logger.internalLogger.fMessages.first['message'], contains(defaultFormat(longMessage)));
      });

      test('should handle special characters', () {
        final specialMessage = 'Message with special chars: !@#\$%^&*()_+-=[]{}|;:,.<>?';
        logger.info(specialMessage);
        logger.wtf(specialMessage);
        expect(logger.internalLogger.iMessages.first['message'], contains(defaultFormat(specialMessage)));
        expect(logger.internalLogger.fMessages.first['message'], contains(defaultFormat(specialMessage)));
      });

      test('should handle unicode characters', () {
        final unicodeMessage = 'Unicode: 🚀 🎉 ✨ 中文 العربية';
        logger.info(unicodeMessage);
        logger.omg(unicodeMessage);
        expect(logger.internalLogger.iMessages.first['message'], contains(defaultFormat(unicodeMessage)));
        expect(logger.internalLogger.fMessages.first['message'], contains(defaultFormat(unicodeMessage)));
      });

      test('logging with errors and stackTraces', () {
        final error = Exception('Test Error');
        final stackTrace = StackTrace.current;
        logger.error('Error occurred', error, stackTrace);
        logger.wtf('WTF occurred', error, stackTrace);
        logger.omg('OMG occurred', error, stackTrace);
        logger.warning('Warning occurred', error, stackTrace);
        logger.debug('Debug occurred', error, stackTrace);
        logger.info('Info occurred', error, stackTrace);
         
        expect(logger.internalLogger.iMessages.first['message'], contains(defaultFormat('Info occurred')));
        expect(logger.internalLogger.dMessages.first['message'], contains(defaultFormat('Debug occurred')));
        expect(logger.internalLogger.wMessages.first['message'], contains(defaultFormat('Warning occurred')));
        expect(logger.internalLogger.eMessages.first['message'], contains(defaultFormat('Error occurred')));
        expect(logger.internalLogger.fMessages.first['message'], contains(defaultFormat('WTF occurred')));
        expect(logger.internalLogger.fMessages.last['message'], contains(defaultFormat('OMG occurred')));
        
        expect(logger.loggedErrors, contains(error));
        expect(logger.loggedStackTraces, contains(stackTrace));
        // Check count if multiple errors are logged
        expect(logger.loggedErrors.where((e) => e == error).length, 6);
        expect(logger.loggedStackTraces.where((st) => st == stackTrace).length, 6);
      });
    });
  });
} 