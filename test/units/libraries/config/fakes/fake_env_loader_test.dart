import 'package:flutter_test/flutter_test.dart';
import 'package:construculator/libraries/config/testing/fake_env_loader.dart';

void main() {
  group('FakeEnvLoader', () {
    late FakeEnvLoader fakeLoader;

    setUp(() {
      fakeLoader = FakeEnvLoader();
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
} 