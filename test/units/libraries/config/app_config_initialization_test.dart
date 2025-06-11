import 'package:construculator/libraries/config/env_constants.dart';
<<<<<<< HEAD
=======
<<<<<<< HEAD
<<<<<<< HEAD
=======
import 'package:construculator/libraries/config/testing/fake_supabase_initializer.dart';
>>>>>>> ec9afe0 (Move supabase initializer to config)
=======
import 'package:construculator/libraries/supabase/testing/fake_supabase_initializer.dart';
>>>>>>> 75661ee (Refactor)
>>>>>>> 596e4ad (Fix restack errors)
import 'package:flutter_test/flutter_test.dart';
import 'package:construculator/libraries/config/app_config_impl.dart';
import 'package:construculator/libraries/config/testing/fake_env_loader.dart';

void main() {
  group('App Config Initialization Tests', () {
      late FakeEnvLoader fakeDotEnvLoader;
      late AppConfigImpl appConfig;

      setUp(() {
        fakeDotEnvLoader = FakeEnvLoader();

        appConfig = AppConfigImpl(
          envLoader: fakeDotEnvLoader,
        );
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
          fakeDotEnvLoader.setEnvVar(
            'SUPABASE_URL',
            'https://prod.supabase.co',
          );
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
  
}
