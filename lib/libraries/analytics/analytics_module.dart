import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/libraries/analytics/domain/repositories/analytics_repository.dart';
import 'package:flutter_modular/flutter_modular.dart';

class AnalyticsModule extends Module {
  final AppBootstrap appBootstrap;
  AnalyticsModule(this.appBootstrap);
  @override
  void exportedBinds(Injector i) {
    i.addLazySingleton<AnalyticsRepository>(() => appBootstrap.analyticsRepository);
  }
}
