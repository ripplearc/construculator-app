import 'package:construculator/libraries/config/config_module.dart';
import 'package:construculator/libraries/supabase/supabase_wrapper_impl.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:flutter_modular/flutter_modular.dart';

class SupabaseModule extends Module {
  @override
  List<Module> get imports => [
    ConfigModule(),
  ];
  @override
  void exportedBinds(Injector i) async{
    final wrapperImpl = SupabaseWrapperImpl(envLoader: i());
    await wrapperImpl.initialize();
    i.addLazySingleton<SupabaseWrapper>(
      () => wrapperImpl,
    );
  }
}
