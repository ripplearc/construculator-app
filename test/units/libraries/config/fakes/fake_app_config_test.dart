import 'package:construculator/libraries/config/testing/config_test_module.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:construculator/libraries/config/env_constants.dart';
import 'package:construculator/libraries/config/interfaces/config.dart';
import 'package:construculator/libraries/config/testing/fake_app_config.dart';

void main() {
  late FakeAppConfig fakeConfig;

  setUpAll(() {
    Modular.init(_TestAppModule());
    fakeConfig = Modular.get<Config>(key: 'fakeAppConfig') as FakeAppConfig;
  });

  tearDownAll(() {
    Modular.destroy();
  });

  group('FakeAppConfig', () {
    test('should have default values', () {
      expect(fakeConfig.environment, Environment.dev);
      expect(fakeConfig.appName, 'Construculator');
      expect(fakeConfig.baseAppName, 'Construculator');
      expect(fakeConfig.debugFeaturesEnabled, true);
    });

    test('should update environment and debug features in prod', () {
      fakeConfig.setEnvironment(Environment.prod);
      expect(fakeConfig.environment, Environment.prod);
      expect(fakeConfig.isProd, isTrue);
      expect(fakeConfig.debugFeaturesEnabled, isFalse);
    });

    test('should update environment and debug features in qa', () {
      fakeConfig.setEnvironment(Environment.qa);
      expect(fakeConfig.environment, Environment.qa);
      expect(fakeConfig.isQa, isTrue);
      expect(fakeConfig.debugFeaturesEnabled, isTrue);
    });
    test('should update environment and debug features in dev', () {
      fakeConfig.setEnvironment(Environment.dev);
      expect(fakeConfig.environment, Environment.dev);
      expect(fakeConfig.isDev, isTrue);
      expect(fakeConfig.debugFeaturesEnabled, isTrue);
    });
    test('initialize should throw an exception', () {
      expect(
        () async => await fakeConfig.initialize(Environment.dev),
        throwsA(
          isA<Exception>(),
        ),
      );
    });
    test('setAppName should update app name', () {
      const testName = 'Test App';
      fakeConfig.setAppName(testName);
      expect(fakeConfig.appName, testName);
    });

    test('setBaseAppName should update base app name', () {
      const testName = 'Test Base App';
      fakeConfig.setBaseAppName(testName);
      expect(fakeConfig.baseAppName, testName);
    });

    test('setDebugFeaturesEnabled should update debug features enabled', () {
      fakeConfig.setDebugFeaturesEnabled(false);
      expect(fakeConfig.debugFeaturesEnabled, false);
    });

    test('getEnvironmentName should return correct environment names', () {
      expect(fakeConfig.getEnvironmentName(Environment.dev), 'Development');
      expect(
        fakeConfig.getEnvironmentName(Environment.dev, isAlias: true),
        'Fishfood',
      );
      expect(fakeConfig.getEnvironmentName(Environment.qa), 'QA');
      expect(
        fakeConfig.getEnvironmentName(Environment.qa, isAlias: true),
        'Dogfood',
      );
      expect(fakeConfig.getEnvironmentName(Environment.prod), 'Production');
      expect(
        fakeConfig.getEnvironmentName(Environment.prod, isAlias: true),
        '',
      );
    });
  });
}

class _TestAppModule extends Module {
  @override
  List<Module> get imports => [ConfigTestModule()];
}
