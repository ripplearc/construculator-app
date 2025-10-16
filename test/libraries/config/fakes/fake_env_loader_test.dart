import 'package:construculator/libraries/config/interfaces/env_loader.dart';
import 'package:construculator/libraries/config/testing/config_test_module.dart';
import 'package:construculator/libraries/errors/exceptions.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:construculator/libraries/config/testing/fake_env_loader.dart';

void main() {
  late FakeEnvLoader fakeLoader;

  setUp(() {
    Modular.init(_TestAppModule());
    fakeLoader = Modular.get<EnvLoader>() as FakeEnvLoader;
  });

  tearDown(() {
    Modular.destroy();
  });
  group('FakeEnvLoader', () {
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
        expect(() async => await fakeLoader.load(), returnsNormally);
      });

      test('load executes successfully with filename', () async {
        expect(
          () async => await fakeLoader.load(fileName: '.env.test'),
          returnsNormally,
        );
      });

      test('load throws exception when configured to fail', () async {
        fakeLoader.shouldThrowOnLoad = true;
        fakeLoader.loadErrorMessage = 'Failed to load .env file';

        expect(
          () async => await fakeLoader.load(),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Failed to load .env file'),
            ),
          ),
        );
      });

      test(
        'load throws with custom error message when configured to fail',
        () async {
          fakeLoader.loadErrorMessage = 'Failed to load env file';
          fakeLoader.shouldThrowOnLoad = true;
          expect(
            () async => await fakeLoader.load(),
            throwsA(
              isA<ConfigException>().having(
                (e) => e.message,
                'message',
                equals('Failed to load env file'),
              ),
            ),
          );
        },
      );
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

      test(
        'correctly handles empty string values for environment variables',
        () {
          fakeLoader.setEnvVar('EMPTY_KEY', '');

          final result = fakeLoader.get('EMPTY_KEY');

          expect(result, equals(''));
        },
      );
    });
  });
}

class _TestAppModule extends Module {
  @override
  List<Module> get imports => [ConfigTestModule()];
}
