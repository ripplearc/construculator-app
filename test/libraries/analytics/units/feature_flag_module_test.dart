import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/libraries/analytics/domain/repositories/feature_flag_repository.dart';
import 'package:construculator/libraries/analytics/feature_flag_module.dart';
import 'package:construculator/libraries/analytics/testing/fake_feature_flag_repository.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/fake_app_bootstrap_factory.dart';

class _FeatureFlagModuleTestHarness extends Module {
  final AppBootstrap appBootstrap;
  _FeatureFlagModuleTestHarness(this.appBootstrap);

  @override
  List<Module> get imports => [FeatureFlagModule(appBootstrap)];
}

void main() {
  group('FeatureFlagModule', () {
    tearDown(() {
      Modular.destroy();
    });

    test('registers the FeatureFlagRepository from AppBootstrap', () {
      final repository = FakeFeatureFlagRepository();
      final bootstrap = FakeAppBootstrapFactory.create(
        featureFlagRepository: repository,
      );

      Modular.init(_FeatureFlagModuleTestHarness(bootstrap));

      expect(Modular.get<FeatureFlagRepository>(), same(repository));
    });
  });
}
