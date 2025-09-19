import 'package:construculator/libraries/config/app_config_impl.dart';
import 'package:construculator/libraries/config/interfaces/config.dart';
import 'package:construculator/libraries/config/interfaces/env_loader.dart';
import 'package:construculator/libraries/config/testing/fake_app_config.dart';
import 'package:construculator/libraries/config/testing/fake_env_loader.dart';
import 'package:flutter_modular/flutter_modular.dart';

class ConfigTestModule extends Module {
  @override
  void exportedBinds(Injector i) {
    // FakeEnvLoader is added as a singleton because, an instance of the fake env loader is retrieved
    // to configure a specific behavior. If added as a factory, the instance the AppConfigImpl gets
    // is different from the one manipulated, causing tests to fail.
    i.addSingleton<EnvLoader>(() => FakeEnvLoader());
    i.add<Config>(() => FakeAppConfig(), key: 'fakeAppConfig');
    i.add<Config>(
      () => AppConfigImpl(envLoader: i()),
      key: 'appConfigWithFakeDep',
    );
  }
}
