import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/libraries/analytics/analytics_module.dart';
import 'package:construculator/libraries/analytics/data/repositories/no_op_analytics_repository.dart';
import 'package:construculator/libraries/analytics/domain/repositories/analytics_repository.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/fake_app_bootstrap_factory.dart';

class _AnalyticsModuleTestHarness extends Module {
  final AppBootstrap appBootstrap;
  _AnalyticsModuleTestHarness(this.appBootstrap);

  @override
  List<Module> get imports => [AnalyticsModule(appBootstrap)];
}

void main() {
  group('AnalyticsModule', () {
    tearDown(() {
      Modular.destroy();
    });

    test('registers the AnalyticsRepository from AppBootstrap', () {
      const repository = NoOpAnalyticsRepository();
      final bootstrap = FakeAppBootstrapFactory.create(
        analyticsRepository: repository,
      );

      Modular.init(_AnalyticsModuleTestHarness(bootstrap));

      expect(Modular.get<AnalyticsRepository>(), same(repository));
    });
  });
}
