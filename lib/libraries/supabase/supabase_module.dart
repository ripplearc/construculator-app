import 'package:construculator/libraries/config/config_module.dart';
import 'package:construculator/app/module_param.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:flutter_modular/flutter_modular.dart';

class SupabaseModule extends Module {
  final ModuleParam moduleParam;
  SupabaseModule(this.moduleParam);
  @override
  List<Module> get imports => [ConfigModule(moduleParam)];
  @override
  void exportedBinds(Injector i) {
    i.addLazySingleton<SupabaseWrapper>(() => moduleParam.supabaseWrapper);
  }
}
