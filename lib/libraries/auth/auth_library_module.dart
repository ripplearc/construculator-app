import 'package:construculator/libraries/auth/auth_manager_impl.dart';
import 'package:construculator/libraries/auth/auth_notifier_impl.dart';
import 'package:construculator/libraries/auth/interfaces/auth_manager.dart';
import 'package:construculator/libraries/auth/interfaces/auth_notifier.dart';
import 'package:construculator/libraries/auth/interfaces/auth_notifier_controller.dart';
import 'package:construculator/libraries/auth/interfaces/auth_repository.dart';
import 'package:construculator/libraries/auth/repositories/supabase_repository_impl.dart';
import 'package:construculator/libraries/supabase/supabase_module.dart';
import 'package:flutter_modular/flutter_modular.dart';

class AuthLibraryModule extends Module {
  @override
  List<Module> get imports => [
    SupabaseModule(),
  ];
  final AuthNotifierController authNotifierImpl = AuthNotifierImpl();
  @override
  void binds(Injector i) {
    i.addLazySingleton<AuthNotifierController>(
      () => authNotifierImpl,
    );
    i.addLazySingleton<AuthRepository>(
      () => SupabaseRepositoryImpl(
        supabaseWrapper: i(),
      ),
    );
  }
  @override
  void exportedBinds(Injector i) {
    i.addLazySingleton<AuthNotifier>(
      () => authNotifierImpl,
    );
    i.addLazySingleton<AuthManager>(
      () => AuthManagerImpl(
        wrapper: i(),
        authRepository: i(),
        authNotifier: i(),
      ),
    );
  }
}
