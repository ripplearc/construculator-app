import 'package:construculator/libraries/config/config_module.dart';
import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:flutter_modular/flutter_modular.dart';

class SupabaseModule extends Module {
  final AppBootstrap appBootstrap;
  SupabaseModule(this.appBootstrap);
  @override
  List<Module> get imports => [ConfigModule(appBootstrap)];
  @override
  void exportedBinds(Injector i) {
    i.addLazySingleton<SupabaseWrapper>(() => appBootstrap.supabaseWrapper);
  }
}
