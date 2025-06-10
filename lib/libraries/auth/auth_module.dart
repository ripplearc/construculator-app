import 'package:construculator/libraries/auth/interfaces/auth_repository.dart';
import 'package:construculator/libraries/auth/repositories/supabase_auth_repository.dart';
import 'package:construculator/libraries/supabase/supabase_module.dart';
import 'package:flutter_modular/flutter_modular.dart';

class AuthModule extends Module {
  @override
  List<Module> get imports => [
    SupabaseModule(),
  ];
  @override
  void exportedBinds(Injector i) {
    i.addLazySingleton<AuthRepository>(
      () => SupabaseAuthRepository(
        supabaseWrapper: i(),
      ),
    );
  }
}
