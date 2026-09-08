import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/libraries/analytics/domain/repositories/feature_flag_repository.dart';
import 'package:flutter_modular/flutter_modular.dart';

/// Modular module that exposes [FeatureFlagRepository] for DI.
class FeatureFlagModule extends Module {
  final AppBootstrap appBootstrap;
  FeatureFlagModule(this.appBootstrap);

  @override
  void exportedBinds(Injector i) {
    i.addLazySingleton<FeatureFlagRepository>(
      () => appBootstrap.featureFlagRepository,
    );
  }
}
