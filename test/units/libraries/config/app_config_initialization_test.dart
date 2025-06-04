import 'package:construculator/libraries/config/env_constants.dart';
import 'package:construculator/libraries/logging/testing/fake_logger_wrapper.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_initializer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:construculator/libraries/config/app_config.dart';
import 'package:construculator/libraries/logging/testing/test_app_logger.dart';
import 'package:construculator/libraries/config/testing/fake_env_loader.dart';

void main() {
  group('App Config Initialization Tests', () {
      late FakeEnvLoader fakeDotEnvLoader;
      late FakeSupabaseInitializer fakeSupabaseInitializer;
      late TestAppLogger testAppLogger;
      late AppConfig appConfig;

      setUp(() {
        fakeDotEnvLoader = FakeEnvLoader();
        fakeSupabaseInitializer = FakeSupabaseInitializer();
        testAppLogger = TestAppLogger(internalLogger: FakeLoggerWrapper());

        appConfig = AppConfig(
          dotEnvLoader: fakeDotEnvLoader,
          supabaseInitializer: fakeSupabaseInitializer,
          logger: testAppLogger,
        );
      });

      tearDown(() {
        fakeDotEnvLoader.reset();
        fakeSupabaseInitializer.reset();
        testAppLogger.clear();
      });

       test('should initialize successfully for dev environment', () async {
          fakeDotEnvLoader.setEnvVar('APP_NAME', 'TestApp');
          fakeDotEnvLoader.setEnvVar('API_URL', 'https://dev-api.com');
          fakeDotEnvLoader.setEnvVar('SUPABASE_URL', 'https://dev.supabase.co');
          fakeDotEnvLoader.setEnvVar('SUPABASE_ANON_KEY', 'dev-key');

          await appConfig.initialize(Environment.dev);

          expect(appConfig.environment, equals(Environment.dev));
          expect(appConfig.baseAppName, equals('TestApp'));
          expect(appConfig.apiUrl, equals('https://dev-api.com'));
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
            fakeSupabaseInitializer.lastUrl,
            equals('https://dev.supabase.co'),
          );
          expect(fakeSupabaseInitializer.lastAnonKey, equals('dev-key'));
          expect(fakeSupabaseInitializer.lastDebugFlag, isTrue);
          expect(appConfig.supabaseClient, isNotNull);
        });

        test('should initialize successfully for qa environment', () async {
          fakeDotEnvLoader.setEnvVar('APP_NAME', 'QAApp');
          fakeDotEnvLoader.setEnvVar('API_URL', 'https://qa-api.com');
          fakeDotEnvLoader.setEnvVar('SUPABASE_URL', 'https://qa.supabase.co');
          fakeDotEnvLoader.setEnvVar('SUPABASE_ANON_KEY', 'qa-key');

          await appConfig.initialize(Environment.qa);

          expect(appConfig.environment, equals(Environment.qa));
          expect(appConfig.baseAppName, equals('QAApp'));
          expect(appConfig.apiUrl, equals('https://qa-api.com'));
          expect(appConfig.appName, equals('QAApp (Dogfood)'));
          expect(appConfig.debugFeaturesEnabled, isTrue);
          expect(appConfig.isQa, isTrue);
          expect(appConfig.isDev, isFalse);
          expect(appConfig.isProd, isFalse);
          expect(appConfig.supabaseClient, isNotNull);

          expect(
            fakeDotEnvLoader.lastLoadedFileName,
            equals('assets/env/.env.qa'),
          );
          expect(
            fakeSupabaseInitializer.lastUrl,
            equals('https://qa.supabase.co'),
          );
          expect(fakeSupabaseInitializer.lastAnonKey, equals('qa-key'));
          expect(fakeSupabaseInitializer.lastDebugFlag, isTrue);
        });

        test('should initialize successfully for prod environment', () async {
          fakeDotEnvLoader.setEnvVar('APP_NAME', 'ProdApp');
          fakeDotEnvLoader.setEnvVar('API_URL', 'https://prod-api.com');
          fakeDotEnvLoader.setEnvVar(
            'SUPABASE_URL',
            'https://prod.supabase.co',
          );
          fakeDotEnvLoader.setEnvVar('SUPABASE_ANON_KEY', 'prod-key');

          await appConfig.initialize(Environment.prod);

          expect(appConfig.environment, equals(Environment.prod));
          expect(appConfig.baseAppName, equals('ProdApp'));
          expect(appConfig.apiUrl, equals('https://prod-api.com'));
          expect(appConfig.appName, equals('ProdApp'));
          expect(appConfig.debugFeaturesEnabled, isFalse);
          expect(appConfig.isProd, isTrue);
          expect(appConfig.supabaseClient, isNotNull);

          expect(
            fakeDotEnvLoader.lastLoadedFileName,
            equals('assets/env/.env.prod'),
          );
          expect(
            fakeSupabaseInitializer.lastUrl,
            equals('https://prod.supabase.co'),
          );
          expect(fakeSupabaseInitializer.lastAnonKey, equals('prod-key'));
          expect(fakeSupabaseInitializer.lastDebugFlag, isFalse);
        });

 });
  
}
