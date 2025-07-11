import 'package:construculator/libraries/config/config_module.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:construculator/libraries/supabase/supabase_wrapper_impl.dart';
import 'package:flutter_modular/flutter_modular.dart';

class SupabaseModule extends Module {
  @override
  List<Module> get imports => [ConfigModule()];
  @override
  void exportedBinds(Injector i) {
    i.addLazySingleton<SupabaseWrapper>(() => SupabaseWrapperImpl(envLoader: i()));
  }
}
