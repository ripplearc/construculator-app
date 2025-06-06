import 'package:construculator/libraries/supabase/default_supabase_initializer.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_initializer.dart';
import 'package:flutter_modular/flutter_modular.dart';

class SupabaseModule extends Module {

  @override
  void exportedBinds(Injector i) {
    i.addLazySingleton<SupabaseInitializer>(() => DefaultSupabaseInitializer());
  }
}
