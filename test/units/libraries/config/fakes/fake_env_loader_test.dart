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
      test('setEnvVar correctly stores a variable and get retrieves it', () {
        fakeLoader.setEnvVar('TEST_KEY', 'test_value');
        final result = fakeLoader.get('TEST_KEY');
        expect(result, equals('test_value'));
      });

      test('get returns null for a non-existent environment variable', () {
        final result = fakeLoader.get('NON_EXISTENT_KEY');
        expect(result, isNull);
      });

      test('setEnvVar and get handle null values correctly', () {
        fakeLoader.setEnvVar('NULL_KEY', null);
        final result = fakeLoader.get('NULL_KEY');
        expect(result, isNull);
      });

      test('setEnvVar overrides an existing environment variable', () {
        fakeLoader.setEnvVar('OVERRIDE_KEY', 'original_value');
        fakeLoader.setEnvVar('OVERRIDE_KEY', 'new_value');
        final result = fakeLoader.get('OVERRIDE_KEY');
        expect(result, equals('new_value'));
      });

      test('clearEnvVars removes all stored environment variables', () {
        fakeLoader.setEnvVar('CLEAR_KEY', 'value');
        expect(fakeLoader.get('CLEAR_KEY'), equals('value'));

        fakeLoader.clearEnvVars();
        expect(fakeLoader.get('CLEAR_KEY'), isNull);
      });
    });

    group('Load Method Behavior', () {
      test('load executes successfully when not configured to throw', () async {
        expect(
          () async => await fakeLoader.load(),
          returnsNormally,
        );
      });

      test('load captures the provided filename when one is given', () async {
        await fakeLoader.load(fileName: '.env.test');
        expect(fakeLoader.lastLoadedFileName, equals('.env.test'));
      });

      test('load sets lastLoadedFileName to null if no filename is provided', () async {
        await fakeLoader.load();
        expect(fakeLoader.lastLoadedFileName, isNull);
      });

      test('load throws a custom exception when configured to fail', () async {
        fakeLoader.shouldThrowOnLoad = true;
        fakeLoader.loadErrorMessage = 'Failed to load .env file';

        expect(
          () async => await fakeLoader.load(),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Failed to load .env file'),
          )),
        );
      });

      test('load throws a default error message if configured to fail without a custom message', () async {
        fakeLoader.shouldThrowOnLoad = true;
        // No custom message is set here
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
      test('reset clears all configurations, data, and error states', () async {
        fakeLoader.setEnvVar('TEST_KEY', 'test_value');
        fakeLoader.shouldThrowOnLoad = true;
        fakeLoader.loadErrorMessage = 'Custom error';
        await fakeLoader.load(fileName: '.env.test').catchError((_) {}); // Attempt load to set lastLoadedFileName

        fakeLoader.reset();

        expect(fakeLoader.get('TEST_KEY'), isNull);
        expect(fakeLoader.shouldThrowOnLoad, isFalse);
        expect(fakeLoader.loadErrorMessage, isNull);
        expect(fakeLoader.lastLoadedFileName, isNull);
      });

      test('allows normal operations after a reset from a throwing state', () async {
        fakeLoader.shouldThrowOnLoad = true;
        fakeLoader.reset();

        expect(
          () async => await fakeLoader.load(fileName: '.env.production'),
          returnsNormally
        );
        expect(fakeLoader.lastLoadedFileName, equals('.env.production'));
      });
    });

    group('Handling Multiple and Special Environment Variables', () {
      test('correctly sets and gets multiple environment variables', () {
        final envVars = {
          'API_URL': 'https://api.example.com',
          'API_KEY': 'secret_key_123',
          'DEBUG_MODE': 'true',
          'PORT': '3000',
        };

        envVars.forEach((key, value) {
          fakeLoader.setEnvVar(key, value);
        });

        envVars.forEach((key, expectedValue) {
          expect(fakeLoader.get(key), equals(expectedValue));
        });
      });

      test('correctly handles empty string values for environment variables', () {
        fakeLoader.setEnvVar('EMPTY_KEY', '');
        final result = fakeLoader.get('EMPTY_KEY');
        expect(result, equals(''));
      });
    });
  });
} 