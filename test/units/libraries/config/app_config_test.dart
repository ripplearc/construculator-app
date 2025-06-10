import 'package:construculator/libraries/config/env_constants.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:construculator/libraries/config/app_config_impl.dart';
import 'package:construculator/libraries/config/testing/fake_env_loader.dart';

void main() {
  group('AppConfig', () {
    group('App Config Initialization Tests', () {
      late FakeEnvLoader fakeDotEnvLoader;
      late AppConfigImpl appConfig;

      setUp(() {
        fakeDotEnvLoader = FakeEnvLoader();

        appConfig = AppConfigImpl(envLoader: fakeDotEnvLoader);
      });

      tearDown(() {
        fakeDotEnvLoader.reset();
      });

      test('should initialize successfully for dev environment', () async {
        fakeDotEnvLoader.setEnvVar('APP_NAME', 'TestApp');
        fakeDotEnvLoader.setEnvVar('API_URL', 'https://dev-api.com');
        fakeDotEnvLoader.setEnvVar('SUPABASE_URL', 'https://dev.supabase.co');
        fakeDotEnvLoader.setEnvVar('SUPABASE_ANON_KEY', 'dev-key');

        await appConfig.initialize(Environment.dev);

        expect(appConfig.environment, equals(Environment.dev));
        expect(appConfig.baseAppName, equals('TestApp'));
        expect(appConfig.appName, equals('TestApp (Fishfood)'));
        expect(appConfig.debugFeaturesEnabled, isTrue);
        expect(appConfig.isDev, isTrue);
        expect(appConfig.isQa, isFalse);
        expect(appConfig.isProd, isFalse);

        expect(
          fakeDotEnvLoader.lastLoadedFileName,
          equals('assets/env/.env.dev'),
        );
        expect(
          fakeDotEnvLoader.get('SUPABASE_URL'),
          equals('https://dev.supabase.co'),
        );
        expect(fakeDotEnvLoader.get('SUPABASE_ANON_KEY'), equals('dev-key'));
      });

      test('should initialize successfully for qa environment', () async {
        fakeDotEnvLoader.setEnvVar('APP_NAME', 'QAApp');
        fakeDotEnvLoader.setEnvVar('API_URL', 'https://qa-api.com');
        fakeDotEnvLoader.setEnvVar('SUPABASE_URL', 'https://qa.supabase.co');
        fakeDotEnvLoader.setEnvVar('SUPABASE_ANON_KEY', 'qa-key');

        await appConfig.initialize(Environment.qa);

        expect(appConfig.environment, equals(Environment.qa));
        expect(appConfig.baseAppName, equals('QAApp'));
        expect(appConfig.appName, equals('QAApp (Dogfood)'));
        expect(appConfig.debugFeaturesEnabled, isTrue);
        expect(appConfig.isQa, isTrue);
        expect(appConfig.isDev, isFalse);
        expect(appConfig.isProd, isFalse);

        expect(
          fakeDotEnvLoader.lastLoadedFileName,
          equals('assets/env/.env.qa'),
        );
        expect(
          fakeDotEnvLoader.get('SUPABASE_URL'),
          equals('https://qa.supabase.co'),
        );
        expect(fakeDotEnvLoader.get('SUPABASE_ANON_KEY'), equals('qa-key'));
      });

      test('should initialize successfully for prod environment', () async {
        fakeDotEnvLoader.setEnvVar('APP_NAME', 'ProdApp');
        fakeDotEnvLoader.setEnvVar('API_URL', 'https://prod-api.com');
        fakeDotEnvLoader.setEnvVar('SUPABASE_URL', 'https://prod.supabase.co');
        fakeDotEnvLoader.setEnvVar('SUPABASE_ANON_KEY', 'prod-key');

        await appConfig.initialize(Environment.prod);

        expect(appConfig.environment, equals(Environment.prod));
        expect(appConfig.baseAppName, equals('ProdApp'));
        expect(appConfig.appName, equals('ProdApp'));
        expect(appConfig.debugFeaturesEnabled, isFalse);
        expect(appConfig.isProd, isTrue);

        expect(
          fakeDotEnvLoader.lastLoadedFileName,
          equals('assets/env/.env.prod'),
        );
        expect(
          fakeDotEnvLoader.get('SUPABASE_URL'),
          equals('https://prod.supabase.co'),
        );
        expect(fakeDotEnvLoader.get('SUPABASE_ANON_KEY'), equals('prod-key'));
      });
    });

    group('Environment Name Tests', () {
      test('should return correct environment names', () {
        final appConfig = AppConfigImpl(envLoader: FakeEnvLoader());

        expect(
          appConfig.getEnvironmentName(Environment.dev),
          equals('Development'),
        );
        expect(appConfig.getEnvironmentName(Environment.qa), equals('QA'));
        expect(
          appConfig.getEnvironmentName(Environment.prod),
          equals('Production'),
        );
      });
      test('should return correct environment aliases', () {
        final appConfig = AppConfigImpl(envLoader: FakeEnvLoader());

        expect(
          appConfig.getEnvironmentName(Environment.dev, isAlias: true),
          equals('Fishfood'),
        );
        expect(
          appConfig.getEnvironmentName(Environment.qa, isAlias: true),
          equals('Dogfood'),
        );
        expect(
          appConfig.getEnvironmentName(Environment.prod, isAlias: true),
          equals(''),
        );
      });
    });

    group('App Config Functionality Tests', () {
      late FakeEnvLoader fakeDotEnvLoader;
      late AppConfigImpl appConfig;

      setUp(() {
        fakeDotEnvLoader = FakeEnvLoader();

        appConfig = AppConfigImpl(envLoader: fakeDotEnvLoader);
      });

      tearDown(() {
        fakeDotEnvLoader.reset();
      });

      group('Default Values Handling', () {
        test('should use default values when env vars are null', () async {
          fakeDotEnvLoader.setEnvVar(
            'SUPABASE_URL',
            'https://test.supabase.co',
          );
          fakeDotEnvLoader.setEnvVar('SUPABASE_ANON_KEY', 'test-key');

          await appConfig.initialize(Environment.dev);

          expect(appConfig.baseAppName, equals('Construculator'));
          expect(appConfig.appName, equals('Construculator (Fishfood)'));
        });
      });

      group('Environment File Loading', () {
        test(
          'should load correct env file for each environment and log it',
          () async {
            final environments = [
              Environment.dev,
              Environment.qa,
              Environment.prod,
            ];
            final expectedFullPaths = [
              'assets/env/.env.dev',
              'assets/env/.env.qa',
              'assets/env/.env.prod',
            ];

            for (int i = 0; i < environments.length; i++) {
              final freshFakeDotEnvLoader = FakeEnvLoader();
              final freshConfig = AppConfigImpl(
                envLoader: freshFakeDotEnvLoader,
              );
              freshFakeDotEnvLoader.setEnvVar(
                'SUPABASE_URL',
                'https://test.supabase.co',
              );
              freshFakeDotEnvLoader.setEnvVar('SUPABASE_ANON_KEY', 'test-key');

              await freshConfig.initialize(environments[i]);

              expect(
                freshFakeDotEnvLoader.lastLoadedFileName,
                equals(expectedFullPaths[i]),
              );
            }
          },
        );
      });

      group('Environment Getters', () {
        setUp(() {
          // Re-init appConfig for this group if needed, or ensure it's fresh.
          // For these tests, AppConfig needs to be initialized.
          fakeDotEnvLoader.setEnvVar(
            'SUPABASE_URL',
            'https://test.supabase.co',
          );
          fakeDotEnvLoader.setEnvVar('SUPABASE_ANON_KEY', 'test-key');
        });

        test('should return correct values for dev environment', () async {
          await appConfig.initialize(Environment.dev);
          expect(appConfig.isDev, isTrue);
          expect(appConfig.isQa, isFalse);
          expect(appConfig.isProd, isFalse);
        });
        test('should return correct values for qa environment', () async {
          await appConfig.initialize(Environment.qa);
          expect(appConfig.isDev, isFalse);
          expect(appConfig.isQa, isTrue);
          expect(appConfig.isProd, isFalse);
        });
        test('should return correct values for prod environment', () async {
          await appConfig.initialize(Environment.prod);
          expect(appConfig.isDev, isFalse);
          expect(appConfig.isQa, isFalse);
          expect(appConfig.isProd, isTrue);
        });
      });

      group('App Name Formatting', () {
        test('should format app name correctly for each environment', () async {
          final testCases = [
            (Environment.dev, 'DevApp', 'DevApp (Fishfood)'),
            (Environment.qa, 'QAApp', 'QAApp (Dogfood)'),
            (Environment.prod, 'ProdApp', 'ProdApp'),
          ];

          for (final testCase in testCases) {
            final freshFakeDotEnvLoader = FakeEnvLoader();
            final freshConfig = AppConfigImpl(envLoader: freshFakeDotEnvLoader);

            freshFakeDotEnvLoader.setEnvVar('APP_NAME', testCase.$2);
            freshFakeDotEnvLoader.setEnvVar('API_URL', 'https://api.com');
            freshFakeDotEnvLoader.setEnvVar(
              'SUPABASE_URL',
              'https://test.supabase.co',
            );
            freshFakeDotEnvLoader.setEnvVar('SUPABASE_ANON_KEY', 'test-key');

            await freshConfig.initialize(testCase.$1);

            expect(freshConfig.baseAppName, equals(testCase.$2));
            expect(freshConfig.appName, equals(testCase.$3));
          }
        });
      });

      group('Debug Features Configuration', () {
        test(
          'should set debug features correctly for each environment',
          () async {
            final testCases = [
              (Environment.dev, true),
              (Environment.qa, true),
              (Environment.prod, false),
            ];

            for (final testCase in testCases) {
              final freshFakeDotEnvLoader = FakeEnvLoader();
              final freshConfig = AppConfigImpl(
                envLoader: freshFakeDotEnvLoader,
              );

              // Arrange: Set necessary vars for initialization to succeed
              freshFakeDotEnvLoader.setEnvVar('APP_NAME', 'TestApp');
              freshFakeDotEnvLoader.setEnvVar('API_URL', 'https://api.com');
              freshFakeDotEnvLoader.setEnvVar(
                'SUPABASE_URL',
                'https://test.supabase.co',
              );
              freshFakeDotEnvLoader.setEnvVar('SUPABASE_ANON_KEY', 'test-key');

              // Act
              await freshConfig.initialize(testCase.$1);

              // Assert
              expect(freshConfig.debugFeaturesEnabled, equals(testCase.$2));

              // Verify debug flag is passed correctly to Supabase
              // (Supabase init is called during freshConfig.initialize)
              expect(
                freshFakeDotEnvLoader.get('SUPABASE_URL'),
                equals('https://test.supabase.co'),
              );
              expect(
                freshFakeDotEnvLoader.get('SUPABASE_ANON_KEY'),
                equals('test-key'),
              );
            }
          },
        );
      });

      group('Environment Variable Input Handling', () {
        setUp(() {
          fakeDotEnvLoader = FakeEnvLoader();
          appConfig = AppConfigImpl(envLoader: fakeDotEnvLoader);
          // Required for successful initialization in sub-tests
          fakeDotEnvLoader.setEnvVar(
            'SUPABASE_URL',
            'https://test.supabase.co',
          );
          fakeDotEnvLoader.setEnvVar('SUPABASE_ANON_KEY', 'test-key');
        });

        test('should handle empty environment variables', () async {
          fakeDotEnvLoader.setEnvVar('APP_NAME', '');
          fakeDotEnvLoader.setEnvVar('API_URL', '');
          await appConfig.initialize(Environment.dev);
          expect(appConfig.baseAppName, equals(''));
        });

        test('should handle very long environment variable values', () async {
          final longAppName = 'A' * 1000;
          final longApiUrl = 'https://${'a' * 1000}.com';
          fakeDotEnvLoader.setEnvVar('APP_NAME', longAppName);
          fakeDotEnvLoader.setEnvVar('API_URL', longApiUrl);
          await appConfig.initialize(Environment.dev);
          expect(appConfig.baseAppName, equals(longAppName));
        });

        test(
          'should handle special characters in environment variables',
          () async {
            fakeDotEnvLoader.setEnvVar('APP_NAME', 'Test-App_123!@#');
            fakeDotEnvLoader.setEnvVar(
              'API_URL',
              'https://api-test_123.com/path?param=value&other=123',
            );
            await appConfig.initialize(Environment.dev);
            expect(appConfig.baseAppName, equals('Test-App_123!@#'));
          },
        );
      });
    });
  });
}
