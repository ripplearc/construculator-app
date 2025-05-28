import 'package:flutter_test/flutter_test.dart';
import 'package:construculator_app_architecture/core/config/fakes/fake_app_config_dependencies.dart';

void main() {
  group('FakeDotEnvLoader', () {
    late FakeDotEnvLoader fakeLoader;

    setUp(() {
      fakeLoader = FakeDotEnvLoader();
    });

    tearDown(() {
      fakeLoader.reset();
    });

    group('Environment Variable Management', () {
      test('should set and get environment variables', () {
        // Arrange
        fakeLoader.setEnvVar('TEST_KEY', 'test_value');

        // Act
        final result = fakeLoader.get('TEST_KEY');

        // Assert
        expect(result, equals('test_value'));
      });

      test('should return null for non-existent environment variables', () {
        // Act
        final result = fakeLoader.get('NON_EXISTENT_KEY');

        // Assert
        expect(result, isNull);
      });

      test('should handle null values', () {
        // Arrange
        fakeLoader.setEnvVar('NULL_KEY', null);

        // Act
        final result = fakeLoader.get('NULL_KEY');

        // Assert
        expect(result, isNull);
      });

      test('should override existing environment variables', () {
        // Arrange
        fakeLoader.setEnvVar('OVERRIDE_KEY', 'original_value');
        fakeLoader.setEnvVar('OVERRIDE_KEY', 'new_value');

        // Act
        final result = fakeLoader.get('OVERRIDE_KEY');

        // Assert
        expect(result, equals('new_value'));
      });

      test('should clear environment variables', () {
        // Arrange
        fakeLoader.setEnvVar('CLEAR_KEY', 'value');
        expect(fakeLoader.get('CLEAR_KEY'), equals('value'));

        // Act
        fakeLoader.clearEnvVars();

        // Assert
        expect(fakeLoader.get('CLEAR_KEY'), isNull);
      });
    });

    group('Load Method', () {
      test('should load successfully when not configured to throw', () async {
        // Act & Assert
        expect(
          () async => await fakeLoader.load(),
          returnsNormally,
        );
      });

      test('should load with filename parameter', () async {
        // Act
        await fakeLoader.load(fileName: '.env.test');

        // Assert
        expect(fakeLoader.lastLoadedFileName, equals('.env.test'));
      });

      test('should load without filename parameter', () async {
        // Act
        await fakeLoader.load();

        // Assert
        expect(fakeLoader.lastLoadedFileName, isNull);
      });

      test('should throw exception when configured to fail', () async {
        // Arrange
        fakeLoader.shouldThrowOnLoad = true;
        fakeLoader.loadErrorMessage = 'Failed to load .env file';

        // Act & Assert
        expect(
          () async => await fakeLoader.load(),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Failed to load .env file'),
          )),
        );
      });

      test('should throw default error message when no custom message set', () async {
        // Arrange
        fakeLoader.shouldThrowOnLoad = true;

        // Act & Assert
        expect(
          () async => await fakeLoader.load(),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Failed to load env file'),
          )),
        );
      });
    });

    group('Reset Functionality', () {
      test('should reset all configuration and data', () async {
        // Arrange
        fakeLoader.setEnvVar('TEST_KEY', 'test_value');
        fakeLoader.shouldThrowOnLoad = true;
        fakeLoader.loadErrorMessage = 'Custom error';
        await fakeLoader.load(fileName: '.env.test').catchError((_) {});

        // Act
        fakeLoader.reset();

        // Assert
        expect(fakeLoader.get('TEST_KEY'), isNull);
        expect(fakeLoader.shouldThrowOnLoad, isFalse);
        expect(fakeLoader.loadErrorMessage, isNull);
        expect(fakeLoader.lastLoadedFileName, isNull);
      });

      test('should allow normal operation after reset', () async {
        // Arrange
        fakeLoader.shouldThrowOnLoad = true;
        fakeLoader.reset();

        // Act & Assert
        expect(
          () async => await fakeLoader.load(fileName: '.env.production'),
          returnsNormally,
        );
        expect(fakeLoader.lastLoadedFileName, equals('.env.production'));
      });
    });

    group('Multiple Environment Variables', () {
      test('should handle multiple environment variables', () {
        // Arrange
        final envVars = {
          'API_URL': 'https://api.example.com',
          'API_KEY': 'secret_key_123',
          'DEBUG_MODE': 'true',
          'PORT': '3000',
        };

        // Act
        envVars.forEach((key, value) {
          fakeLoader.setEnvVar(key, value);
        });

        // Assert
        envVars.forEach((key, expectedValue) {
          expect(fakeLoader.get(key), equals(expectedValue));
        });
      });

      test('should handle empty string values', () {
        // Arrange
        fakeLoader.setEnvVar('EMPTY_KEY', '');

        // Act
        final result = fakeLoader.get('EMPTY_KEY');

        // Assert
        expect(result, equals(''));
      });
    });
  });
  group('FakeLogger', () {
    late FakeLogger logger;

    setUp(() {
      logger = FakeLogger();
    });

    tearDown(() {
      logger.reset();
    });

    group('Logging Methods', () {
      test('should log info messages', () {
        // Act
        logger.info('Test info message');

        // Assert
        expect(logger.loggedMessages, contains('Test info message'));
        expect(logger.hasLoggedMessage('Test info message'), isTrue);
      });

      test('should log multiple messages', () {
        // Act
        logger.info('First message');
        logger.info('Second message');
        logger.info('Third message');

        // Assert
        expect(logger.loggedMessages.length, equals(3));
        expect(logger.loggedMessages[0], equals('First message'));
        expect(logger.loggedMessages[1], equals('Second message'));
        expect(logger.loggedMessages[2], equals('Third message'));
      });

      test('should check if message was logged', () {
        // Arrange
        logger.info('Important log message');

        // Act & Assert
        expect(logger.hasLoggedMessage('Important'), isTrue);
        expect(logger.hasLoggedMessage('log message'), isTrue);
        expect(logger.hasLoggedMessage('Important log message'), isTrue);
        expect(logger.hasLoggedMessage('Not logged'), isFalse);
      });

      test('should clear logged messages', () {
        // Arrange
        logger.info('Message 1');
        logger.info('Message 2');
        expect(logger.loggedMessages.length, equals(2));

        // Act
        logger.clearLogs();

        // Assert
        expect(logger.loggedMessages.length, equals(0));
        expect(logger.hasLoggedMessage('Message 1'), isFalse);
      });
    });

    group('Reset Functionality', () {
      test('should reset all logged messages', () {
        // Arrange
        logger.info('Test message 1');
        logger.info('Test message 2');
        expect(logger.loggedMessages.length, equals(2));

        // Act
        logger.reset();

        // Assert
        expect(logger.loggedMessages.length, equals(0));
        expect(logger.hasLoggedMessage('Test message 1'), isFalse);
        expect(logger.hasLoggedMessage('Test message 2'), isFalse);
      });

      test('should allow normal operation after reset', () {
        // Arrange
        logger.info('Before reset');
        logger.reset();

        // Act
        logger.info('After reset');

        // Assert
        expect(logger.loggedMessages.length, equals(1));
        expect(logger.loggedMessages[0], equals('After reset'));
        expect(logger.hasLoggedMessage('Before reset'), isFalse);
        expect(logger.hasLoggedMessage('After reset'), isTrue);
      });
    });

    group('Edge Cases', () {
      test('should handle empty messages', () {
        // Act
        logger.info('');

        // Assert
        expect(logger.loggedMessages, contains(''));
        expect(logger.hasLoggedMessage(''), isTrue);
      });

      test('should handle very long messages', () {
        // Arrange
        final longMessage = 'A' * 10000;

        // Act
        logger.info(longMessage);

        // Assert
        expect(logger.loggedMessages, contains(longMessage));
        expect(logger.hasLoggedMessage('A' * 100), isTrue);
      });

      test('should handle special characters', () {
        // Arrange
        final specialMessage = 'Message with special chars: !@#\$%^&*()_+-=[]{}|;:,.<>?';

        // Act
        logger.info(specialMessage);

        // Assert
        expect(logger.loggedMessages, contains(specialMessage));
        expect(logger.hasLoggedMessage('special chars'), isTrue);
      });

      test('should handle unicode characters', () {
        // Arrange
        final unicodeMessage = 'Unicode: 🚀 🎉 ✨ 中文 العربية';

        // Act
        logger.info(unicodeMessage);

        // Assert
        expect(logger.loggedMessages, contains(unicodeMessage));
        expect(logger.hasLoggedMessage('🚀'), isTrue);
      });
    });
  });
} 