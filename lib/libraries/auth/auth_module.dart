import 'package:construculator/libraries/auth/interfaces/auth_repository.dart';
import 'package:construculator/libraries/auth/repositories/supabase_auth_repository_impl.dart';
import 'package:construculator/libraries/auth/interfaces/auth_service.dart';
import 'package:construculator/libraries/auth/shared_auth_service.dart';
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
      () => SupabaseRepositoryImpl(
        supabaseWrapper: i(),
      ),
    );
    i.addLazySingleton<AuthService>(
      () => SharedAuthService(
        notifier: i(),
        repository: i(),
      ),
    );
  }
}
